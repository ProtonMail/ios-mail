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

import DesignSystem
import SwiftUI

struct MailboxScreen: View {
    @EnvironmentObject private var appUIState: AppUIState
    @EnvironmentObject private var userSettings: UserSettings

    var body: some View {
        NavigationStack {
            ZStack {
                if userSettings.mailboxViewMode == .conversation {
                    MailboxConversationScreen(model: .init())
                } else {
                    Text("message list mailbox")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(LocalizationTemp.Mailbox.inbox)
            .mailboxToolbar()
        }
    }
}

#Preview {
    let appUIState = AppUIState(isSidebarOpen: true)
    let userSettings = UserSettings(mailboxViewMode: .conversation)
    return MailboxScreen()
        .environmentObject(appUIState)
        .environmentObject(userSettings)
}
