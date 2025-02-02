import Nimble
import SnapshotTesting
import XCTest

@testable import RevenueCat

class ProductRequestDataTests: XCTestCase {

    func testAsDictionaryConvertsProductIdentifierCorrectly() throws {
        let productIdentifier = "cool_product"
        let productData: ProductRequestData = .createMockProductData(productIdentifier: productIdentifier)

        assertSnapshot(matching: productData, as: .formattedJson)
    }

    func testAsDictionaryConvertsPaymentModeCorrectly() throws {
        var paymentMode: StoreProductDiscount.PaymentMode?
        var productData: ProductRequestData = .createMockProductData(paymentMode: paymentMode)

        assertSnapshot(matching: productData, as: .formattedJson)

        paymentMode = .payAsYouGo
        productData = .createMockProductData(paymentMode: paymentMode)

        assertSnapshot(matching: productData, as: .formattedJson)

        paymentMode = .freeTrial
        productData = .createMockProductData(paymentMode: paymentMode)

        assertSnapshot(matching: productData, as: .formattedJson)

        paymentMode = .payUpFront
        productData = .createMockProductData(paymentMode: paymentMode)

        assertSnapshot(matching: productData, as: .formattedJson)
    }

    func testAsDictionaryConvertsCurrencyCodeCorrectly() throws {
        let currencyCode = "USD"
        let productData: ProductRequestData = .createMockProductData(currencyCode: currencyCode)

        assertSnapshot(matching: productData, as: .formattedJson)
    }

    func testAsDictionaryConvertsPriceCorrectly() throws {
        let price: NSDecimalNumber = 9.99
        let productData: ProductRequestData = .createMockProductData(price: price as Decimal)

        assertSnapshot(matching: productData, as: .formattedJson)
    }

    func testAsDictionaryConvertsNormalDurationCorrectly() throws {
        let normalDuration = "P3Y"
        let productData: ProductRequestData = .createMockProductData(normalDuration: normalDuration)

        assertSnapshot(matching: productData, as: .formattedJson)
    }

    func testAsDictionaryConvertsIntroDurationCorrectlyForFreeTrial() throws {
        let trialDuration = "P3M"
        let productData: ProductRequestData = .createMockProductData(introDuration: trialDuration,
                                                                     introDurationType: .freeTrial)

        assertSnapshot(matching: productData, as: .formattedJson)
    }

    func testAsDictionaryConvertsIntroDurationCorrectlyForIntroPrice() throws {
        let introDuration = "P3M"
        let productData: ProductRequestData = .createMockProductData(introDuration: introDuration,
                                                                     introDurationType: .payUpFront)

        assertSnapshot(matching: productData, as: .formattedJson)
    }

    func testAsDictionaryDoesntAddIntroDurationIfDurationTypeUnknown() throws {
        let introDuration = "P3M"
        let productData: ProductRequestData = .createMockProductData(introDuration: introDuration,
                                                                     introDurationType: nil)

        assertSnapshot(matching: productData, as: .formattedJson)
    }

    func testAsDictionaryConvertsIntroPriceCorrectly() throws {
        let introPrice: NSDecimalNumber = 6.99
        let productData: ProductRequestData = .createMockProductData(introPrice: introPrice as Decimal)

        assertSnapshot(matching: productData, as: .formattedJson)
    }

    func testAsDictionaryConvertsSubscriptionGroupCorrectly() {
        let subscriptionGroup = "cool_group"
        let productData: ProductRequestData = .createMockProductData(subscriptionGroup: subscriptionGroup)

        assertSnapshot(matching: productData, as: .formattedJson)
    }

    func testAsDictionaryConvertsDiscountsCorrectly() throws {
        let discount1 = MockStoreProductDiscount(offerIdentifier: "offerid1",
                                                 currencyCode: "USD",
                                                 price: 11.1,
                                                 localizedPriceString: "$11.10",
                                                 paymentMode: .payAsYouGo,
                                                 subscriptionPeriod: .init(value: 1, unit: .month),
                                                 numberOfPeriods: 1,
                                                 type: .promotional)

        let discount2 = MockStoreProductDiscount(offerIdentifier: "offerid2",
                                                 currencyCode: "USD",
                                                 price: 12.2,
                                                 localizedPriceString: "$12.20",
                                                 paymentMode: .payUpFront,
                                                 subscriptionPeriod: .init(value: 5, unit: .week),
                                                 numberOfPeriods: 2,
                                                 type: .promotional)

        let discount3 = MockStoreProductDiscount(offerIdentifier: "offerid3",
                                                 currencyCode: "USD",
                                                 price: 13.3,
                                                 localizedPriceString: "$13.30",
                                                 paymentMode: .freeTrial,
                                                 subscriptionPeriod: .init(value: 3, unit: .month),
                                                 numberOfPeriods: 3,
                                                 type: .promotional)

        let productData: ProductRequestData = .createMockProductData(discounts: [discount1, discount2, discount3])

        assertSnapshot(matching: productData, as: .formattedJson)
    }

