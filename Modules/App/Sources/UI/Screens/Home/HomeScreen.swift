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
import InboxCoreUI
import proton_app_uniffi
import SwiftUI

struct HomeScreen: View {

    enum ModalState: Identifiable {
        case contacts
        case labelOrFolderCreation
        case settings
        case draft(ComposerModalParams)

        // MARK: - Identifiable

        var id: String {
            switch self {
            case .contacts: "contacts"
            case .labelOrFolderCreation: "labelOrFolderCreation"
            case .settings: "settings"
            case .draft: "draft"
            }
        }
    }

    @EnvironmentObject private var appUIStateStore: AppUIStateStore
    @EnvironmentObject private var toastStateStore: ToastStateStore
    @StateObject private var appRoute: AppRouteState
    @State private var modalState: ModalState?
    @State private var draftPresenter: DraftPresenter
    @StateObject private var sendResultCoordinator: SendResultCoordinator
    @StateObject private var eventLoopErrorCoordinator: EventLoopErrorCoordinator
    @ObservedObject private var appContext: AppContext

    private let userSession: MailUserSession
    private let mailSettingsLiveQuery: MailSettingLiveQuerying
    private let makeSidebarScreen: (@escaping (SidebarItem) -> Void) -> SidebarScreen
    private let userDefaults: UserDefaults
    private let modalFactory: HomeScreenModalFactory

    @State var presentSignOutDialog = false

    init(appContext: AppContext, userSession: MailUserSession, toastStateStore: ToastStateStore) {
        _appRoute = .init(wrappedValue: .initialState)
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
        let draftPresenter = DraftPresenter(userSession: userSession, draftProvider: .productionInstance)
        self._draftPresenter = .init(initialValue: draftPresenter)
        self._sendResultCoordinator = .init(
            wrappedValue: SendResultCoordinator(userSession: userSession, draftPresenter: draftPresenter)
        )
        self._eventLoopErrorCoordinator = .init(
            wrappedValue: EventLoopErrorCoordinator(userSession: userSession, toastStateStore: toastStateStore)
        )
        self.userDefaults = appContext.userDefaults
        self.modalFactory = HomeScreenModalFactory(mailUserSession: userSession, toastStateStore: toastStateStore)
    }

    var didAppear: ((Self) -> Void)?

    // MARK: - View

    var body: some View {
        ZStack {
            MailboxScreen(
                mailSettingsLiveQuery: mailSettingsLiveQuery,
                appRoute: appRoute,
                userSession: userSession,
                userDefaults: userDefaults,
                draftPresenter: draftPresenter,
                sendResultPresenter: sendResultCoordinator.presenter
            )
            makeSidebarScreen() { selectedItem in
                switch selectedItem {
                case .system(let systemFolder):
                    appRoute.updateRoute(to: .mailbox(selectedMailbox: .systemFolder(
                        labelId: systemFolder.id,
                        systemFolder: systemFolder.type
                    )))
                case .other(let otherItem):
                    switch otherItem.type {
                    case .bugReport:
                        toastStateStore.present(toast: .comingSoon)
                    case .contacts:
                        modalState = .contacts
                    case .createFolder, .createLabel:
                        modalState = .labelOrFolderCreation
                    case .settings:
                        modalState = .settings
                    case .shareLogs:
                        presentShareFileController()
                    case .subscriptions:
                        toastStateStore.present(toast: .comingSoon)
                    case .signOut:
                        presentSignOutDialog = true
                    }
                case .label(let label):
                    appRoute.updateRoute(to: .mailbox(selectedMailbox: .customLabel(
                        labelId: label.id,
                        name: label.name.stringResource
                    )))
                case .folder(let folder):
                    appRoute.updateRoute(to: .mailbox(selectedMailbox: .customFolder(
                        labelId: folder.id,
                        name: folder.name.stringResource
                    )))
                }
            }
            .zIndex(appUIStateStore.sidebarState.zIndex)
        }
        .onReceive(draftPresenter.draftToPresent) { modalState = modalStateFor(draftToPresent: $0) }
        .onReceive(sendResultCoordinator.presenter.toastAction, perform: handleSendResultToastAction)
        .sheet(item: $modalState, content: modalFactory.makeModal(for:))
        .withPrimaryAccountSignOutDialog(signOutDialogPresented: $presentSignOutDialog, authCoordinator: appContext.accountAuthCoordinator)
        .onAppear { didAppear?(self) }
        .onOpenURL(perform: handleDeepLink)
    }

    private func modalStateFor(draftToPresent: DraftToPresent) -> ModalState {
        .draft(
            ComposerModalParams(
                draftToPresent: draftToPresent,
                onSendingEvent: { draftId in
                    sendResultCoordinator.presenter.presentResultInfo(.init(messageId: draftId, type: .sending))
                }
            )
        )
    }

    private func handleSendResultToastAction(_ action: SendResultToastAction) {
        switch action {
        case .present(let toast): toastStateStore.present(toast: toast)
        case .dismiss(let toast): toastStateStore.dismiss(toast: toast)
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
            appRoute.updateRoute(to: route)
        }
    }
}
