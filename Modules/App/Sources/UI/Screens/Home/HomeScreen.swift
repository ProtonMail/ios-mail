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
import InboxComposer
import InboxCoreUI
import proton_app_uniffi
import SwiftUI

struct HomeScreen: View {
    enum ModalState: Identifiable {
        case contacts
        case labelOrFolderCreation
        case settings
        case draft(DraftToPresent)

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
    @ObservedObject private var appContext: AppContext

    private let userSession: MailUserSession
    private let mailSettingsLiveQuery: MailSettingLiveQuerying
    private let makeSidebarScreen: (@escaping (SidebarItem) -> Void) -> SidebarScreen
    private let userDefaults: UserDefaults
    private let modalFactory: HomeScreenModalFactory

    @State var presentSignOutDialog = false

    init(appContext: AppContext, userSession: MailUserSession) {
        _appRoute = .init(wrappedValue: .initialState)
        self.appContext = appContext
        self.userSession = userSession
        self.mailSettingsLiveQuery = MailSettingsLiveQuery(userSession: userSession)
        self.makeSidebarScreen = { selectedItem in
            SidebarScreen(
                state: .initial,
                sidebar: Sidebar(ctx: userSession),
                selectedItem: selectedItem
            )
        }
        self._draftPresenter = .init(
            initialValue: DraftPresenter(userSession: userSession, draftProvider: .productionInstance)
        )
        self.userDefaults = appContext.userDefaults
        self.modalFactory = .init(mailUserSession: userSession)
    }

    var didAppear: ((Self) -> Void)?

    // MARK: - View

    var body: some View {
        ZStack {
            switch appRoute.route {
            case .mailbox:
                MailboxScreen(
                    mailSettingsLiveQuery: mailSettingsLiveQuery,
                    appRoute: appRoute,
                    userSession: userSession,
                    userDefaults: userDefaults,
                    draftPresenter: draftPresenter
                )
            case .mailboxOpenMessage(let item):
                MailboxScreen(
                    mailSettingsLiveQuery: mailSettingsLiveQuery,
                    appRoute: appRoute,
                    userSession: userSession,
                    userDefaults: userDefaults,
                    draftPresenter: draftPresenter,
                    openedItem: item
                )
            }
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
        .onReceive(draftPresenter.draftToPresent) { modalState = .draft($0) }
        .sheet(item: $modalState, content: modalFactory.makeModal(for:))
        .withPrimaryAccountSignOutDialog(signOutDialogPresented: $presentSignOutDialog, authCoordinator: appContext.accountAuthCoordinator)
        .onAppear { didAppear?(self) }
    }

    private func presentShareFileController() {
        let fileManager = FileManager.default
        guard let logFolder = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        let sourceLogFile = logFolder.appending(path: "proton-mail-uniffi.log")
        let activityController = UIActivityViewController(activityItems: [sourceLogFile], applicationActivities: nil)
        UIApplication.shared.keyWindow?.rootViewController?.present(activityController, animated: true)
    }
}
