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
import proton_app_uniffi
import SwiftUI

struct HomeScreen: View {

    enum ModalState: Identifiable {
        case contacts
        case labelOrFolderCreation
        case settings
        case reportProblem
        case subscriptions

        // MARK: - Identifiable

        var id: String {
            .init(describing: self)
        }
    }

    @EnvironmentObject private var appUIStateStore: AppUIStateStore
    @EnvironmentObject private var toastStateStore: ToastStateStore
    @StateObject private var appRoute: AppRouteState
    @StateObject private var composerCoordinator: ComposerCoordinator
    @State private var modalState: ModalState?
    @State private var isNotificationPromptPresented = false
    @StateObject private var eventLoopErrorCoordinator: EventLoopErrorCoordinator
    @ObservedObject private var appContext: AppContext

    private let userSession: MailUserSession
    private let mailSettingsLiveQuery: MailSettingLiveQuerying
    private let makeSidebarScreen: (@escaping (SidebarItem) -> Void) -> SidebarScreen
    private let userDefaults: UserDefaults
    private let modalFactory: HomeScreenModalFactory
    private let notificationAuthorizationStore: NotificationAuthorizationStore

    @State var presentSignOutDialog = false

    init(appContext: AppContext, userSession: MailUserSession, toastStateStore: ToastStateStore) {
        _appRoute = .init(wrappedValue: .initialState)
        _composerCoordinator = .init(wrappedValue: .init(userSession: userSession, toastStateStore: toastStateStore))
        self.appContext = appContext
        self.userSession = userSession
        self.mailSettingsLiveQuery = MailSettingsLiveQuery(userSession: userSession)
        self.makeSidebarScreen = { selectedItem in
            SidebarScreen(
                state: .initial,
                userSession: userSession,
                selectedItem: selectedItem
            )
        }
        self._eventLoopErrorCoordinator = .init(
            wrappedValue: EventLoopErrorCoordinator(userSession: userSession, toastStateStore: toastStateStore)
        )
        self.userDefaults = appContext.userDefaults
        self.modalFactory = HomeScreenModalFactory(mailUserSession: userSession)
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
                case .system(let systemFolder):
                    appRoute.updateRoute(
                        to: .mailbox(
                            selectedMailbox: .systemFolder(
                                labelId: systemFolder.id,
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
                    case .signOut:
                        presentSignOutDialog = true
                    }
                case .label(let label):
                    appRoute.updateRoute(
                        to: .mailbox(
                            selectedMailbox: .customLabel(
                                labelId: label.id,
                                name: label.name.stringResource
                            )))
                case .folder(let folder):
                    appRoute.updateRoute(
                        to: .mailbox(
                            selectedMailbox: .customFolder(
                                labelId: folder.id,
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
        .withPrimaryAccountSignOutDialog(signOutDialogPresented: $presentSignOutDialog, authCoordinator: appContext.accountAuthCoordinator)
        .onAppear { didAppear?(self) }
        .onOpenURL(perform: handleDeepLink)
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

    private func presentShareFileController() {
        let fileManager = FileManager.default
        let logFolder = fileManager.sharedCacheDirectory
        let sourceLogFile = logFolder.appending(path: "proton-mail-uniffi.log")
        let activityController = UIActivityViewController(activityItems: [sourceLogFile], applicationActivities: nil)
        UIApplication.shared.keyWindow?.rootViewController?.present(activityController, animated: true)
    }

    private func handleDeepLink(_ deepLink: URL) {
        if let route = DeepLinkRouteCoder.decode(deepLink: deepLink) {
            modalState = nil
            appUIStateStore.toggleSidebar(isOpen: false)
            appRoute.updateRoute(to: route)
        }
    }
}
