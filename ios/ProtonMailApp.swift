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

import SwiftUI

@main
struct ProtonMail: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    private var mailboxModel = MailboxModel()

    let appState = AppState()
    let appUIState = AppUIState()
    let userSettings = UserSettings(mailboxViewMode: .conversation)

    var body: some Scene {
        WindowGroup {
            Root(mailboxModel: mailboxModel)
                .environmentObject(appState)
                .environmentObject(appUIState)
                .environmentObject(userSettings)
        }
        .onChange(of: scenePhase, { oldValue, newValue in
            // scenePhase contains an aggregate phase for all scenes
            if newValue == .active {
                AppLifeCycle.shared.allScenesDidBecomeActive()
            } else if newValue == .background {
                AppLifeCycle.shared.allScenesDidEnterBackground()
            }
        })
    }
}

struct Root: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var appUIState: AppUIState

    // The route determines the view that will be rendered
    @State private var route: Route = .mailbox(label: .defaultMailbox)
    
    // The mailbox model is the source of truth for the mailbox
    @State private var mailboxModel: MailboxModel

    init(mailboxModel: MailboxModel) {
        self.mailboxModel = mailboxModel
    }

    var body: some View {
        if !appState.hasAuthenticatedSession {
            SignIn()
        } else {
            ZStack {
                switch route {
                case .mailbox:
                    MailboxScreen(mailboxModel: mailboxModel)
                case .settings:
                    SettingsScreen()
                }
                SidebarScreen(selectedRoute: $route)
            }
            .onChange(of: route) { oldValue, newValue in
                if let selectedMailbox = newValue.selectedMailbox {
                    Task {
                        await mailboxModel.updateSelectedMailbox(selectedMailbox)
                    }
                }
            }
        }
    }
}
