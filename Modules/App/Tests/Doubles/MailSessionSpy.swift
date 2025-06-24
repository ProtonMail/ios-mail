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

final class MailSessionSpy: MailSessionProtocol {
    var onPrimaryAccountChanged: (@Sendable (String) -> Void)?
    var appProtectionStub: AppProtection = .none

    var storedSessions: [StoredSessionStub] = [] {
        didSet {
            Task {
                await watchSessionsAsyncCallback?.onUpdate()
            }
        }
    }

    var stubbedRegisterDeviceTaskHandleFactory: () -> RegisterDeviceTaskHandle = {
        fatalError("not stubbed")
    }

    var userSessions: [MailUserSession] = []

    private(set) var changeAppSettingsInvocations: [AppSettingsDiff] = []
    private(set) var registerDeviceCallCount = 0
    private(set) var setPinCodeInvocations: [[UInt32]] = []
    private(set) var setPrimaryAccountInvocations: [String] = []
    private(set) var signOutAllCallCount = 0

    private var stubbedAppSettings = AppSettings(
        appearance: .system,
        protection: .none,
        autoLock: .minutes(0),
        useCombineContacts: false,
        useAlternativeRouting: true
    )

    private var watchSessionsAsyncCallback: AsyncLiveQueryCallback?

    // MARK: - MailSessionProtocol

