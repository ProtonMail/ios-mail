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
    private let sessionProvider: SessionProvider
    @StateObject var mailSettings: PMMailSettings
    @ObservedObject private var appRoute: AppRouteState
    @ObservedObject private var customLabelModel: CustomLabelModel

    init(
        appRoute: AppRouteState,
        customLabelModel: CustomLabelModel,
        userSession: MailUserSession,
        sessionProvider: SessionProvider = AppContext.shared
    ) {
        self.sessionProvider = sessionProvider
        self._mailSettings = StateObject(wrappedValue: PMMailSettings(userSession: userSession))
        self.appRoute = appRoute
        self.customLabelModel = customLabelModel
    }

    var body: some View {
        ZStack {
            switch appRoute.route {
            case .mailbox:
                MailboxScreen(customLabelModel: customLabelModel, mailSettings: mailSettings)
            case .mailboxOpenMessage(let item):
                MailboxScreen(customLabelModel: customLabelModel, mailSettings: mailSettings, openedItem: item)
            case .settings:
                SettingsScreen()
            case .subscription:
                SidebarWebViewScreen(webViewPage: .subscriptionDetails)
            case .createFolder:
                SidebarWebViewScreen(webViewPage: .createFolder)
            case .createLabel:
                SidebarWebViewScreen(webViewPage: .createLabel)
            }
            SidebarScreen() { selectedItem in
                switch selectedItem {
                case .system(let systemFolder):
                    appRoute.updateRoute(to: .mailbox(selectedMailbox: .label(
                        localLabelId: systemFolder.localID,
                        name: systemFolder.identifier.humanReadable,
                        systemFolder: systemFolder.identifier
                    )))
                case .other(let otherItem):
                    switch otherItem.type {
                    case .settings:
                        appRoute.updateRoute(to: .settings)
                    case .subscriptions:
                        appRoute.updateRoute(to: .subscription)
                    case .createLabel:
                        appRoute.updateRoute(to: .createLabel)
                    case .createFolder:
                        appRoute.updateRoute(to: .createFolder)
                    case .signOut:
                        signOut()
                    case .shareLogs, .bugReport, .contacts:
                        break
                    }
                case .label(let label):
                    appRoute.updateRoute(to: .mailbox(selectedMailbox: .label(
                        localLabelId: label.localID,
                        name: label.name.stringResource,
                        systemFolder: nil
                    )))
                case .folder(let folder):
                    appRoute.updateRoute(to: .mailbox(selectedMailbox: .label(
                        localLabelId: folder.id,
                        name: folder.name.stringResource,
                        systemFolder: nil
                    )))
                }
            }
        }
    }

    private func signOut() {
        Task {
            do {
                try await sessionProvider.logoutActiveUserSession()
            } catch {
                AppLogger.log(error: error, category: .userSessions)
            }
        }
    }

}
