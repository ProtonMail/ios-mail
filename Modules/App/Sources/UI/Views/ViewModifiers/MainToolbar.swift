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

enum ButtonIcon {
    case asset(ImageResource)
    case sfSymbol(SFSymbol)
}

extension Button where Label == SwiftUI.Label<Text, Image> {
    init(_ title: LocalizedStringResource, icon: SFSymbol, action: @escaping () -> Void) {
        self.init(title, systemImage: icon.rawValue, action: action)
    }

    init(_ title: LocalizedStringResource, icon: ButtonIcon, action: @escaping () -> Void) {
        switch icon {
        case .asset(let imageResource):
            self.init(title, image: imageResource, action: action)
        case .sfSymbol(let symbol):
            self.init(title, icon: symbol, action: action)
        }
    }
}

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

    @available(iOS 26, *)
    @ToolbarContentBuilder
    var liquidGlassTopBarTrailingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Search", icon: .magnifier) {
                onEvent(.onSearch)
            }
        }

        ToolbarSpacer(.fixed, placement: .topBarTrailing)
        if case .eligible(let upsellType) = upsellEligibility {
            ToolbarItem(placement: .topBarTrailing) {
                Button("", image: upsellType.icon) {
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
        ToolbarItem(placement: .topBarTrailing) {
            avatarView()  // FIXME: - This has to be fixed in Account repo
                .frame(width: 26, height: 26)
                .clipShape(.circle)
        }
    }

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: .zero) {
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
                ToolbarItem(placement: .principal) {
                    //                    Text(title)
                    //                        .font(.headline)
                    //                        .fontWeight(.semibold)
                    //                        .frame(maxWidth: .infinity, alignment: .leading)
                    SelectionTitleView(title: title)
                    //                        .accessibilityIdentifier(MainToolbarIdentifiers.titleText)
                }
                if !selectionMode.hasItems {
                    if #available(iOS 26, *) {
                        liquidGlassTopBarTrailingToolbar
                    } else {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            if !selectionMode.hasItems {
                                HStack(spacing: DS.Spacing.standard) {
                                    if case .eligible(let upsellType) = upsellEligibility {
                                        toolbarButton(icon: upsellType.icon.image) {
                                            do {
                                                let upsellScreenModel = try await upsellCoordinator.presentUpsellScreen(entryPoint: .mailboxTopBar, upsellType: upsellType)
                                                onEvent(.onUpsell(upsellScreenModel))
                                            } catch {
                                                toastStateStore.present(toast: .error(message: error.localizedDescription))
                                            }
                                        }
                                    }

                                    toolbarButton(icon: .init(symbol: .magnifier)) {
                                        onEvent(.onSearch)
                                    }
                                    avatarView()
                                }
                            }
                        }
                    }
                }
            }
            .modify { view in
                if #unavailable(iOS 26) {
                    view
                        .toolbarBackground(DS.Color.Background.norm, for: .navigationBar)
                        .tint(DS.Color.Text.norm)
                }
            }
            .animation(.default, value: title)
            .animation(.default, value: state)
    }

    private func toolbarButton(icon: Image, action: @escaping () async -> Void) -> some View {
        Button(
            action: {
                Task {
                    await action()
                }
            },
            label: {
                icon
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
            "Menu"
        case .selection:
            "Exit"
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
