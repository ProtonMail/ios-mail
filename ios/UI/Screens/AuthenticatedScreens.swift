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

import proton_mail_uniffi
import SwiftUI

struct AuthenticatedScreens: View {
    @EnvironmentObject private var appUIStateStore: AppUIStateStore
    @EnvironmentObject private var toastStateStore: ToastStateStore
    @ObservedObject private var appRoute: AppRouteState
    @ObservedObject private var customLabelModel: CustomLabelModel
    private let mailSettingsLiveQuery: MailSettingLiveQuerying
    private let makeSidebarScreen: (@escaping (SidebarItem) -> Void) -> SidebarScreen

    @State var webViewSheet: ProtonAuthenticatedWebPage?

    init(
        appRoute: AppRouteState,
        customLabelModel: CustomLabelModel,
        userSession: MailUserSession
    ) {
        self.appRoute = appRoute
        self.customLabelModel = customLabelModel
        self.mailSettingsLiveQuery = MailSettingsLiveQuery(userSession: userSession)
        self.makeSidebarScreen = { selectedItem in
            SidebarScreen(
                state: .initial,
                sidebar: Sidebar(ctx: userSession),
                selectedItem: selectedItem
            )
        }
    }

    var body: some View {
        ZStack {
            switch appRoute.route {
            case .mailbox:
                MailboxScreen(
                    customLabelModel: customLabelModel,
                    mailSettingsLiveQuery: mailSettingsLiveQuery
                )
            case .mailboxOpenMessage(let item):
                MailboxScreen(
                    customLabelModel: customLabelModel,
                    mailSettingsLiveQuery: mailSettingsLiveQuery,
                    openedItem: item
                )
            case .settings:
                SettingsScreen()
            }
            makeSidebarScreen() { selectedItem in
                switch selectedItem {
                case .system(let systemFolder):
                    appRoute.updateRoute(to: .mailbox(selectedMailbox: .label(
                        labelId: systemFolder.id,
                        name: systemFolder.type.humanReadable,
                        systemFolder: systemFolder.type
                    )))
                case .other(let otherItem):
                    switch otherItem.type {
                    case .settings:
                        appRoute.updateRoute(to: .settings)
                    case .subscriptions:
                        webViewSheet = .subscriptionDetails
                    case .createLabel:
                        webViewSheet = .createLabel
                    case .createFolder:
                        webViewSheet = .createFolder
                    case .signOut:
                        signOut()
                    case .shareLogs:
                        presentShareFileController()
                    case .bugReport, .contacts:
                        toastStateStore.present(toast: .comingSoon)
                    }
                case .label(let label):
                    appRoute.updateRoute(to: .mailbox(selectedMailbox: .label(
                        labelId: label.id,
                        name: label.name.stringResource,
                        systemFolder: nil
                    )))
                case .folder(let folder):
                    appRoute.updateRoute(to: .mailbox(selectedMailbox: .label(
                        labelId: folder.id,
                        name: folder.name.stringResource,
                        systemFolder: nil
                    )))
                }
            }
            .zIndex(appUIStateStore.sidebarState.zIndex)
        }
        .sheet(item: $webViewSheet) { webViewSheet in
            SidebarWebViewScreen(webViewPage: webViewSheet)
        }
    }

    private func signOut() {
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
