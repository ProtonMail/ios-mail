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

final class CustomSettingsSpy: CustomSettingsProtocol, @unchecked Sendable {
    var stubbedMobileSignature: MobileSignature
    var stubbedSwipeToAdjacent: CustomSettingsSwipeToAdjacentConversationResult

    private(set) var setMobileSignatureCalls: [String] = []
    private(set) var setMobileSignatureEnabledCalls: [Bool] = []

    var stubbedMobileSignatureError: ProtonError?

    init(
        stubbedMobileSignature: MobileSignature = .init(body: .empty, status: .needsPaidVersion),
        stubbedSwipeToAdjacent: CustomSettingsSwipeToAdjacentConversationResult = .ok(false)
    ) {
        self.stubbedMobileSignature = stubbedMobileSignature
        self.stubbedSwipeToAdjacent = stubbedSwipeToAdjacent
    }

    // MARK: - CustomSettingsProtocol

    func mobileSignature() async -> CustomSettingsMobileSignatureResult {
        if let stubbedMobileSignatureError {
            return .error(stubbedMobileSignatureError)
        } else {
            return .ok(stubbedMobileSignature)
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

    func setSwipeToAdjacentConversation(enabled: Bool) async -> CustomSettingsSetSwipeToAdjacentConversationResult {
        guard case .ok = stubbedSwipeToAdjacent else {
            return .error(.network)
        }

        stubbedSwipeToAdjacent = .ok(enabled)

        return .ok
    }

    func swipeToAdjacentConversation() async -> CustomSettingsSwipeToAdjacentConversationResult {
        stubbedSwipeToAdjacent
    }
}
