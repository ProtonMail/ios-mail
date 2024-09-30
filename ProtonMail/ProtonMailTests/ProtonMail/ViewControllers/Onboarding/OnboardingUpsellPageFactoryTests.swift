// Copyright (c) 2024 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import ProtonCoreTestingToolkitUnitTestsPayments
import ProtonCoreTestingToolkitUnitTestsServices
import XCTest

@testable import ProtonCorePayments
@testable import ProtonMail
@testable import ProtonMailUI

final class OnboardingUpsellPageFactoryTests: XCTestCase {
    private var sut: OnboardingUpsellPageFactory!
    private var user: UserManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        let storeKitManager = StoreKitManagerMock()

        storeKitManager.priceLabelForProductStub.bodyIs { _, storeKitProductId in
            switch storeKitProductId {
            case "iosmail_bundle2022_1_usd_auto_renewing":
                return (12.99, .enUS)
            case "iosmail_bundle2022_12_usd_auto_renewing":
                return (119.88, .enUS)
            case "iosmail_mail2022_1_usd_auto_renewing":
                return (4.99, .enUS)
            case "iosmail_mail2022_12_usd_auto_renewing":
                return (47.88, .enUS)
            default:
                return nil
            }
        }

        user = UserManager(api: APIServiceMock())
        let userContainer = user.container
        userContainer.storeKitManagerFactory.register { storeKitManager }

        sut = .init(dependencies: user.container)
    }

    override func tearDownWithError() throws {
        sut = nil
        user = nil

        try super.tearDownWithError()
    }

    @MainActor
    func testGeneratedPlan() throws {
        let plans: [AvailablePlans.AvailablePlan] = [
            .init(
                ID: "ID \(#line)",
                type: #line,
                name: "name \(#line)",
                title: "Proton Unlimited",
                instances: [
                    .init(
                        cycle: 1,
                        description: "",
                        periodEnd: 0,
                        price: [.init(ID: "", current: 1299, currency: "USD")],
                        vendors: .init(apple: .init(productID: "iosmail_bundle2022_1_usd_auto_renewing"))
                    ),
                    .init(
                        cycle: 12,
                        description: "",
                        periodEnd: 0,
                        price: [.init(ID: "", current: 11988, currency: "USD")],
                        vendors: .init(apple: .init(productID: "iosmail_bundle2022_12_usd_auto_renewing"))
                    ),
                ],
                entitlements: [],
                decorations: []
            ),
            .init(
                ID: "ID \(#line)",
                type: #line,
                name: "name \(#line)",
                title: "Mail Plus",
                instances: [
                    .init(
                        cycle: 1,
                        description: "",
                        periodEnd: 0,
                        price: [.init(ID: "", current: 499, currency: "USD")],
                        vendors: .init(apple: .init(productID: "iosmail_mail2022_1_usd_auto_renewing"))
                    ),
                    .init(
                        cycle: 12,
                        description: "",
                        periodEnd: 0,
                        price: [.init(ID: "", current: 4788, currency: "USD")],
                        vendors: .init(apple: .init(productID: "iosmail_mail2022_12_usd_auto_renewing"))
                    ),
                ],
                entitlements: [],
                decorations: []
            )
        ]

        let pageModel = sut.makeOnboardingUpsellPageModel(for: plans)

        let expectedTiles: [OnboardingUpsellPageModel.TileModel] = [
            .init(
                planName: "Proton Unlimited",
                perks: [
                    .init(icon: \.storage, description: "500 GB storage"),
                    .init(icon: \.lock, description: "End-to-end encryption"),
                    .init(icon: \.envelope, description: "15 email addresses"),
                    .init(icon: \.globe, description: "Support for 3 custom email domains"),
                    .init(icon: \.tag, description: "Unlimited folders, labels, and filters"),
                    .init(icon: \.calendarCheckmark, description: "25 personal calendars"),
                    .init(icon: \.shield, description: "High-speed VPN on 10 devices")
                ],
                monthlyPricesPerCycle: [
                    1: "$12.99",
                    12: "$9.99"
                ],
                isBestValue: true,
                maxDiscount: 23,
                alwaysVisiblePerks: 4,
                storeKitProductIDsPerCycle: [
                    1: "iosmail_bundle2022_1_usd_auto_renewing",
                    12: "iosmail_bundle2022_12_usd_auto_renewing"
                ],
                billingPricesPerCycle: [
                    1: "$12.99",
                    12: "$119.88"
                ],
                includedProducts: [.mail, .calendar, .drive, .vpn, .pass]
            ),
            .init(
                planName: "Mail Plus",
                perks: [
                    .init(icon: \.storage, description: "15 GB storage"),
                    .init(icon: \.lock, description: "End-to-end encryption"),
                    .init(icon: \.envelope, description: "10 email addresses"),
                    .init(icon: \.globe, description: "Support for 1 custom email domain"),
                    .init(icon: \.tag, description: "Unlimited folders, labels, and filters"),
                    .init(icon: \.calendarCheckmark, description: "25 personal calendars")
                ],
                monthlyPricesPerCycle: [
                    1: "$4.99",
                    12: "$3.99"
                ],
                isBestValue: false,
                maxDiscount: 20,
                alwaysVisiblePerks: 3,
                storeKitProductIDsPerCycle: [
                    1: "iosmail_mail2022_1_usd_auto_renewing",
                    12: "iosmail_mail2022_12_usd_auto_renewing"
                ],
                billingPricesPerCycle: [
                    1: "$4.99",
                    12: "$47.88"
                ],
                includedProducts: [.mail, .calendar]
            ),
            .init(
                planName: "Proton Free",
                perks: [
                    .init(icon: \.storage, description: "1 GB Storage and 1 email"),
                    .init(icon: \.lock, description: "End-to-end encryption")
                ],
                monthlyPricesPerCycle: [:],
                isBestValue: false,
                maxDiscount: nil,
                alwaysVisiblePerks: 2,
                storeKitProductIDsPerCycle: [:],
                billingPricesPerCycle: [:],
                includedProducts: nil
            )
        ]

        XCTAssertEqual(pageModel.tiles, expectedTiles)
    }
}
