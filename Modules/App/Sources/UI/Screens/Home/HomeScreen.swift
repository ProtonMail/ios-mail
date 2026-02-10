// Copyright (c) 2024 Proton Technologies AG
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

import AccountLogin
import Combine
import InboxAttribution
import InboxCore
import InboxCoreUI
import InboxIAP
import PaymentsNG
import ProtonUIFoundations
import SwiftUI
import proton_app_uniffi

import enum InboxComposer.ComposerDismissReason

struct HomeScreen: View {
    enum ModalState: Identifiable {
        case contacts
        case labelOrFolderCreation
        case settings
        case reportProblem
        case subscriptions
        case upsell(UpsellScreenModel)

        // MARK: - Identifiable

        var id: String {
            .init(describing: self)
        }
    }

    @EnvironmentObject private var appUIStateStore: AppUIStateStore
    @EnvironmentObject private var toastStateStore: ToastStateStore
    @Environment(\.mainWindowSize) var mainWindowSize
    @StateObject private var appRoute: AppRouteState
    @StateObject private var composerCoordinator: ComposerCoordinator
    @StateObject private var upsellEligibilityPublisher: UpsellEligibilityPublisher
    @State private var messageQuickLook = MessageQuickLook()
    @State private var modalState: ModalState?
    @State private var isNotificationPromptPresented = false
    @StateObject private var userAttributionService: UserAttributionService
    @StateObject private var eventLoopErrorCoordinator: EventLoopErrorCoordinator
    @StateObject private var upsellCoordinator: UpsellCoordinator
    @StateObject private var userAnalyticsConfigurator: UserAnalyticsConfigurator
    @ObservedObject private var appContext: AppContext

    private let userSession: MailUserSession
    private let mailSettingsLiveQuery: MailSettingLiveQuerying
    private let makeSidebarScreen: (@escaping (SidebarItem) -> Void) -> SidebarScreen
    private let modalFactory: HomeScreenModalFactory
    private let notificationAuthorizationStore: NotificationAuthorizationStore

    init(
        appContext: AppContext,
        userSession: MailUserSession,
        toastStateStore: ToastStateStore,
        analytics: Analytics
    ) {
        _appRoute = .init(wrappedValue: .initialState)
        _composerCoordinator = .init(wrappedValue: .init(userSession: userSession, toastStateStore: toastStateStore))
        let upsellEligibilityPublisher = UpsellEligibilityPublisher(userSession: userSession)
        _upsellEligibilityPublisher = .init(wrappedValue: upsellEligibilityPublisher)
        self.appContext = appContext
        self.userSession = userSession
        self.mailSettingsLiveQuery = MailSettingsLiveQuery(userSession: userSession)
        self.makeSidebarScreen = { selectedItem in
            SidebarScreen(
                state: .initial,
                userSession: userSession,
                upsellEligibilityPublisher: upsellEligibilityPublisher,
                selectedItem: selectedItem
            )
        }
        self._eventLoopErrorCoordinator = .init(
            wrappedValue: EventLoopErrorCoordinator(userSession: userSession, toastStateStore: toastStateStore)
        )

        let userAttributionService = UserAttributionService(
            userSettingsProvider: { try await userSession.userSettings().get() },
            userDefaults: appContext.userDefaults
        )
        self._userAttributionService = .init(wrappedValue: userAttributionService)

        let newUpsellCoordinator = UpsellCoordinator(
            mailUserSession: userSession,
            userAttributionService: userAttributionService,
            configuration: .mail
        )
        _upsellCoordinator = .init(wrappedValue: newUpsellCoordinator)

        self.modalFactory = HomeScreenModalFactory(
            mailUserSession: userSession,
            accountAuthCoordinator: appContext.accountAuthCoordinator,
            upsellCoordinator: newUpsellCoordinator
        )
        notificationAuthorizationStore = .init(userDefaults: appContext.userDefaults)
        _userAnalyticsConfigurator = .init(wrappedValue: .init(mailUserSession: userSession, analytics: analytics))
    }

    // MARK: - View