    func testEncoding() throws {
        let discount1 = MockStoreProductDiscount(offerIdentifier: "offerid1",
                                                 currencyCode: "USD",
                                                 price: 11.2,
                                                 localizedPriceString: "$11.20",
                                                 paymentMode: .payAsYouGo,
                                                 subscriptionPeriod: .init(value: 1, unit: .month),
                                                 numberOfPeriods: 1,
                                                 type: .promotional)

        let discount2 = MockStoreProductDiscount(offerIdentifier: "offerid2",
                                                 currencyCode: "USD",
                                                 price: 12.2,
                                                 localizedPriceString: "$12.20",
                                                 paymentMode: .payUpFront,
                                                 subscriptionPeriod: .init(value: 2, unit: .year),
                                                 numberOfPeriods: 2,
                                                 type: .promotional)

        let discount3 = MockStoreProductDiscount(offerIdentifier: "offerid3",
                                                 currencyCode: "USD",
                                                 price: 13.3,
                                                 localizedPriceString: "$13.30",
                                                 paymentMode: .freeTrial,
                                                 subscriptionPeriod: .init(value: 3, unit: .day),
                                                 numberOfPeriods: 3,
                                                 type: .promotional)

        let productData: ProductRequestData = .createMockProductData(productIdentifier: "cool_product",
                                                                     paymentMode: .payUpFront,
                                                                     currencyCode: "UYU",
                                                                     price: 49.99,
                                                                     normalDuration: "P3Y",
                                                                     introDuration: "P3W",
                                                                     introDurationType: .freeTrial,
                                                                     introPrice: 15.13,
                                                                     subscriptionGroup: "cool_group",
                                                                     discounts: [discount1, discount2, discount3])

        assertSnapshot(matching: productData, as: .formattedJson)
    }

    func testCacheKey() throws {
        guard #available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *) else {
            throw XCTSkip()
        }

        let discount1 = MockStoreProductDiscount(offerIdentifier: "offerid1",
                                                 currencyCode: "USD",
                                                 price: 11,
                                                 localizedPriceString: "$11.00",
                                                 paymentMode: .payAsYouGo,
                                                 subscriptionPeriod: .init(value: 1, unit: .month),
                                                 numberOfPeriods: 1,
                                                 type: .promotional)

        let discount2 = MockStoreProductDiscount(offerIdentifier: "offerid2",
                                                 currencyCode: "USD",
                                                 price: 12,
                                                 localizedPriceString: "$12.00",
                                                 paymentMode: .payUpFront,
                                                 subscriptionPeriod: .init(value: 2, unit: .year),
                                                 numberOfPeriods: 2,
                                                 type: .promotional)

        let discount3 = MockStoreProductDiscount(offerIdentifier: "offerid3",
                                                 currencyCode: "USD",
                                                 price: 13,
                                                 localizedPriceString: "$13.0",
                                                 paymentMode: .freeTrial,
                                                 subscriptionPeriod: .init(value: 3, unit: .day),
                                                 numberOfPeriods: 3,
                                                 type: .promotional)

        let productData: ProductRequestData = .createMockProductData(productIdentifier: "cool_product",
                                                                     paymentMode: .payUpFront,
                                                                     currencyCode: "UYU",
                                                                     price: 49.99,
                                                                     normalDuration: "P3Y",
                                                                     introDuration: "P3W",
                                                                     introDurationType: .freeTrial,
                                                                     introPrice: 0,
                                                                     subscriptionGroup: "cool_group",
                                                                     discounts: [discount1, discount2, discount3])
        expect(productData.cacheKey) == "cool_product-49.99-UYU-1-0-cool_group-P3Y-P3W-2-offerid1-offerid2-offerid3"
    }

}
