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
import ProtonMailUI
import XCTest

@testable import ProtonMail

final class UpsellTelemetryReporterTests: XCTestCase {
    private var sut: UpsellTelemetryReporter!
    private var plansDataSource: PlansDataSourceMock!
    private var telemetryService: MockTelemetryServiceProtocol!
    private var user: UserManager!

    private let entryPoint = UpsellPageEntryPoint.autoDelete

    override func setUp() {
        super.setUp()

        plansDataSource = .init()
        telemetryService = .init()
        user = UserManager(api: APIServiceMock())

        let container = user.container

        container.telemetryServiceFactory.register {
            self.telemetryService
        }

        container.planServiceFactory.register {
            .right(self.plansDataSource)
        }

        sut = .init(dependencies: container)

        sut.prepare(entryPoint: entryPoint, upsellPageVariant: .plain)
    }

    override func tearDown() {
        sut = nil
        telemetryService = nil
        user = nil

        super.tearDown()
    }

    func testUpsellPageDisplayed() async throws {
        await sut.upsellPageDisplayed()

        let transmittedEvent = try XCTUnwrap(telemetryService.sendEventStub.lastArguments?.value)

        let expectedEvent = TelemetryEvent(
            measurementGroup: "mail.any.upsell",
            name: "upsell_button_tapped",
            values: [:],
            dimensions: [
                "upsell_entry_point": "auto_delete_messages",
                "plan_before_upgrade": "free",
                "days_since_account_creation": ">60",
                "upsell_modal_version": "A.1"
            ],
            frequency: .always
        )

        XCTAssertEqual(transmittedEvent, expectedEvent)
    }

    func testUpgradeAttempt() async throws {
        await sut.upgradeAttempt(storeKitProductId: "iosmail_mail2022_12_usd_auto_renewing")

        let transmittedEvent = try XCTUnwrap(telemetryService.sendEventStub.lastArguments?.value)

        let expectedEvent = TelemetryEvent(
            measurementGroup: "mail.any.upsell",
            name: "upgrade_attempt",
            values: [:],
            dimensions: [
                "upsell_entry_point": "auto_delete_messages",
                "plan_before_upgrade": "free",
                "days_since_account_creation": ">60",
                "upsell_modal_version": "A.1",
                "selected_plan": "mail2022",
                "selected_cycle": "12"
            ],
            frequency: .always
        )

        XCTAssertEqual(transmittedEvent, expectedEvent)
    }

    func testUpgradeSuccess() async throws {
        await sut.upgradeSuccess(storeKitProductId: "iosmail_mail2022_12_usd_auto_renewing")

        let transmittedEvent = try XCTUnwrap(telemetryService.sendEventStub.lastArguments?.value)

        let expectedEvent = TelemetryEvent(
            measurementGroup: "mail.any.upsell",
            name: "upgrade_success",
            values: [:],
            dimensions: [
                "upsell_entry_point": "auto_delete_messages",
                "plan_before_upgrade": "free",
                "days_since_account_creation": ">60",
                "upsell_modal_version": "A.1",
                "selected_plan": "mail2022",
                "selected_cycle": "12"
            ],
            frequency: .always
        )

        XCTAssertEqual(transmittedEvent, expectedEvent)
    }

    func testUpgradeFailed() async throws {
        await sut.upgradeFailed(storeKitProductId: "iosmail_mail2022_12_usd_auto_renewing")

        let transmittedEvent = try XCTUnwrap(telemetryService.sendEventStub.lastArguments?.value)

        let expectedEvent = TelemetryEvent(
            measurementGroup: "mail.any.upsell",
            name: "upgrade_error",
            values: [:],
            dimensions: [
                "upsell_entry_point": "auto_delete_messages",
                "plan_before_upgrade": "free",
                "days_since_account_creation": ">60",
                "upsell_modal_version": "A.1",
                "selected_plan": "mail2022",
                "selected_cycle": "12"
            ],
            frequency: .always
        )

        XCTAssertEqual(transmittedEvent, expectedEvent)
    }

    func testUpgradeCancelled() async throws {
        await sut.upgradeCancelled(storeKitProductId: "iosmail_mail2022_12_usd_auto_renewing")

        let transmittedEvent = try XCTUnwrap(telemetryService.sendEventStub.lastArguments?.value)

        let expectedEvent = TelemetryEvent(
            measurementGroup: "mail.any.upsell",
            name: "upgrade_cancelled_by_user",
            values: [:],
            dimensions: [
                "upsell_entry_point": "auto_delete_messages",
                "plan_before_upgrade": "free",
                "days_since_account_creation": ">60",
                "upsell_modal_version": "A.1",
                "selected_plan": "mail2022",
                "selected_cycle": "12"
            ],
            frequency: .always
        )

        XCTAssertEqual(transmittedEvent, expectedEvent)
    }

    func testWhenUserAlreadyIsOnPremiumPlan_thenTheValueIsSentInTheEvent() async throws {
        plansDataSource.currentPlanStub.fixture = .init(
            subscriptions: [.init(title: "", name: "foo2024", description: "", entitlements: [])]
        )

        sut.prepare(entryPoint: entryPoint, upsellPageVariant: .plain)
        await sut.upsellPageDisplayed()

        let transmittedEvent = try XCTUnwrap(telemetryService.sendEventStub.lastArguments?.value)
        XCTAssertEqual(transmittedEvent.dimensions["plan_before_upgrade"], "foo2024")
    }

    func testAccountAgeBrackets() async throws {
        let currentDate = Date()

        let expectedBracketsByAge: [Int: String] = [
            0: "0",
            1: "01-03",
            3: "01-03",
            4: "04-10",
            10: "04-10",
            11: "11-30",
            30: "11-30",
            31: "31-60",
            60: "31-60",
            61: ">60",
            -1: "n/a",
        ]

        for (mockedAge, expectedBracket) in expectedBracketsByAge {
            let mockedAccountCreationDate = Calendar.autoupdatingCurrent.date(
                byAdding: .day,
                value: -mockedAge,
                to: currentDate
            )

            user.userInfo.createTime = Int64(try XCTUnwrap(mockedAccountCreationDate).timeIntervalSince1970)

            await sut.upsellPageDisplayed()

            let transmittedEvent = try XCTUnwrap(telemetryService.sendEventStub.lastArguments?.value)
            XCTAssertEqual(transmittedEvent.dimensions["days_since_account_creation"], expectedBracket)
        }
    }

    func testNonDefaultUpsellPageVariant() async throws {
        sut.prepare(entryPoint: entryPoint, upsellPageVariant: .comparison)

        await sut.upsellPageDisplayed()

        let transmittedEvent = try XCTUnwrap(telemetryService.sendEventStub.lastArguments?.value)
        XCTAssertEqual(transmittedEvent.dimensions["upsell_modal_version"], "B.1")
    }
}