    func biometricsCheckPassed() {
        fatalError(#function)
    }

    func allMessagesWereSent() async -> MailSessionAllMessagesWereSentResult {
        fatalError(#function)
    }

    func appProtection() async -> MailSessionAppProtectionResult {
        .ok(appProtectionStub)
    }

    func changeAppSettings(settings: AppSettingsDiff) async -> MailSessionChangeAppSettingsResult {
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

    func startAutoLockCountdown() {
        fatalError(#function)
    }

    func deleteAccount(userId: String) async -> VoidSessionResult {
        fatalError(#function)
    }

    func deletePinCode(pin: [UInt32]) async -> proton_app_uniffi.MailSessionDeletePinCodeResult {
        fatalError(#function)
    }

    func getAccount(userId: String) async -> MailSessionGetAccountResult {
        fatalError(#function)
    }

    func getAccountBlocking(userId: String) -> MailSessionGetAccountResult {
        fatalError(#function)
    }

    func getAccountSessions(account: StoredAccount) async -> MailSessionGetAccountSessionsResult {
        fatalError(#function)
    }

    func getAccountState(userId: String) async -> MailSessionGetAccountStateResult {
        fatalError(#function)
    }

    func getAccountStateBlocking(userId: String) -> MailSessionGetAccountStateResult {
        fatalError()
    }

    func getAccounts() async -> MailSessionGetAccountsResult {
        fatalError(#function)
    }

    func getAccountsBlocking() -> MailSessionGetAccountsResult {
        fatalError(#function)
    }

    func getAppSettings() async -> MailSessionGetAppSettingsResult {
        .ok(stubbedAppSettings)
    }

    func getPrimaryAccount() async -> MailSessionGetPrimaryAccountResult {
        fatalError(#function)
    }

    func getPrimaryAccountBlocking() -> MailSessionGetPrimaryAccountResult {
        fatalError(#function)
    }

    func getSession(sessionId: String) async -> MailSessionGetSessionResult {
        .ok(storedSessions.first { $0.sessionId() == sessionId })
    }

    func getSessionBlocking(sessionId: String) -> MailSessionGetSessionResult {
        fatalError(#function)
    }

    func getSessionState(sessionId: String) async -> MailSessionGetSessionStateResult {
        fatalError(#function)
    }

    func getSessionStateBlocking(sessionId: String) -> MailSessionGetSessionStateResult {
        fatalError(#function)
    }

    func getSessions() async -> MailSessionGetSessionsResult {
        .ok(storedSessions)
    }

    func getSessionsBlocking(account: StoredAccount) -> MailSessionGetAccountSessionsResult {
        fatalError(#function)
    }

    func getUnsentMessagesIdsInQueue(userId: String) async -> MailSessionGetUnsentMessagesIdsInQueueResult {
        fatalError(#function)
    }

    func initializedUserContextFromSession(session: StoredSession) -> MailSessionInitializedUserContextFromSessionResult {
        fatalError(#function)
    }

    func logoutAccount(userId: String) async -> VoidSessionResult {
        fatalError(#function)
    }

    func newLoginFlow() async -> MailSessionNewLoginFlowResult {
        fatalError(#function)
    }

    func newSignupFlow() async -> MailSessionNewSignupFlowResult {
        fatalError(#function)
    }

    func pauseWork() {
        fatalError(#function)
    }

    func pauseWorkAndWait() {
        fatalError(#function)
    }

    func registerDeviceTask() -> MailSessionRegisterDeviceTaskResult {
        registerDeviceCallCount += 1
        return .ok(stubbedRegisterDeviceTaskHandleFactory())
    }

    func remainingPinAttempts() async -> MailSessionRemainingPinAttemptsResult {
        fatalError(#function)
    }

    func resumeLoginFlow(userId: String, sessionId: String) async -> MailSessionResumeLoginFlowResult {
        fatalError(#function)
    }

    func resumeWork() {
        fatalError(#function)
    }

    func setBiometricsAppProtection() async -> MailSessionSetBiometricsAppProtectionResult {
        .ok
    }

    func setPinCode(pin: [UInt32]) async -> MailSessionSetPinCodeResult {
        setPinCodeInvocations.append(pin)
        return .ok
    }

    func setPrimaryAccount(userId: String) async -> VoidSessionResult {
        setPrimaryAccountInvocations.append(userId)
        onPrimaryAccountChanged?(userId)
        return .ok
    }

    func shouldAutoLock() async -> MailSessionShouldAutoLockResult {
        fatalError(#function)
    }

    func signOutAll() async -> MailSessionSignOutAllResult {
        signOutAllCallCount += 1
        return .ok
    }

    func startBackgroundExecution(callback: any BackgroundExecutionCallback) -> MailSessionStartBackgroundExecutionResult {
        fatalError()
    }

    func startBackgroundExecutionWithDuration(
        durationSeconds: UInt64,
        callback: any BackgroundExecutionCallback
    ) -> MailSessionStartBackgroundExecutionWithDurationResult {
        fatalError(#function)
    }

    func toUserContext(ffiFlow: LoginFlow) async -> MailSessionToUserContextResult {
        fatalError(#function)
    }

    func unsetBiometricsAppProtection() async -> MailSessionUnsetBiometricsAppProtectionResult {
        fatalError(#function)
    }

    func userContextFromSession(session: StoredSession) -> MailSessionUserContextFromSessionResult {
        if let userSession = userSessions.first(where: { try! $0.sessionId().get() == session.sessionId() }) {
            .ok(userSession)
        } else {
            fatalError("session not configured")
        }
    }

    func verifyPinCode(pin: [UInt32]) async -> MailSessionVerifyPinCodeResult {
        fatalError(#function)
    }

    func watchAccountSessions(account: StoredAccount, callback: any LiveQueryCallback) async -> MailSessionWatchAccountSessionsResult {
        fatalError(#function)
    }

    func watchAccounts(callback: any LiveQueryCallback) async -> MailSessionWatchAccountsResult {
        fatalError(#function)
    }

    func watchAccountsAsync(callback: any AsyncLiveQueryCallback) async -> MailSessionWatchAccountsAsyncResult {
        fatalError(#function)
    }

    func watchSessions(callback: any LiveQueryCallback) async -> MailSessionWatchSessionsResult {
        fatalError(#function)
    }

    func watchSessionsAsync(callback: any AsyncLiveQueryCallback) async -> MailSessionWatchSessionsAsyncResult {
        watchSessionsAsyncCallback = callback
        return .ok(.init(sessions: storedSessions, handle: WatchHandleDummy(noPointer: .init())))
    }
}
