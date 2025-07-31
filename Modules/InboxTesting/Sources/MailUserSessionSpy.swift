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

public final class MailUserSessionSpy: MailUserSession, @unchecked Sendable {
    public var stubbedAccountDetails: AccountDetails?

    public private(set) var executeNotificationQuickActionInvocations: [PushNotificationQuickAction] = []

    private let id: String

    public init(id: String) {
        self.id = id

        super.init(noPointer: .init())
    }

    @available(*, unavailable)
    required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        fatalError("init(unsafeFromRawPointer:) has not been implemented")
    }

    public override func accountDetails() async -> MailUserSessionAccountDetailsResult {
        .ok(stubbedAccountDetails!)
    }

    public override func executeNotificationQuickAction(action: PushNotificationQuickAction) async -> VoidActionResult {
        executeNotificationQuickActionInvocations.append(action)
        return .ok
    }

    public override func newPasswordChangeFlow() async -> MailUserSessionNewPasswordChangeFlowResult {
        .ok(PasswordFlowStub())
    }

    public override func passwordValidator() -> PasswordValidatorService? {
        nil
    }

    public override func sessionId() -> MailUserSessionSessionIdResult {
        .ok(id)
    }

    public override func userSettings() async -> MailUserSessionUserSettingsResult {
        .error(.reason(.userSessionNotInitialized))
    }
}
