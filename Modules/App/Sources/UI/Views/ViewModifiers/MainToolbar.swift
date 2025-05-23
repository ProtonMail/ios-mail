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

import InboxCoreUI
import InboxDesignSystem
import SwiftUI

struct MainToolbar: ViewModifier {
    @ObservedObject private var selectionMode: SelectionModeState
    let onEvent: (MainToolbarEvent) -> Void

    private let title: LocalizedStringResource

    private var state: ToolbarState {
        selectionMode.hasItems ? .selection : .noSelection
    }

    init(title: LocalizedStringResource, selectionMode: SelectionModeState, onEvent: @escaping (MainToolbarEvent) -> Void) {
        self.title = title
        self.selectionMode = selectionMode
        self.onEvent = onEvent
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
                                    Image(state.icon)
                                        .resizable()
                                        .square(size: 24)
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
                    Button(
                        action: {
                            onEvent(.onSearch)
                        },
                        label: {
                            HStack {
                                Spacer()
                                Image(DS.Icon.icMagnifier)
                                    .resizable()
                                    .square(size: 24)
                            }
                            .padding(10)
                        }
                    )
                    .opacity(selectionMode.hasItems ? 0 : 1)
                    .square(size: 40)
                }
            }
            .toolbarBackground(DS.Color.Background.norm, for: .navigationBar)
            .tint(DS.Color.Text.norm)
    }
}

extension View {
    @MainActor
    func mainToolbar(
        title: LocalizedStringResource,
        selectionMode: SelectionModeState? = nil,
        onEvent: @escaping (MainToolbarEvent) -> Void
    ) -> some View {
        let selectionMode = selectionMode ?? SelectionModeState()
        return self.modifier(
            MainToolbar(title: title, selectionMode: selectionMode, onEvent: onEvent)
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
    .mainToolbar(title: "Inbox", selectionMode: .init(), onEvent: { _ in })
    .environmentObject(appUIStateStore)
    .environmentObject(toastStateStore)
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
