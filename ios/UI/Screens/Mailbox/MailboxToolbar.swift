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
    @ObservedObject private var selectionMode: SelectionModeState

    private let title: String
    private var sessionProvider: SessionProvider

    private var state: ToolbarState {
        selectionMode.hasSelectedItems ? .selection : .noSelection
    }

    init(title: String, selectionMode: SelectionModeState, sessionProvider: SessionProvider) {
        self.title = title
        self.selectionMode = selectionMode
        self.sessionProvider = sessionProvider
    }

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(alignment: .leading) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, DS.Spacing.medium)
                    .accessibilityIdentifier(MailboxToolbarIdentifiers.titleText)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        switch state {
                        case .noSelection:
                            appUIState.isSidebarOpen = true
                        case .selection:
                            selectionMode.exitSelectionMode()
                        }
                    }, label: {
                        HStack {
                            Spacer()
                            Image(uiImage: state.icon)
                                .id(state.rawValue)
                                .transition(.scale.animation(.easeOut(duration: AppConstants.selectionModeStartDuration)))
                        }
                        .padding(10)
                    })
                    .frame(width: 40, height: 40)
                    .overlay {
                        Circle()
                            .stroke(DS.Color.Border.norm)
                    }
                    .accessibilityIdentifier(MailboxToolbarIdentifiers.navigationButton(forState: state))
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
                            .opacity(selectionMode.hasSelectedItems ? 0 : 1)
                            .animation(
                                .easeInOut(duration: AppConstants.selectionModeStartDuration),
                                value: selectionMode.hasSelectedItems
                            )
                    })
                }
            }
            .tint(DS.Color.Text.norm)
    }
}

extension View {
    @MainActor func mailboxToolbar(title: String, selectionMode: SelectionModeState) -> some View {
        self.modifier(MailboxToolbar(title: title, selectionMode: selectionMode, sessionProvider: AppContext.shared))
    }
}

extension MailboxToolbar {

    enum ToolbarState: Int {
        case noSelection
        case selection

        var icon: UIImage {
            switch self {
            case .noSelection:
                return DS.Icon.icHamburguer
            case .selection:
                return DS.Icon.icChevronLeft
            }
        }
    }
}


#Preview {
    let appUIState = AppUIState(isSidebarOpen: false)
    let userSettings = UserSettings(mailboxViewMode: .conversation, mailboxActions: .init())

    let customLabelModel = CustomLabelModel()

    return MailboxScreen(customLabelModel: customLabelModel)
        .mailboxToolbar(title: "Inbox", selectionMode: .init())
        .environmentObject(appUIState)
        .environmentObject(userSettings)
}

private struct MailboxToolbarIdentifiers {
    static let titleText = "mailbox.toolbar.titleText"
    
    static func navigationButton(forState state: MailboxToolbar.ToolbarState) -> String {
        switch state {
        case .noSelection:
            "mailbox.toolbar.hamburgerButton"
        case .selection:
            "mailbox.toolbar.backButton"
        }
    }
}
