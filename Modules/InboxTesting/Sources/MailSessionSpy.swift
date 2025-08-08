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

public final class MailSessionSpy: MailSessionProtocol {
    public var onPrimaryAccountChanged: (@Sendable (String) -> Void)?
    public var appProtectionStub: AppProtection = .none

    public var primaryUserSessionStub: MailUserSession?

    public var storedSessions: [StoredSessionStub] = [] {
        didSet {
            Task {
                await watchSessionsAsyncCallback?.onUpdate()
            }
        }
    }

    public var stubbedRegisterDeviceTaskHandleFactory: () -> RegisterDeviceTaskHandle = {
        fatalError("not stubbed")
    }

    public var userSessions: [MailUserSession] = []

    private(set) public var changeAppSettingsInvocations: [AppSettingsDiff] = []
    private(set) public var registerDeviceCallCount = 0
    private(set) public var setPinCodeInvocations: [[UInt32]] = []
    private(set) public var setPrimaryAccountInvocations: [String] = []
    private(set) public var signOutAllCallCount = 0

    private var stubbedAppSettings = AppSettings(
        appearance: .system,
        protection: .none,
        autoLock: .minutes(0),
        useCombineContacts: false,
        useAlternativeRouting: true
    )

    private var watchSessionsAsyncCallback: AsyncLiveQueryCallback?

    public init() {}

    // MARK: - MailSessionProtocol

