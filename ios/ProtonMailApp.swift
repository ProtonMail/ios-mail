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

enum MailboxViewMode {
    case message
    case conversation
}

final class UserSettings: ObservableObject {
    var mailboxViewMode: MailboxViewMode

    init(mailboxViewMode: MailboxViewMode) {
        self.mailboxViewMode = mailboxViewMode
    }
}

final class AppUIState: ObservableObject {
    @Published var isSidebarOpen: Bool

    init(isSidebarOpen: Bool) {
        self.isSidebarOpen = isSidebarOpen
    }
}


@main
struct ProtonMail: App {
    @State private var route: Route = .mailbox(labelId: "inbox")

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch route {
                case .mailbox:
                    MailboxScreen()
                case .settings:
                    SettingsScreen()
                }
                SidebarScreen(screenModel: PreviewData.sideBarScreenModel)
            }
            .environment(\.navigate) { destinaton in
                route = destinaton
            }
            .environmentObject(AppUIState(isSidebarOpen: false))
            .environmentObject(UserSettings(mailboxViewMode: .conversation))
        }
    }
}

enum Route: Hashable {
    case mailbox(labelId: String)
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
