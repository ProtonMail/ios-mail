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

import ProtonCorePayments
import ProtonCoreTestingToolkitUnitTestsPayments
import ProtonCoreTestingToolkitUnitTestsServices
import ProtonMailUI
import XCTest

@testable import ProtonMail

final class UpsellPageFactoryTests: XCTestCase {
    private var sut: UpsellPageFactory!
    private var user: UserManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        let storeKitManager = StoreKitManagerMock()
        storeKitManager.priceLabelForProductStub.bodyIs { _, storeKitProductId in
            switch storeKitProductId {
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
        let planJSON = AvailablePlansTestData.availablePlan(named: "mail2022")
        let planData = try JSONSerialization.data(withJSONObject: planJSON)
        let plan = try JSONDecoder.decapitalisingFirstLetter.decode(AvailablePlans.AvailablePlan.self, from: planData)

        let pageModel = sut.makeUpsellPageModel(for: plan, entryPoint: .header)

        let expectedPlan = UpsellPageModel.Plan(
            name: "Mail Plus",
            perks: [
                .init(icon: \.storage, description: "15 GB storage"),
                .init(icon: \.inbox, description: "10 email addresses"),
                .init(icon: \.globe, description: "Custom email domain support"),
                .init(icon: \.gift, description: "+7 premium features")
            ],
            purchasingOptions: [
                .init(
                    identifier: "iosmail_mail2022_1_usd_auto_renewing",
                    cycleInMonths: 1,
                    monthlyPrice: "$4.99",
                    billingPrice: "$4.99",
                    isHighlighted: false,
                    discount: nil
                ),
                .init(
                    identifier: "iosmail_mail2022_12_usd_auto_renewing",
                    cycleInMonths: 12,
                    monthlyPrice: "$3.99",
                    billingPrice: "$47.88",
                    isHighlighted: true,
                    discount: 20
                )
            ]
        )

        XCTAssertEqual(pageModel.plan, expectedPlan)
    }
}
