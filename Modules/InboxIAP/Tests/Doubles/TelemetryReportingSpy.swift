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

import proton_app_uniffi

@testable import InboxIAP

final class TelemetryReportingSpy: TelemetryReporting {
    private(set) var upsellButtonTappedCalls = 0
    private(set) var upgradeAttemptCalls = 0
    private(set) var upgradeSuccessCalls = 0
    private(set) var upgradeErrorCalls = 0
    private(set) var upgradeCancelledCalls = 0

    func prepare(entryPoint: UpsellEntryPoint) {
    }

    func upsellButtonTapped() {
        upsellButtonTappedCalls += 1
    }

    func upgradeAttempt(storeKitProductID: String) {
        upgradeAttemptCalls += 1
    }

    func upgradeSuccess(storeKitProductID: String) {
        upgradeSuccessCalls += 1
    }

    func upgradeError(storeKitProductID: String) {
        upgradeErrorCalls += 1
    }

    func upgradeCancelled(storeKitProductID: String) {
        upgradeCancelledCalls += 1
    }
}
