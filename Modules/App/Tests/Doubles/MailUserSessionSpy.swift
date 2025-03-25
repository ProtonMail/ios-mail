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

    var pollEventsResultStub = VoidEventResult.ok

    private(set) var pollEventInvokeCount = 0
    private(set) var executePendingActionsInvokeCount = 0

    // MARK: - MailUserSessionProtocol

    func pollEvents() async -> VoidEventResult {
        pollEventInvokeCount += 1

        return pollEventsResultStub
    }

    func accountDetails() async -> MailUserSessionAccountDetailsResult {
        fatalError(#function)
    }

    func applicableLabels() async -> MailUserSessionApplicableLabelsResult {
        fatalError(#function)
    }

    var connectionStatusStub: MailUserSessionConnectionStatusResult = .ok(.online)

    func connectionStatus() async -> MailUserSessionConnectionStatusResult {
        connectionStatusStub
    }

    func executeWhenOnline(callback: LiveQueryCallback) {
        fatalError(#function)
    }

    func fork() async -> MailUserSessionForkResult {
        fatalError(#function)
    }

    func getAttachment(localAttachmentId: Id) async -> MailUserSessionGetAttachmentResult {
        fatalError(#function)
    }

    func imageForSender(
        address: String,
        bimiSelector: String?,
        displaySenderImage: Bool,
        size: UInt32?,
        mode: String?,
        format: String?
    ) async -> MailUserSessionImageForSenderResult {
        fatalError(#function)
    }

    func initialize(cb: any MailUserSessionInitializationCallback) async -> VoidSessionResult {
        fatalError(#function)
    }

    func logout() async -> VoidSessionResult {
        fatalError(#function)
    }

    func movableFolders() async -> MailUserSessionMovableFoldersResult {
        fatalError(#function)
    }

    func observeEventLoopErrors(callback: any EventLoopErrorObserver) -> MailUserSessionObserveEventLoopErrorsResult {
        fatalError(#function)
    }
    
    func sessionId() -> proton_app_uniffi.MailUserSessionSessionIdResult {
        fatalError(#function)
    }

    func sessionUuid() async -> MailUserSessionSessionUuidResult {
        fatalError(#function)
    }

    func user() async -> MailUserSessionUserResult {
        fatalError(#function)
    }

    func userId() -> MailUserSessionUserIdResult {
        fatalError(#function)
    }

    var draftSendResultUnseenResultStub = DraftSendResultUnseenResult.ok([])

    func draftSendResultUnseen() async -> DraftSendResultUnseenResult {
        draftSendResultUnseenResultStub
    }

    func userSettings() async -> MailUserSessionUserSettingsResult {
        fatalError(#function)
    }

    // MARK: - Payments

    func getPaymentsPlans(options: GetPaymentsPlansOptions) async -> MailUserSessionGetPaymentsPlansResult {
        fatalError(#function)
    }
    
    func getPaymentsSubscription() async -> MailUserSessionGetPaymentsSubscriptionResult {
        fatalError(#function)
    }
    
    func postPaymentsSubscription(
        subscription: NewSubscription,
        newValues: NewSubscriptionValues
    ) async -> MailUserSessionPostPaymentsSubscriptionResult {
        fatalError(#function)
    }
    
    func postPaymentsTokens(
        amount: UInt64,
        currency: String,
        payment: PaymentReceipt
    ) async -> MailUserSessionPostPaymentsTokensResult {
        fatalError(#function)
    }
    
}
