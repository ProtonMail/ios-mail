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

import Foundation
import PaymentsNG
import proton_app_uniffi

protocol TelemetryReporting {
    func prepare(entryPoint: UpsellEntryPoint)
    func upsellButtonTapped() async
    func upgradeAttempt(storeKitProductID: String) async
    func upgradeSuccess(storeKitProductID: String) async
    func upgradeError(storeKitProductID: String) async
    func upgradeCancelled(storeKitProductID: String) async
}

final class TelemetryReporter: TelemetryReporting {
    private let mailUserSession: MailUserSession
    private let telemetryActions: TelemetryActions
    private var entryPoint: UpsellEntryPoint?

    init(mailUserSession: MailUserSession, telemetryActions: TelemetryActions) {
        self.mailUserSession = mailUserSession
        self.telemetryActions = telemetryActions
    }

    func prepare(entryPoint: UpsellEntryPoint) {
        self.entryPoint = entryPoint
    }

    func upsellButtonTapped() async {
        await telemetryActions.upsellButtonTapped(mailUserSession, generalDimensions())
    }

    func upgradeAttempt(storeKitProductID: String) async {
        await telemetryActions.upgradeAttempt(mailUserSession, generalDimensions(), planSpecificDimensions(storeKitProductID: storeKitProductID))
    }

    func upgradeSuccess(storeKitProductID: String) async {
        await telemetryActions.upgradeSuccess(mailUserSession, generalDimensions(), planSpecificDimensions(storeKitProductID: storeKitProductID))
    }

    func upgradeError(storeKitProductID: String) async {
        await telemetryActions.upgradeError(mailUserSession, generalDimensions(), planSpecificDimensions(storeKitProductID: storeKitProductID))
    }

    func upgradeCancelled(storeKitProductID: String) async {
        await telemetryActions.upgradeCancelled(mailUserSession, generalDimensions(), planSpecificDimensions(storeKitProductID: storeKitProductID))
    }

    private func generalDimensions() -> GeneralDimensions {
        .init(upsellEntryPoint: entryPoint!, planBeforeUpgrade: "free", modalVariant: .comparison)
    }

    private func planSpecificDimensions(storeKitProductID: String) -> PlanSpecificDimensions {
        let (selectedPlan, selectedCycle) = parsePlanNameAndCycle(from: storeKitProductID)

        return .init(
            selectedPlan: selectedPlan,
            selectedCycle: selectedCycle,
            upsellIsPromotional: false
        )
    }

    private func parsePlanNameAndCycle(from storeKitProductID: String) -> (name: String, cycle: String) {
        let regex = #/^ios[^_]*_([^_]*)_?(.*)_(\d+)_(\w+)_(?:non_|auto_)renewing(?:_v\d+)?$/#
        let result = try! regex.wholeMatch(in: storeKitProductID)!
        return (String(result.1), String(result.3))
    }
}

struct DummyTelemetryReporting: TelemetryReporting {
    func prepare(entryPoint: proton_app_uniffi.UpsellEntryPoint) {
    }

    func upsellButtonTapped() {
    }

    func upgradeAttempt(storeKitProductID: String) {
    }

    func upgradeSuccess(storeKitProductID: String) {
    }

    func upgradeError(storeKitProductID: String) {
    }

    func upgradeCancelled(storeKitProductID: String) {
    }
}
