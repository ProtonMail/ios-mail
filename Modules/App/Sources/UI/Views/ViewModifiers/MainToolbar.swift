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

import AccountManager
import InboxCoreUI
import InboxDesignSystem
import SwiftUI

struct MainToolbar<AvatarView: View>: ViewModifier {
    @ObservedObject private var selectionMode: SelectionModeState
    let onEvent: (MainToolbarEvent) -> Void
    let avatarView: () -> AvatarView

    private let title: LocalizedStringResource

    private var state: MainToolbarState {
        selectionMode.hasItems ? .selection : .noSelection
    }

    init(
        title: LocalizedStringResource,
        selectionMode: SelectionModeState,
        onEvent: @escaping (MainToolbarEvent) -> Void,
        avatarView: @escaping () -> AvatarView
    ) {
        self.title = title
        self.selectionMode = selectionMode
        self.onEvent = onEvent
        self.avatarView = avatarView
    }

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: .zero) {
                        Button(
                            action: {
                                switch state {
                                case .noSelection:
                                    onEvent(.onOpenMenu)
                                case .selection:
                                    onEvent(.onExitSelectionMode)
                                }
                            },
                            label: {
                                HStack {
                                    Spacer()
                                    state.image
                                        .square(size: 40)
                                        .id(state.rawValue)
                                        .transition(.scale.animation(.easeOut(duration: Animation.selectionModeStartDuration)))
                                }
                                .padding(10)
                            }
                        )
                        .square(size: 40)
                        .accessibilityIdentifier(MainToolbarIdentifiers.navigationButton(forState: state))
                    }
                }
                ToolbarItem(placement: .principal) {
                    SelectionTitleView(title: title)
                        .accessibilityIdentifier(MainToolbarIdentifiers.titleText)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !selectionMode.hasItems {
                        HStack(spacing: DS.Spacing.standard) {
                            searchButton()
                            avatarView()
                        }
                    }
                }
            }
            .toolbarBackground(DS.Color.Background.norm, for: .navigationBar)
            .tint(DS.Color.Text.norm)
    }

    private func searchButton() -> some View {
        Button(
            action: { onEvent(.onSearch) },
            label: {
                Image(symbol: .magnifier)
                    .square(size: 24)
                    .padding(10)
            }
        )
        .square(size: 40)
    }
}

extension View {
    @MainActor
    func mainToolbar(
        title: LocalizedStringResource,
        selectionMode: SelectionModeState? = nil,
        onEvent: @escaping (MainToolbarEvent) -> Void,
        avatarView: @escaping () -> some View
    ) -> some View {
        let selectionMode = selectionMode ?? SelectionModeState()
        return modifier(
            MainToolbar(title: title, selectionMode: selectionMode, onEvent: onEvent, avatarView: avatarView)
        )
    }
}

enum MainToolbarState: Int {
    case noSelection
    case selection

    var image: Image {
        switch self {
        case .noSelection:
            Image(DS.Icon.icHamburguer)
        case .selection:
            Image(symbol: .xmark)
        }
    }
}

enum MainToolbarEvent {
    case onOpenMenu
    case onExitSelectionMode
    case onSearch
}

#Preview {
    let appUIStateStore = AppUIStateStore()
    let toastStateStore = ToastStateStore(initialState: .initial)
    let userDefaults = UserDefaults(suiteName: "preview").unsafelyUnwrapped

    MailboxScreen(
        mailSettingsLiveQuery: MailSettingsLiveQueryPreviewDummy(),
        appRoute: .initialState,
        notificationAuthorizationStore: .init(userDefaults: userDefaults),
        userSession: .init(noPointer: .init()),
        userDefaults: userDefaults,
        draftPresenter: .dummy(),
        sendResultPresenter: .init(draftPresenter: .dummy())
    )
    .mainToolbar(
        title: "Inbox",
        selectionMode: .init(),
        onEvent: { _ in },
        avatarView: { EmptyView() }
    )
    .environmentObject(appUIStateStore)
    .environmentObject(toastStateStore)
}

private struct MainToolbarIdentifiers {
    static let titleText = "main.toolbar.titleText"

    static func navigationButton(forState state: MainToolbarState) -> String {
        switch state {
        case .noSelection:
            "main.toolbar.hamburgerButton"
        case .selection:
            "main.toolbar.backButton"
        }
    }
}