    var body: some View {
        ZStack {
            MailboxScreen(
                mailSettingsLiveQuery: mailSettingsLiveQuery,
                appRoute: appRoute,
                userSession: userSession,
                draftPresenter: composerCoordinator.draftPresenter
            )
            .introductionViews(
                dependencies: .init(
                    notificationAuthorizationStore: notificationAuthorizationStore,
                    userDefaults: appContext.userDefaults
                )
            )
            .environmentObject(composerCoordinator)
            .environment(messageQuickLook)

            makeSidebarScreen { selectedItem in
                switch selectedItem {
                case .upsell(let upsellType):
                    presentUpsellScreen(ofType: upsellType)
                case .system(let systemFolder):
                    appRoute.updateRoute(
                        to: .mailbox(
                            selectedMailbox: .systemFolder(
                                labelId: systemFolder.folderID,
                                systemFolder: systemFolder.type
                            )))
                case .other(let otherItem):
                    switch otherItem.type {
                    case .bugReport:
                        modalState = .reportProblem
                    case .contacts:
                        modalState = .contacts
                    case .createFolder, .createLabel:
                        modalState = .labelOrFolderCreation
                    case .settings:
                        modalState = .settings
                    case .shareLogs:
                        presentShareFileController()
                    case .subscriptions:
                        modalState = .subscriptions
                    }
                case .label(let label):
                    appRoute.updateRoute(
                        to: .mailbox(
                            selectedMailbox: .customLabel(
                                labelId: label.labelID,
                                name: label.name.stringResource
                            )))
                case .folder(let folder):
                    appRoute.updateRoute(
                        to: .mailbox(
                            selectedMailbox: .customFolder(
                                labelId: folder.folderID,
                                name: folder.name.stringResource
                            )))
                }
            }
            .zIndex(appUIStateStore.sidebarState.zIndex)
        }
        .composer(screen: .home, coordinator: composerCoordinator)
        .onReceive(composerCoordinator.messageSent) {
            requestNotificationAuthorizationIfApplicable()
            notifyEmailSent()
        }
        .sheet(item: $modalState) { state in
            modalFactory.makeModal(for: state, draftPresenter: composerCoordinator.draftPresenter)
        }
        .sheet(isPresented: $isNotificationPromptPresented) {
            NotificationAuthorizationPrompt(
                trigger: .messageSent,
                userDidRespond: userDidRespondToAuthorizationRequest
            )
        }
        .quickLookPreview($messageQuickLook.shortLivedURL)
        .onOpenURL(perform: handleDeepLink)
        .onLoad {
            Task {
                if AnalyticsState.shouldConfigureAnalytics {
                    Task {
                        await userAnalyticsConfigurator.observeUserAnalyticsSettings()
                    }
                }
                await upsellCoordinator.prewarm()
                await userAttributionService.handle(event: .signedIn)
            }
        }
        .environmentObject(upsellCoordinator)
        .environmentObject(userAttributionService)
        .environment(\.upsellEligibility, upsellEligibilityPublisher.state)
    }

    private func requestNotificationAuthorizationIfApplicable() {
        Task {
            isNotificationPromptPresented = await notificationAuthorizationStore.shouldRequestAuthorization(
                trigger: .messageSent
            )
        }
    }

    private func notifyEmailSent() {
        Task {
            await userAttributionService.handle(event: .firstActionPerformed)
        }
    }

    private func userDidRespondToAuthorizationRequest(accepted: Bool) {
        Task {
            await notificationAuthorizationStore.userDidRespondToAuthorizationRequest(accepted: accepted)
            isNotificationPromptPresented = false
        }
    }

    private func presentUpsellScreen(ofType upsellType: UpsellType) {
        Task {
            do {
                let upsellScreenModel = try await upsellCoordinator.presentUpsellScreen(entryPoint: .navbarUpsell, upsellType: upsellType)
                modalState = .upsell(upsellScreenModel)
            } catch {
                toastStateStore.present(toast: .error(message: error.localizedDescription))
            }
        }
    }

    private func presentShareFileController() {
        do {
            let sourceLogFile = try LogFileProvider.file(mailSession: appContext.mailSession)
            var filesToShare: [URL] = [sourceLogFile]

            if let transactionLog = TransactionsObserver.shared.generateTransactionLog() {
                filesToShare.append(transactionLog)
            }

            let activityController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
            let rootViewController = UIApplication.shared.keyWindow?.rootViewController

            if let popoverPresentationController = activityController.popoverPresentationController {
                popoverPresentationController.sourceView = rootViewController?.view
                popoverPresentationController.sourceRect = .init(
                    origin: .init(x: appUIStateStore.sidebarWidth, y: mainWindowSize.height / 2),
                    size: .zero
                )
            }

            rootViewController?.present(activityController, animated: true)
        } catch {
            toastStateStore.present(toast: .error(message: error.localizedDescription))
        }
    }

    private func handleDeepLink(_ deepLink: URL) {
        guard isCurrentSessionActive() else {
            return
        }

        if let route = DeepLinkRouteCoder.decode(deepLink: deepLink) {
            modalState = nil
            appUIStateStore.toggleSidebar(isOpen: false)
            messageQuickLook.dismiss()

            Task {
                await ensurePresentedViewsAreDismissed()
                appRoute.updateRoute(to: route)
            }
        }
    }

    private func isCurrentSessionActive() -> Bool {
        guard let activeSession = appContext.sessionState.userSession else {
            return false
        }

        return ObjectIdentifier(activeSession) == ObjectIdentifier(userSession)
    }

    private func ensurePresentedViewsAreDismissed() async {
        await UIApplication.shared.keyWindow?.rootViewController?.presentedViewController?.dismissAndWait(animated: true)
    }
}

private extension UIViewController {
    func dismissAndWait(animated: Bool) async {
        await withCheckedContinuation { continuation in
            dismiss(animated: animated, completion: continuation.resume)
        }
    }
}
