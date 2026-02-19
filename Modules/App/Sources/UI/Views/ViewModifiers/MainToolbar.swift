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
import InboxIAP
import ProtonUIFoundations
import SwiftUI
import proton_app_uniffi

struct MainToolbar<AvatarView: View>: ViewModifier {
    @EnvironmentObject private var toastStateStore: ToastStateStore
    @EnvironmentObject private var upsellCoordinator: UpsellCoordinator
    @Environment(\.upsellEligibility) private var upsellEligibility
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
            .toolbarRole(selectionMode.hasItems ? .navigationStack : .browser)
            .toolbar {
                if #available(iOS 26, *) {
                    ios26ToolbarContent
                } else {
                    legacyToolbarContent
                }
            }
            .modify { view in
                if #available(iOS 26, *) {
                    view
                        .animation(.default, value: title)
                        .animation(.default, value: state)
                } else {
                    view
                        .toolbarBackground(DS.Color.Background.norm, for: .navigationBar)
                        .tint(DS.Color.Text.norm)
                }
            }
    }

    @ToolbarContentBuilder
    @available(iOS 26, *)
    private var ios26ToolbarContent: some ToolbarContent {
        leadingToolbarItem

        ToolbarItem(placement: .title) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        if !selectionMode.hasItems {
            ToolbarItem(placement: .topBarTrailing) {
                searchButton
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
            if case .eligible(let upsellType) = upsellEligibility {
                ToolbarItem(placement: .topBarTrailing) {
                    upsellButton(for: upsellType)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                avatarView()
                    .frame(width: 26, height: 26)
                    .clipShape(.circle)
            }
        }
    }

    @ToolbarContentBuilder
    private var legacyToolbarContent: some ToolbarContent {
        leadingToolbarItem

        ToolbarItem(placement: .principal) {
            SelectionTitleView(title: title)
        }

        if !selectionMode.hasItems {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !selectionMode.hasItems {
                    HStack(spacing: DS.Spacing.standard) {
                        if case .eligible(let upsellType) = upsellEligibility {
                            upsellButton(for: upsellType)
                        }
                        searchButton
                        avatarView()
                    }
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var leadingToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(state.name, icon: state.image) {
                switch state {
                case .noSelection:
                    onEvent(.onOpenMenu)
                case .selection:
                    onEvent(.onExitSelectionMode)
                }
            }
        }
    }

    private var searchButton: some View {
        Button(L10n.Search.searchPlaceholder, icon: .magnifier) {
            onEvent(.onSearch)
        }
    }

    private func upsellButton(for upsellType: UpsellType) -> some View {
        Button(L10n.MainToolbar.upgrade, image: upsellType.icon) {
            Task {
                do {
                    let upsellScreenModel = try await upsellCoordinator.presentUpsellScreen(entryPoint: .mailboxTopBar, upsellType: upsellType)
                    onEvent(.onUpsell(upsellScreenModel))
                } catch {
                    toastStateStore.present(toast: .error(message: error.localizedDescription))
                }
            }
        }
    }
}

extension View {
    @MainActor
    func mainToolbar(
        title: LocalizedStringResource,
        selectionMode: SelectionModeState? = nil,
        onEvent: @escaping (MainToolbarEvent) -> Void,
        @ViewBuilder avatarView: @escaping () -> some View
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

    var image: ButtonIcon {
        switch self {
        case .noSelection:
            .asset(DS.Icon.icMenu)
        case .selection:
            .sfSymbol(.xmark)
        }
    }

    var name: LocalizedStringResource {
        switch self {
        case .noSelection:
            L10n.MainToolbar.menu
        case .selection:
            L10n.MainToolbar.cancelSelection
        }
    }
}

enum MainToolbarEvent {
    case onOpenMenu
    case onExitSelectionMode
    case onSearch
    case onUpsell(UpsellScreenModel)
}

private extension UpsellType {
    var icon: ImageResource {
        switch self {
        case .standard:
            DS.Icon.icBrandProtonMailUpsellBlackAndWhite
        case .blackFriday(.wave1):
            DS.Icon.upsellBlackFridayHeaderButtonWave1
        case .blackFriday(.wave2):
            DS.Icon.upsellBlackFridayHeaderButtonWave2
        }
    }
}