    public func biometricsCheckPassed() {
        fatalError(#function)
    }

    public func appProtection() async -> MailSessionAppProtectionResult {
        .ok(appProtectionStub)
    }

    public func changeAppSettings(settings: AppSettingsDiff) async -> MailSessionChangeAppSettingsResult {
        changeAppSettingsInvocations.append(settings)

        if let changedSetting = settings.appearance {
            stubbedAppSettings.appearance = changedSetting
        }

        if let changedSetting = settings.autoLock {
            stubbedAppSettings.autoLock = changedSetting
        }

        if let changedSetting = settings.useCombineContacts {
            stubbedAppSettings.useCombineContacts = changedSetting
        }

        if let changedSetting = settings.useAlternativeRouting {
            stubbedAppSettings.useAlternativeRouting = changedSetting
        }

        return .ok
    }

    public func startAutoLockCountdown() {
        fatalError(#function)
    }

    public func deleteAccount(userId: String) async -> VoidSessionResult {
        fatalError(#function)
    }

    public func deletePinCode(pin: [UInt32]) async -> proton_app_uniffi.MailSessionDeletePinCodeResult {
        fatalError(#function)
    }

    public func exportLogs(filePath: String) -> proton_app_uniffi.MailSessionExportLogsResult {
        fatalError(#function)
    }

    public func getAccount(userId: String) async -> MailSessionGetAccountResult {
        fatalError(#function)
    }

    public func getAccountBlocking(userId: String) -> MailSessionGetAccountResult {
        fatalError(#function)
    }

    public func getAccountSessions(account: StoredAccount) async -> MailSessionGetAccountSessionsResult {
        fatalError(#function)
    }

    public func getAccountState(userId: String) async -> MailSessionGetAccountStateResult {
        fatalError(#function)
    }

    public func getAccountStateBlocking(userId: String) -> MailSessionGetAccountStateResult {
        fatalError()
    }

    public func getAccounts() async -> MailSessionGetAccountsResult {
        fatalError(#function)
    }

    public func getAccountsBlocking() -> MailSessionGetAccountsResult {
        fatalError(#function)
    }

    public func getAppSettings() async -> MailSessionGetAppSettingsResult {
        .ok(stubbedAppSettings)
    }

    public func getPrimaryAccount() async -> MailSessionGetPrimaryAccountResult {
        fatalError(#function)
    }

    public func getPrimaryAccountBlocking() -> MailSessionGetPrimaryAccountResult {
        fatalError(#function)
    }

    public func getSession(sessionId: String) async -> MailSessionGetSessionResult {
        .ok(storedSessions.first { $0.sessionId() == sessionId })
    }

    public func getSessionBlocking(sessionId: String) -> MailSessionGetSessionResult {
        fatalError(#function)
    }

    public func getSessionState(sessionId: String) async -> MailSessionGetSessionStateResult {
        fatalError(#function)
    }

    public func getSessionStateBlocking(sessionId: String) -> MailSessionGetSessionStateResult {
        fatalError(#function)
    }

    public func getSessions() async -> MailSessionGetSessionsResult {
        .ok(storedSessions)
    }

    public func getSessionsBlocking(account: StoredAccount) -> MailSessionGetAccountSessionsResult {
        fatalError(#function)
    }

    public func initializedUserSessionFromStoredSession(session: StoredSession) -> MailSessionInitializedUserSessionFromStoredSessionResult {
        if let userSession = userSessions.first(where: { $0.sessionId == session.sessionId() }) {
            .ok(userSession)
        } else {
            fatalError("session not configured")
        }
    }

    public func logoutAccount(userId: String) async -> VoidSessionResult {
        fatalError(#function)
    }

    public func newLoginFlow() async -> MailSessionNewLoginFlowResult {
        fatalError(#function)
    }

    public func newSignupFlow() async -> MailSessionNewSignupFlowResult {
        fatalError(#function)
    }

    public func pauseWork() {
        fatalError(#function)
    }

    public func pauseWorkAndWait() {
        fatalError(#function)
    }

    public func registerDeviceTask() -> MailSessionRegisterDeviceTaskResult {
        registerDeviceCallCount += 1
        return .ok(stubbedRegisterDeviceTaskHandleFactory())
    }

    public func remainingPinAttempts() async -> MailSessionRemainingPinAttemptsResult {
        fatalError(#function)
    }

    public func resumeLoginFlow(userId: String, sessionId: String) async -> MailSessionResumeLoginFlowResult {
        fatalError(#function)
    }

    public func resumeWork() {
        fatalError(#function)
    }

    public func setBiometricsAppProtection() async -> MailSessionSetBiometricsAppProtectionResult {
        .ok
    }

    public func setPinCode(pin: [UInt32]) async -> MailSessionSetPinCodeResult {
        setPinCodeInvocations.append(pin)
        return .ok
    }

    public func setPrimaryAccount(userId: String) async -> VoidSessionResult {
        setPrimaryAccountInvocations.append(userId)
        onPrimaryAccountChanged?(userId)
        return .ok
    }

    public func shouldAutoLock() async -> MailSessionShouldAutoLockResult {
        fatalError(#function)
    }

    public func signOutAll() async -> MailSessionSignOutAllResult {
        signOutAllCallCount += 1
        return .ok
    }

    public func startBackgroundExecution(callback: any BackgroundExecutionCallback) -> MailSessionStartBackgroundExecutionResult {
        fatalError()
    }

    public func startBackgroundExecutionWithDuration(
        durationSeconds: UInt64,
        callback: any BackgroundExecutionCallback
    ) -> MailSessionStartBackgroundExecutionWithDurationResult {
        fatalError(#function)
    }

    public func toPrimaryUserSession() async -> MailSessionToPrimaryUserSessionResult {
        .ok(primaryUserSessionStub!)
    }

    public func toUserSession(ffiFlow: LoginFlow) async -> MailSessionToUserSessionResult {
        fatalError(#function)
    }

    public func unsetBiometricsAppProtection() async -> MailSessionUnsetBiometricsAppProtectionResult {
        fatalError(#function)
    }

    public func userSessionFromStoredSession(session: StoredSession) -> MailSessionUserSessionFromStoredSessionResult {
        fatalError(#function)
    }

    public func verifyPinCode(pin: [UInt32]) async -> MailSessionVerifyPinCodeResult {
        fatalError(#function)
    }

    public func watchAccountSessions(account: StoredAccount, callback: any LiveQueryCallback) async -> MailSessionWatchAccountSessionsResult {
        fatalError(#function)
    }

    public func watchAccounts(callback: any LiveQueryCallback) async -> MailSessionWatchAccountsResult {
        fatalError(#function)
    }

    public func watchAccountsAsync(callback: any AsyncLiveQueryCallback) async -> MailSessionWatchAccountsAsyncResult {
        fatalError(#function)
    }

    public func watchSessions(callback: any LiveQueryCallback) async -> MailSessionWatchSessionsResult {
        fatalError(#function)
    }

    public func watchSessionsAsync(callback: any AsyncLiveQueryCallback) async -> MailSessionWatchSessionsAsyncResult {
        watchSessionsAsyncCallback = callback
        return .ok(.init(sessions: storedSessions, handle: WatchHandleDummy(noPointer: .init())))
    }
}

private extension MailUserSession {
    var sessionId: String {
        switch sessionId() {
        case .ok(let id):
            id
        case .error(let error):
            fatalError("\(error)")
        }
    }
}
