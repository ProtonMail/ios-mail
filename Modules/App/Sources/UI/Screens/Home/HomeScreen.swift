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
import InboxCore
import InboxCoreUI
import enum InboxComposer.ComposerDismissReason
import InboxIAP
import proton_app_uniffi
import SwiftUI

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
    @StateObject private var appRoute: AppRouteState
    @StateObject private var composerCoordinator: ComposerCoordinator
    @StateObject private var upsellButtonVisibilityPublisher: UpsellButtonVisibilityPublisher
    @State private var modalState: ModalState?
    @State private var isNotificationPromptPresented = false
    @StateObject private var eventLoopErrorCoordinator: EventLoopErrorCoordinator
    @StateObject private var upsellCoordinator: UpsellCoordinator
    @ObservedObject private var appContext: AppContext

    private let userSession: MailUserSession
    private let mailSettingsLiveQuery: MailSettingLiveQuerying
    private let makeSidebarScreen: (@escaping (SidebarItem) -> Void) -> SidebarScreen
    private let userDefaults: UserDefaults
    private let modalFactory: HomeScreenModalFactory
    private let notificationAuthorizationStore: NotificationAuthorizationStore

    init(appContext: AppContext, userSession: MailUserSession, toastStateStore: ToastStateStore) {
        _appRoute = .init(wrappedValue: .initialState)
        _composerCoordinator = .init(wrappedValue: .init(userSession: userSession, toastStateStore: toastStateStore))
        let upsellButtonVisibilityPublisher = UpsellButtonVisibilityPublisher(userSession: userSession)
        _upsellButtonVisibilityPublisher = .init(wrappedValue: upsellButtonVisibilityPublisher)
        self.appContext = appContext
        self.userSession = userSession
        self.mailSettingsLiveQuery = MailSettingsLiveQuery(userSession: userSession)
        self.makeSidebarScreen = { selectedItem in
            SidebarScreen(
                state: .initial,
                userSession: userSession,
                upsellButtonVisibilityPublisher: upsellButtonVisibilityPublisher,
                selectedItem: selectedItem
            )
        }
        self._eventLoopErrorCoordinator = .init(
            wrappedValue: EventLoopErrorCoordinator(userSession: userSession, toastStateStore: toastStateStore)
        )
        _upsellCoordinator = .init(wrappedValue: .init(mailUserSession: userSession, configuration: .mail))
        self.userDefaults = appContext.userDefaults
        self.modalFactory = HomeScreenModalFactory(mailUserSession: userSession, accountAuthCoordinator: appContext.accountAuthCoordinator)
        notificationAuthorizationStore = .init(userDefaults: userDefaults)
    }

    var didAppear: ((Self) -> Void)?

    // MARK: - View

    var body: some View {
        ZStack {
            MailboxScreen(
                mailSettingsLiveQuery: mailSettingsLiveQuery,
                appRoute: appRoute,
                notificationAuthorizationStore: notificationAuthorizationStore,
                userSession: userSession,
                userDefaults: userDefaults,
                draftPresenter: composerCoordinator.draftPresenter
            )
            .environmentObject(composerCoordinator)

            makeSidebarScreen() { selectedItem in
                switch selectedItem {
                case .upsell:
                    presentUpsellScreen()
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
        .onAppear { didAppear?(self) }
        .onOpenURL(perform: handleDeepLink)
        .onLoad {
            Task {
                await upsellCoordinator.prewarm()
            }
        }
        .environmentObject(upsellCoordinator)
        .environment(\.isUpsellButtonVisible, upsellButtonVisibilityPublisher.isUpsellButtonVisible)
    }

    private func requestNotificationAuthorizationIfApplicable() {
        Task {
            isNotificationPromptPresented = await notificationAuthorizationStore.shouldRequestAuthorization(
                trigger: .messageSent
            )
        }
    }

    private func userDidRespondToAuthorizationRequest(accepted: Bool) {
        Task {
            await notificationAuthorizationStore.userDidRespondToAuthorizationRequest(accepted: accepted)
            isNotificationPromptPresented = false
        }
    }

    private func presentUpsellScreen() {
        Task {
            do {
                let upsellScreenModel = try await upsellCoordinator.presentUpsellScreen(entryPoint: .sidebar)
                modalState = .upsell(upsellScreenModel)
            } catch {
                toastStateStore.present(toast: .error(message: error.localizedDescription))
            }
        }
    }

    private func presentShareFileController() {
        do {
            let logFolder = FileManager.default.sharedCacheDirectory
            let sourceLogFile = logFolder.appending(path: "proton-mail-ios.log")
            _ = try appContext.mailSession.exportLogs(filePath: sourceLogFile.path).get()
            let activityController = UIActivityViewController(activityItems: [sourceLogFile], applicationActivities: nil)
            UIApplication.shared.keyWindow?.rootViewController?.present(activityController, animated: true)
        } catch {
            toastStateStore.present(toast: .error(message: error.localizedDescription))
        }
    }

    private func handleDeepLink(_ deepLink: URL) {
        if let route = DeepLinkRouteCoder.decode(deepLink: deepLink) {
            modalState = nil
            appUIStateStore.toggleSidebar(isOpen: false)
            appRoute.updateRoute(to: route)
        }
    }
}
