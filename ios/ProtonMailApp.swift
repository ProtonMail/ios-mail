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
import DesignSystem

@main
struct ProtonMail: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    let appState = AppState()
    let appUIState = AppUIState.shared
    let userSettings = UserSettings(mailboxViewMode: .conversation)

    var body: some Scene {
        WindowGroup {
            Root()
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
    @State private var route: Route = .mailbox(label: .defaultMailbox)

    var body: some View {
        if !appState.hasAuthenticatedSession {
            SignIn()
        } else {
            ZStack {
                switch route {
                case .mailbox:
                    MailboxScreen()
                case .settings:
                    SettingsScreen()
                }
                SidebarScreen()
            }
            .environment(\.navigate) { destinaton in
                route = destinaton
                switch route {
                case .mailbox(let label):
                    appUIState.selectedMailbox = label
                case .settings:
                    break
                }
                appUIState.isSidebarOpen = false
            }
        }
    }
}

enum SystemFolderIdentifier: UInt64 {
    case inbox = 0
    case spam = 4
//    case allMail = 5
//    case archive = 6
    case sent = 7
//    case draft = 8
    case starred = 10
}

extension SystemFolderIdentifier {

    var localisedName: String {
        switch self {
        case .inbox:
            LocalizationTemp.Mailbox.inbox
        case .sent:
            LocalizationTemp.Mailbox.sent
        case .spam:
            LocalizationTemp.Mailbox.spam
        case .starred:
            LocalizationTemp.Mailbox.starred
        }
    }

    var icon: UIImage {
        switch self {
        case .inbox:
            DS.Icon.icInbox
        case .sent:
            DS.Icon.icPaperPlane
        case .spam:
            DS.Icon.icFire
        case .starred:
            DS.Icon.icStar
        }
    }
}

enum Route: Hashable {
    case mailbox(label: SelectedMailbox)
    case settings
}

struct NavigateEnvironmentKey: EnvironmentKey {
    static var defaultValue: (Route) -> Void = { _ in }
}

extension EnvironmentValues {
    var navigate: (Route) -> Void {
        get { self[NavigateEnvironmentKey.self] }
        set { self[NavigateEnvironmentKey.self] = newValue }
    }
}
