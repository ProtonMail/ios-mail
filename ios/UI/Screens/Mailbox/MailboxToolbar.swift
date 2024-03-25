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

struct MailboxToolbar: ViewModifier {
    @EnvironmentObject private var appUIState: AppUIState

    private(set) var sessionProvider: SessionProvider

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        appUIState.isSidebarOpen = true
                    }, label: {
                        Image(uiImage: DS.Icon.icHamburguer)
                    })
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            do {
                                try await sessionProvider.logoutActiveUserSession()
                            } catch {
                                AppLogger.log(error: error, category: .userSessions)
                            }
                        }
                    }, label: {
                        Text("sign out")
                            .font(.footnote)
                    })
                }
            }
    }
}

extension View {
    @MainActor func mailboxToolbar() -> some View {
        self.modifier(MailboxToolbar(sessionProvider: AppContext.shared))
    }
}
