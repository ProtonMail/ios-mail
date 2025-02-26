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

@testable import ProtonMail
import proton_app_uniffi

class MailUserSessionSpy: MailUserSessionProtocol {
    // this will be reworked in https://protonag.atlassian.net/browse/ET-2226
//    var pendingActionsExecutionResultStub = MailUserSessionExecutePendingActionsResult.ok(1)
    var pollEventsResultStub = VoidEventResult.ok

    private(set) var pollEventInvokeCount = 0
    private(set) var executePendingActionsInvokeCount = 0

    // MARK: - MailUserSessionProtocol

    func pollEvents() async -> VoidEventResult {
        pollEventInvokeCount += 1

        return pollEventsResultStub
    }

    func accountDetails() async -> MailUserSessionAccountDetailsResult {
        fatalError()
    }

    func applicableLabels() async -> MailUserSessionApplicableLabelsResult {
        fatalError()
    }

    func connectionStatus() async -> MailUserSessionConnectionStatusResult {
        fatalError()
    }

    func executeWhenOnline(callback: any proton_app_uniffi.LiveQueryCallback) {
        fatalError()
    }

    func fork() async -> MailUserSessionForkResult {
        fatalError()
    }

    func getAttachment(localAttachmentId: Id) async -> MailUserSessionGetAttachmentResult {
        fatalError()
    }

    func imageForSender(
        address: String,
        bimiSelector: String?,
        displaySenderImage: Bool,
        size: UInt32?,
        mode: String?,
        format: String?
    ) async -> MailUserSessionImageForSenderResult {
        fatalError()
    }

    func initialize(cb: any MailUserSessionInitializationCallback) async -> VoidSessionResult {
        fatalError()
    }

    func logout() async -> VoidSessionResult {
        fatalError()
    }

    func movableFolders() async -> MailUserSessionMovableFoldersResult {
        fatalError()
    }

    func observeEventLoopErrors(callback: any EventLoopErrorObserver) -> MailUserSessionObserveEventLoopErrorsResult {
        fatalError()
    }

    func sessionId() -> MailUserSessionSessionIdResult {
        fatalError()
    }

    func user() async -> MailUserSessionUserResult {
        fatalError()
    }

    func userId() -> MailUserSessionUserIdResult {
        fatalError()
    }

}
