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

import InboxComposer
import InboxCore
import InboxCoreUI
import InboxIAP
import proton_app_uniffi
import SwiftUI

@MainActor
public final class ShareScreenModel: ObservableObject {
    typealias MakeNewDraft = (MailUserSession, SharedContent) async throws -> AppDraftProtocol

    enum ViewState {
        case preparingAfterLaunch
        case initializingComposer
        case composing(AppDraftProtocol, ComposerScreen.Dependencies, UpsellCoordinator)
        case locked(LockScreenState.LockScreenType, MailSessionProtocol)
        case error(Error)
    }

    @Published private(set) var state: ViewState = .preparingAfterLaunch
    @Published private(set) public var alert: String?

    private let extensionContext: NSExtensionContext
    private let makeNewDraft: MakeNewDraft
    private let sessionHolder: SessionHolder
    private let upsellConfiguration: UpsellConfiguration

    public convenience init(apiEnvId: ApiEnvId, extensionContext: NSExtensionContext) {
        self.init(
            apiEnvId: apiEnvId,
            extensionContext: extensionContext,
            makeMailSession: {
                try createMailSession(params: $0, keyChain: $1, hvNotifier: $2, deviceInfoProvider: $3, issueReporter: $4).get()
            },
            makeNewDraft: {
                try await DraftStubWriter().createDraftStub(basedOn: $1)
                return try await newDraft(session: $0, createMode: .fromIosShareExtension, imagePolicy: .safe).get()
            }
        )
    }

    init(
        apiEnvId: ApiEnvId,
        extensionContext: NSExtensionContext,
        makeMailSession: @escaping SessionHolder.MakeMailSession,
        makeNewDraft: @escaping MakeNewDraft
    ) {
        self.extensionContext = extensionContext
        self.makeNewDraft = makeNewDraft
        sessionHolder = .init(apiEnvId: apiEnvId, makeMailSession: makeMailSession)
        upsellConfiguration = .mail(apiEnvId: apiEnvId)
    }

    func prepare() async {
        do {
            let mailSession = try sessionHolder.mailSession()
            let appProtection = try await mailSession.appProtection().get()

            if let lockScreenType = appProtection.lockScreenType {
                state = .locked(lockScreenType, mailSession)
            } else {
                await onAppUnlocked()
            }
        } catch {
            AppLogger.log(error: error, category: .shareExtension)
            state = .error(error)
        }
    }

    func onAppUnlocked() async {
        state = .initializingComposer

        do {
            let userSession = try await sessionHolder.primaryUserSession()
            let draft = try await prepareDraft(userSession: userSession)

            let dependencies = ComposerScreen.Dependencies(
                contactProvider: .productionInstance(session: userSession),
                userSession: userSession
            )

            let upsellCoordinator = UpsellCoordinator(mailUserSession: userSession, configuration: upsellConfiguration)

            state = .composing(draft, dependencies, upsellCoordinator)
        } catch {
            AppLogger.log(error: error, category: .shareExtension)
            state = .error(error)
        }
    }

    func onComposerDismissed(reason: ComposerDismissReason) {
        switch reason {
        case .dismissedManually, .draftDiscarded:
            dismissShareExtension(error: NSError.userCancelled)
        case .messageScheduled(let messageID), .messageSent(let messageID):
            alert = L10n.Sending.sendingInProgress.string

            Task {
                do {
                    try await waitUntilMessageSendingIsFinished(messageID: messageID)
                    alert = L10n.Sending.messageSent.string
                } catch {
                    AppLogger.log(error: error, category: .shareExtension)
                    alert = error.localizedDescription
                }

                try? await Task.sleep(for: .seconds(2))

                dismissShareExtension(error: nil)
            }
        }
    }

    func dismissShareExtension(error: Error?) {
        if let error {
            AppLogger.log(message: "Sharing cancelled", category: .shareExtension)
            extensionContext.cancelRequest(withError: error)
        } else {
            extensionContext.completeRequest(returningItems: nil) { expired in
                if expired {
                    AppLogger.log(message: "Sharing interrupted", category: .shareExtension, isError: true)
                } else {
                    AppLogger.log(message: "Sharing completed", category: .shareExtension)
                }
            }
        }
    }

    private func prepareDraft(userSession: MailUserSession) async throws -> AppDraftProtocol {
        let inputItems = extensionContext.inputItems.map { $0 as! NSExtensionItem }
        let sharedContent = try await SharedItemsParser.parse(extensionItems: inputItems)
        return try await makeNewDraft(userSession, sharedContent)
    }

    private func waitUntilMessageSendingIsFinished(messageID: ID) async throws {
        let userSession = try await sessionHolder.primaryUserSession()
        let sendResultPublisher = SendResultPublisher(userSession: userSession)

        for await sendResultInfo in sendResultPublisher.results.values where sendResultInfo.messageId == messageID {
            switch sendResultInfo.type {
            case .scheduling, .sending:
                break
            case .scheduled, .sent:
                return
            case .error(let error):
                throw error
            }
        }
    }
}

private extension NSError {
    static let userCancelled = NSError(domain: Bundle.main.bundleIdentifier!, code: NSUserCancelledError)
}
