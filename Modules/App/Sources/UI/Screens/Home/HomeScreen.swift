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

import proton_app_uniffi
import SwiftUI

struct HomeScreen: View {
    enum ModalState: String, Identifiable {
        case contacts
        case labelOrFolderCreationScreen
        case settingsScreen

        // MARK: - Identifiable

        var id: String {
            rawValue
        }
    }

    @EnvironmentObject private var appUIStateStore: AppUIStateStore
    @EnvironmentObject private var toastStateStore: ToastStateStore
    @StateObject private var appRoute: AppRouteState
    @State private var modalState: ModalState?
    @ObservedObject private var customLabelModel: CustomLabelModel
    private let mailSettingsLiveQuery: MailSettingLiveQuerying
    private let makeSidebarScreen: (@escaping (SidebarItem) -> Void) -> SidebarScreen
    private let userDefaultsCleaner: UserDefaultsCleaner
    private let userDefaults: UserDefaults

    init(customLabelModel: CustomLabelModel, userSession: MailUserSession, userDefaults: UserDefaults) {
        _appRoute = .init(wrappedValue: .initialState)
        self.customLabelModel = customLabelModel
        self.mailSettingsLiveQuery = MailSettingsLiveQuery(userSession: userSession)
        self.makeSidebarScreen = { selectedItem in
            SidebarScreen(
                state: .initial,
                sidebar: Sidebar(ctx: userSession),
                selectedItem: selectedItem
            )
        }
        self.userDefaultsCleaner = .init(userDefaults: userDefaults)
        self.userDefaults = userDefaults
    }

    var didAppear: ((Self) -> Void)?

    // MARK: - View

    var body: some View {
        ZStack {
            switch appRoute.route {
            case .mailbox:
                MailboxScreen(
                    customLabelModel: customLabelModel,
                    mailSettingsLiveQuery: mailSettingsLiveQuery,
                    appRoute: appRoute,
                    userDefaults: userDefaults
                )
            case .mailboxOpenMessage(let item):
                MailboxScreen(
                    customLabelModel: customLabelModel,
                    mailSettingsLiveQuery: mailSettingsLiveQuery,
                    appRoute: appRoute,
                    userDefaults: userDefaults,
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
                        modalState = .labelOrFolderCreationScreen
                    case .settings:
                        modalState = .settingsScreen
                    case .shareLogs:
                        presentShareFileController()
                    case .subscriptions:
                        toastStateStore.present(toast: .comingSoon)
                    case .signOut:
                        signOut()
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
        .sheet(item: $modalState, content: HomeScreenModalFactory.makeModal)
        .onAppear { didAppear?(self) }
    }

    private func signOut() {
        userDefaultsCleaner.cleanUp()
        Task {
            do {
                try await AppContext.shared.logoutActiveUserSession()
            } catch {
                AppLogger.log(error: error, category: .userSessions)
            }
        }
    }

    private func presentShareFileController() {
        let fileManager = FileManager.default
        guard let logFolder = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        let sourceLogFile = logFolder.appending(path: "proton-mail-uniffi.log")
        let activityController = UIActivityViewController(activityItems: [sourceLogFile], applicationActivities: nil)
        UIApplication.shared.keyWindow?.rootViewController?.present(activityController, animated: true)
    }
}
