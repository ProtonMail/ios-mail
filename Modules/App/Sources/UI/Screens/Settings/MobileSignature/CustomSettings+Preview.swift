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

final class CustomSettingsPreviewProvider: CustomSettingsProtocol {
    private(set) var state: MobileSignature

    init(status: MobileSignatureStatus) {
        state = .init(body: "Sent from Proton Mail for iOS", status: status)
    }

    func mobileSignature() async -> CustomSettingsMobileSignatureResult {
        .ok(state)
    }

    func setMobileSignature(signature: String) async -> CustomSettingsSetMobileSignatureResult {
        state.body = signature
        return .ok
    }

    func setMobileSignatureEnabled(enabled: Bool) async -> CustomSettingsSetMobileSignatureEnabledResult {
        state.status.isEnabled = enabled
        return .ok
    }
}
