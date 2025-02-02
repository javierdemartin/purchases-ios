//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendSubscriberAttributesTestBase.swift
//
//  Created by Joshua Liebowitz on 3/28/22.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class BackendSubscriberAttributesTestBase: XCTestCase {

    let appUserID = "abc123"
    let referenceDate = Date(timeIntervalSinceReferenceDate: 700000000) // 2023-03-08 20:26:40
    let receiptData = "an awesome receipt".data(using: String.Encoding.utf8)!

    var subscriberAttribute1: SubscriberAttribute!
    var subscriberAttribute2: SubscriberAttribute!
    var mockHTTPClient: MockHTTPClient!
    var backend: Backend!

    private var dateProvider: MockDateProvider!
    private var mockETagManager: MockETagManager!

    private static let apiKey = "the api key"

    let validSubscriberResponse: [String: Any] = [
        "request_date": "2019-08-16T10:30:42Z",
        "subscriber": [
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": "app_user_id",
            "subscriptions": [
                "onemonth_freetrial": [
                    "expires_date": "2017-08-30T02:40:36Z"
                ]
            ]
        ]
    ]

    // swiftlint:disable:next force_try
    let systemInfo = try! SystemInfo(platformInfo: .init(flavor: "Unity", version: "2.3.3"), finishTransactions: true)

    override func setUpWithError() throws {
        guard Self.self != BackendSubscriberAttributesTestBase.self else {
            throw XCTSkip("Ignoring base class \(Self.self)")
        }

        mockHTTPClient = self.createClient()
        dateProvider = MockDateProvider(stubbedNow: self.referenceDate)
        let attributionFetcher = AttributionFetcher(attributionFactory: MockAttributionTypeFactory(),
                                                    systemInfo: self.systemInfo)

        self.backend = Backend(httpClient: mockHTTPClient,
                               apiKey: Self.apiKey,
                               attributionFetcher: attributionFetcher,
                               dateProvider: dateProvider)

        subscriberAttribute1 = SubscriberAttribute(withKey: "a key",
                                                   value: "a value",
                                                   dateProvider: dateProvider)

        subscriberAttribute2 = SubscriberAttribute(withKey: "another key",
                                                   value: "another value",
                                                   dateProvider: dateProvider)

        try super.setUpWithError()
    }

    override class func setUp() {
        XCTestObservationCenter.shared.addTestObserver(CurrentTestCaseTracker.shared)
    }

    override class func tearDown() {
        XCTestObservationCenter.shared.removeTestObserver(CurrentTestCaseTracker.shared)
    }

    // MARK: PostReceipt with subscriberAttributes

    func testPostReceiptWithSubscriberAttributesSendsThemCorrectly() throws {
        var completionCallCount = 0

        let subscriberAttributesByKey: [String: SubscriberAttribute] = [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ]

        backend.post(receiptData: receiptData,
                     appUserID: appUserID,
                     isRestore: false,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: false,
                     subscriberAttributes: subscriberAttributesByKey,
                     completion: { _ in
            completionCallCount += 1
        })

        expect(self.mockHTTPClient.calls).toEventually(haveCount(1))
    }

    func testPostReceiptWithSubscriberAttributesReturnsBadJson() throws {
        let subscriberAttributesByKey: [String: SubscriberAttribute] = [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ]

        var receivedResult: Result<CustomerInfo, Error>?

        // No mocked response, the default response is an empty 200.

        backend.post(receiptData: receiptData,
                     appUserID: appUserID,
                     isRestore: false,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: false,
                     subscriberAttributes: subscriberAttributesByKey) {
            receivedResult = $0
        }

        expect(receivedResult).toEventuallyNot(beNil())
        expect(receivedResult).to(beFailure())

        let nsError = try XCTUnwrap(receivedResult?.error as NSError?)
        expect(nsError.domain) == RCPurchasesErrorCodeDomain
        expect(nsError.code) == ErrorCode.unknownBackendError.rawValue

        let underlyingError = try XCTUnwrap(nsError.userInfo[NSUnderlyingErrorKey] as? NSError)

        expect(underlyingError.domain) == "RevenueCat.UnexpectedBackendResponseSubErrorCode"
        expect(underlyingError.code) == UnexpectedBackendResponseSubErrorCode.customerInfoResponseParsing.rawValue

        let parsingError = try XCTUnwrap(underlyingError.userInfo[NSUnderlyingErrorKey] as? NSError)

        expect(parsingError.domain) == "RevenueCat.CustomerInfoError"
        expect(parsingError.code) == CustomerInfoError.missingJsonObject.rawValue
    }

    func testPostReceiptWithoutSubscriberAttributesSkipsThem() throws {
        var completionCallCount = 0

        backend.post(receiptData: receiptData,
                     appUserID: appUserID,
                     isRestore: false,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: false,
                     subscriberAttributes: nil) { _ in
            completionCallCount += 1
        }

        expect(self.mockHTTPClient.calls).toEventually(haveCount(1))
    }

    func testPostReceiptWithSubscriberAttributesPassesErrorsToCallbackIfStatusCodeIsSuccess() throws {
        let attributeErrors = [
            Backend.RCAttributeErrorsKey: [
                [
                    "key_name": "$email",
                    "message": "email is not in valid format"
                ]
            ]
        ]

        self.mockHTTPClient.mock(
            requestPath: .postReceiptData,
            response: .init(statusCode: .success,
                            response: validSubscriberResponse + [Backend.RCAttributeErrorsResponseKey: attributeErrors])
        )

        let subscriberAttributesByKey: [String: SubscriberAttribute] = [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ]
        var receivedError: NSError?
        backend.post(receiptData: receiptData,
                     appUserID: appUserID,
                     isRestore: false,
                     productData: nil,
                     presentedOfferingIdentifier: nil,
                     observerMode: false,
                     subscriberAttributes: subscriberAttributesByKey) { result in
            receivedError = result.error as NSError?
        }

        expect(self.mockHTTPClient.calls).toEventually(haveCount(1))

        expect(receivedError).toNot(beNil())
        expect(receivedError?.successfullySynced) == true
        expect(receivedError?.subscriberAttributesErrors) == [
            "$email": "email is not in valid format"
        ]
    }

    // MARK: PostSubscriberAttributes
    func testPostSubscriberAttributesSendsRightParameters() throws {
        backend.post(subscriberAttributes: [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ],
                     appUserID: appUserID,
                     completion: { (_: Error!) in })

        expect(self.mockHTTPClient.calls).toEventually(haveCount(1))
    }

    func testPostSubscriberAttributesCallsCompletionInSuccessCase() {
        var completionCallCount = 0

        backend.post(subscriberAttributes: [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ],
                     appUserID: appUserID,
                     completion: { (_: Error!) in
            completionCallCount += 1
        })

        expect(self.mockHTTPClient.calls).toEventually(haveCount(1))
        expect(completionCallCount).toEventually(equal(1))
    }

    func testPostSubscriberAttributesCallsCompletionInNetworkErrorCase() throws {
        var completionCallCount = 0
        let underlyingError = NSError(domain: "domain", code: 0, userInfo: nil)

        self.mockHTTPClient.mock(
            requestPath: .postSubscriberAttributes(appUserID: appUserID),
            response: .init(error: ErrorUtils.networkError(withUnderlyingError: underlyingError))
        )

        var receivedError: Error?
        backend.post(subscriberAttributes: [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ],
                     appUserID: appUserID,
                     completion: { (error: Error!) in
            completionCallCount += 1
            receivedError = error
        })

        expect(self.mockHTTPClient.calls).toEventually(haveCount(1))
        expect(completionCallCount).toEventually(equal(1))
        let receivedNSError = try XCTUnwrap(receivedError as NSError?)

        expect(receivedNSError.code) == ErrorCode.networkError.rawValue
        expect(receivedNSError.successfullySynced) == false
    }

    func testPostSubscriberAttributesSendsAttributesErrorsIfAny() throws {
        var completionCallCount = 0

        self.mockHTTPClient.mock(
            requestPath: .postSubscriberAttributes(appUserID: appUserID),
            response: .init(
                error: ErrorResponse
                    .from([
                        Backend.RCAttributeErrorsKey: [
                            [
                                "key_name": "$some_attribute",
                                "message": "wasn't valid"
                            ]
                        ]
                    ])
                    .asBackendError(with: 503)
            )
        )

        var receivedError: Error?
        backend.post(subscriberAttributes: [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ],
                     appUserID: appUserID,
                     completion: { (error: Error!) in
            completionCallCount += 1
            receivedError = error
        })

        expect(self.mockHTTPClient.calls).toEventually(haveCount(1))
        expect(completionCallCount).toEventually(equal(1))

        let receivedNSError = try XCTUnwrap(receivedError as NSError?)
        expect(receivedNSError.code) == ErrorCode.unknownBackendError.rawValue
        expect(receivedNSError.userInfo[Backend.RCAttributeErrorsKey]).toNot(beNil())

        let receivedAttributeErrors = receivedNSError.userInfo[Backend.RCAttributeErrorsKey]
        guard let receivedAttributeErrors = receivedAttributeErrors as? [String: String] else {
            fail("received attribute errors are not of type [String: String]")
            return
        }
        expect(receivedAttributeErrors) == ["$some_attribute": "wasn't valid"]
    }

    func testPostSubscriberAttributesCallsCompletionWithErrorInBadRequestCase() throws {
        var completionCallCount = 0

        let mockedError = ErrorCode.invalidSubscriberAttributesError as NSError

        mockHTTPClient.mock(requestPath: .postSubscriberAttributes(appUserID: appUserID),
                            response: .init(error: mockedError))

        var receivedError: Error?
        backend.post(subscriberAttributes: [
            subscriberAttribute1.key: subscriberAttribute1,
            subscriberAttribute2.key: subscriberAttribute2
        ],
                     appUserID: appUserID,
                     completion: { error in
            completionCallCount += 1
            receivedError = error
        })

        expect(self.mockHTTPClient.calls).toEventually(haveCount(1))
        expect(completionCallCount).toEventually(equal(1))
        expect(receivedError).toNot(beNil())

        let receivedNSError = try XCTUnwrap(receivedError as NSError?)
        expect(receivedNSError) == mockedError
    }

    func testPostSubscriberAttributesNoOpIfAttributesAreEmpty() {
        var completionCallCount = 0
        backend.post(subscriberAttributes: [:],
                     appUserID: appUserID,
                     completion: { (_: Error!) in
            completionCallCount += 1

        })
        expect(self.mockHTTPClient.calls).to(beEmpty())
    }

    func createClient() -> MockHTTPClient {
        XCTFail("This method must be overriden by subclasses")
        return self.createClient(#file)
    }

    final func createClient(_ file: StaticString) -> MockHTTPClient {
        let eTagManager = MockETagManager(userDefaults: MockUserDefaults())
        self.mockETagManager = eTagManager

        return MockHTTPClient(systemInfo: self.systemInfo, eTagManager: eTagManager, sourceTestFile: file)
    }

}
