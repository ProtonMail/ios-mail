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

    var storedSessions: [StoredSessionStub] = [] {
        didSet {
            Task {
                await watchSessionsAsyncCallback?.onUpdate()
            }
        }
    }

    private var watchSessionsAsyncCallback: AsyncLiveQueryCallback?

    var backgroundExecutionFinishedWithSuccess = true
    var backgroundExecutionHandleStub = BackgroundExecutionHandleStub()
    private(set) var startBackgroundExecutionInvokeCount = 0

    // MARK: - MailSessionProtocol

    func deleteAccount(userId: String) async -> VoidSessionResult {
        fatalError()
    }

    func getAccount(userId: String) async -> MailSessionGetAccountResult {
        fatalError()
    }

    func getAccountBlocking(userId: String) -> MailSessionGetAccountResult {
        fatalError()
    }

    func getAccountSessions(account: StoredAccount) async -> MailSessionGetAccountSessionsResult {
        fatalError()
    }

    func getAccountState(userId: String) async -> MailSessionGetAccountStateResult {
        fatalError()
    }

    func getAccountStateBlocking(userId: String) -> MailSessionGetAccountStateResult {
        fatalError()
    }

    func getAccounts() async -> MailSessionGetAccountsResult {
        fatalError()
    }

    func getAccountsBlocking() -> MailSessionGetAccountsResult {
        fatalError()
    }

    func getPrimaryAccount() async -> MailSessionGetPrimaryAccountResult {
        fatalError()
    }

    func getPrimaryAccountBlocking() -> MailSessionGetPrimaryAccountResult {
        fatalError()
    }

    func getSession(sessionId: String) async -> MailSessionGetSessionResult {
        fatalError()
    }

    func getSessionBlocking(sessionId: String) -> MailSessionGetSessionResult {
        fatalError()
    }

    func getSessionState(sessionId: String) async -> MailSessionGetSessionStateResult {
        fatalError()
    }

    func getSessionStateBlocking(sessionId: String) -> MailSessionGetSessionStateResult {
        fatalError()
    }

    func getSessions() async -> MailSessionGetSessionsResult {
        .ok(storedSessions)
    }

    func getSessionsBlocking(account: StoredAccount) -> MailSessionGetAccountSessionsResult {
        fatalError()
    }

    func isNetworkConnected() -> Bool {
        fatalError()
    }

    func logoutAccount(userId: String) async -> VoidSessionResult {
        fatalError()
    }

    func newLoginFlow() async -> MailSessionNewLoginFlowResult {
        fatalError()
    }

    func resumeLoginFlow(userId: String, sessionId: String) async -> MailSessionResumeLoginFlowResult {
        fatalError()
    }

    func setNetworkConnected(online: Bool) {
        fatalError()
    }

    func setPrimaryAccount(userId: String) async -> VoidSessionResult {
        fatalError()
    }

    func userContextFromSession(session: StoredSession) -> MailSessionUserContextFromSessionResult {
        fatalError()
    }

    func watchAccountSessions(account: StoredAccount, callback: any LiveQueryCallback) async -> MailSessionWatchAccountSessionsResult {
        fatalError()
    }

    func watchAccounts(callback: any LiveQueryCallback) async -> MailSessionWatchAccountsResult {
        fatalError()
    }

    func watchAccountsAsync(callback: any AsyncLiveQueryCallback) async -> MailSessionWatchAccountsAsyncResult {
        fatalError()
    }

    func watchSessions(callback: any LiveQueryCallback) async -> MailSessionWatchSessionsResult {
        fatalError()
    }

    func startBackgroundExecution(callback: LiveQueryCallback) -> MailSessionStartBackgroundExecutionResult {
        startBackgroundExecutionInvokeCount += 1

        if backgroundExecutionFinishedWithSuccess {
            callback.onUpdate()
        }

        return .ok(backgroundExecutionHandleStub)
    }

    func watchSessionsAsync(callback: any AsyncLiveQueryCallback) async -> MailSessionWatchSessionsAsyncResult {
        watchSessionsAsyncCallback = callback

        return .ok(.init(sessions: storedSessions, handle: WatchHandleDummy(noPointer: .init())))
    }
}
