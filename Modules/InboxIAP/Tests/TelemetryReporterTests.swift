//
// Copyright (c) 2025 Proton Technologies AG
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

import Testing
import proton_app_uniffi

@testable import InboxIAP

final class TelemetryReporterTests {
    private let sut: TelemetryReporter
    private let telemetryActions = SpyingTelemetryActions()
    private let entryPoint = UpsellEntryPoint.autoDeleteMessages
    private let storeKitProductID = "iosmail_mail2022_12_usd_auto_renewing"

    private var expectedGeneralDimensions: GeneralDimensions {
        .init(
            upsellEntryPoint: entryPoint,
            planBeforeUpgrade: "free",
            modalVariant: .comparison
        )
    }

    private var expectedPlanSpecificDimensions: PlanSpecificDimensions {
        .init(
            selectedPlan: "mail2022",
            selectedCycle: "12",
            upsellIsPromotional: false
        )
    }

    init() {
        sut = .init(mailUserSession: .init(noPointer: .init()), telemetryActions: telemetryActions)
        sut.prepare(entryPoint: entryPoint)
    }

    @Test
    func upsellButtonTapped() async {
        await sut.upsellButtonTapped()

        #expect(telemetryActions.transmittedGeneralDimensions == [expectedGeneralDimensions])
        #expect(telemetryActions.transmittedPlanSpecificDimensions == [])
    }

    @Test
    func upgradeAttempt() async {
        await sut.upgradeAttempt(storeKitProductID: storeKitProductID)

        #expect(telemetryActions.transmittedGeneralDimensions == [expectedGeneralDimensions])
        #expect(telemetryActions.transmittedPlanSpecificDimensions == [expectedPlanSpecificDimensions])
    }

    @Test
    func upgradeSuccess() async {
        await sut.upgradeSuccess(storeKitProductID: storeKitProductID)

        #expect(telemetryActions.transmittedGeneralDimensions == [expectedGeneralDimensions])
        #expect(telemetryActions.transmittedPlanSpecificDimensions == [expectedPlanSpecificDimensions])
    }

    @Test
    func upgradeError() async {
        await sut.upgradeError(storeKitProductID: storeKitProductID)

        #expect(telemetryActions.transmittedGeneralDimensions == [expectedGeneralDimensions])
        #expect(telemetryActions.transmittedPlanSpecificDimensions == [expectedPlanSpecificDimensions])
    }

    @Test
    func upgradeCancelled() async {
        await sut.upgradeCancelled(storeKitProductID: storeKitProductID)

        #expect(telemetryActions.transmittedGeneralDimensions == [expectedGeneralDimensions])
        #expect(telemetryActions.transmittedPlanSpecificDimensions == [expectedPlanSpecificDimensions])
    }
}

private final class SpyingTelemetryActions: TelemetryActions {
    private(set) var transmittedGeneralDimensions: [GeneralDimensions] = []
    private(set) var transmittedPlanSpecificDimensions: [PlanSpecificDimensions] = []

    private(set) lazy var upsellButtonTapped: GeneralAction = { [unowned self] in
        self.transmittedGeneralDimensions.append($1)
    }

    private(set) lazy var upgradeAttempt: PlanSpecificAction = { [unowned self] in
        self.transmittedGeneralDimensions.append($1)
        self.transmittedPlanSpecificDimensions.append($2)
    }

    private(set) lazy var upgradeSuccess: PlanSpecificAction = { [unowned self] in
        self.transmittedGeneralDimensions.append($1)
        self.transmittedPlanSpecificDimensions.append($2)
    }

    private(set) lazy var upgradeError: PlanSpecificAction = { [unowned self] in
        self.transmittedGeneralDimensions.append($1)
        self.transmittedPlanSpecificDimensions.append($2)
    }

    private(set) lazy var upgradeCancelled: PlanSpecificAction = { [unowned self] in
        self.transmittedGeneralDimensions.append($1)

        self.transmittedPlanSpecificDimensions.append($2)
    }
}
