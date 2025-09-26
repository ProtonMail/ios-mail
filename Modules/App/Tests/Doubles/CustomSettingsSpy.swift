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

final class CustomSettingsSpy: CustomSettingsProtocol {
    var state: MobileSignature
    private(set) var setMobileSignatureCalls: [String] = []
    private(set) var setMobileSignatureEnabledCalls: [Bool] = []

    var stubbedOnLoadError: ProtonError?

    init(initialState: MobileSignature = .init(body: .empty, status: .needsPaidVersion)) {
        state = initialState
    }

    func mobileSignature() async -> CustomSettingsMobileSignatureResult {
        if let stubbedOnLoadError {
            return .error(stubbedOnLoadError)
        } else {
            return .ok(state)
        }
    }

    func setMobileSignature(signature: String) async -> CustomSettingsSetMobileSignatureResult {
        setMobileSignatureCalls.append(signature)
        return .ok
    }

    func setMobileSignatureEnabled(enabled: Bool) async -> CustomSettingsSetMobileSignatureEnabledResult {
        setMobileSignatureEnabledCalls.append(enabled)
        return .ok
    }
}
