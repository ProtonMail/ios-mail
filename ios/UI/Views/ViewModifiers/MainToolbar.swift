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

struct MainToolbar: ViewModifier {
    @EnvironmentObject private var appUIStateStore: AppUIStateStore
    @ObservedObject private var selectionMode: SelectionModeState

    private let title: LocalizedStringResource

    private var state: ToolbarState {
        selectionMode.hasSelectedItems ? .selection : .noSelection
    }

    init(title: LocalizedStringResource, selectionMode: SelectionModeState) {
        self.title = title
        self.selectionMode = selectionMode
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
                    .accessibilityIdentifier(MainToolbarIdentifiers.titleText)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        switch state {
                        case .noSelection:
                            appUIStateStore.sidebarState.isOpen = true
                        case .selection:
                            selectionMode.exitSelectionMode()
                        }
                    }, label: {
                        HStack {
                            Spacer()
                            Image(state.icon)
                                .resizable()
                                .square(size: 24)
                                .id(state.rawValue)
                                .transition(.scale.animation(.easeOut(duration: AppConstants.selectionModeStartDuration)))
                        }
                        .padding(10)
                    })
                    .square(size: 40)
                    .accessibilityIdentifier(MainToolbarIdentifiers.navigationButton(forState: state))
                }
            }
            .toolbarBackground(DS.Color.Background.norm, for: .navigationBar)
            .tint(DS.Color.Text.norm)
    }
}

extension View {
    @MainActor 
    func mainToolbar(title: LocalizedStringResource, selectionMode: SelectionModeState? = nil) -> some View {
        let selectionMode = selectionMode ?? SelectionModeState()
        return self.modifier(
            MainToolbar(title: title, selectionMode: selectionMode)
        )
    }
}

extension MainToolbar {

    enum ToolbarState: Int {
        case noSelection
        case selection

        var icon: ImageResource {
            switch self {
            case .noSelection:
                DS.Icon.icHamburguer
            case .selection:
                DS.Icon.icChevronTinyLeft
            }
        }
    }
}


#Preview {
    let appUIStateStore = AppUIStateStore()
    let toastStateStore = ToastStateStore(initialState: .initial)
    let userSettings = UserSettings(mailboxActions: .init())
    let customLabelModel = CustomLabelModel()

    return MailboxScreen(
        customLabelModel: customLabelModel,
        mailSettingsLiveQuery: MailSettingsLiveQueryPreviewDummy(),
        appRoute: .initialState,
        userDefaults: UserDefaults(suiteName: "preview").unsafelyUnwrapped
    )
        .mainToolbar(title: "Inbox", selectionMode: .init())
        .environmentObject(appUIStateStore)
        .environmentObject(toastStateStore)
        .environmentObject(userSettings)
}

private struct MainToolbarIdentifiers {
    static let titleText = "main.toolbar.titleText"

    static func navigationButton(forState state: MainToolbar.ToolbarState) -> String {
        switch state {
        case .noSelection:
            "main.toolbar.hamburgerButton"
        case .selection:
            "main.toolbar.backButton"
        }
    }
}
