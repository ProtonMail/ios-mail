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
import proton_app_uniffi
import ProtonUIFoundations
import SwiftUI

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
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if !selectionMode.hasItems {
                        HStack(spacing: DS.Spacing.standard) {
                            if case .eligible(let upsellType) = upsellEligibility {
                                toolbarButton(icon: upsellType.icon) {
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
                                .popoverTip(WhatsNewTip())
                                .tipViewStyle(WhatsNewTipStyle())
                        }
                    }
                }
            }
            .toolbarBackground(DS.Color.Background.norm, for: .navigationBar)
            .tint(DS.Color.Text.norm)
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
    case onUpsell(UpsellScreenModel)
}

private extension UpsellType {
    var icon: Image {
        switch self {
        case .standard:
            DS.Icon.icBrandProtonMailUpsellBlackAndWhite.image.renderingMode(.template)
        case .blackFriday(.wave1):
            DS.Icon.upsellBlackFridayHeaderButtonWave1.image
        case .blackFriday(.wave2):
            DS.Icon.upsellBlackFridayHeaderButtonWave2.image
        }
    }
}

#Preview {
    let appUIStateStore = AppUIStateStore()
    let toastStateStore = ToastStateStore(initialState: .initial)
    let userDefaults = UserDefaults(suiteName: "preview").unsafelyUnwrapped

    MailboxScreen(
        mailSettingsLiveQuery: MailSettingsLiveQueryPreviewDummy(),
        appRoute: .initialState,
        notificationAuthorizationStore: .init(userDefaults: userDefaults),
        userSession: .dummy,
        userDefaults: userDefaults,
        draftPresenter: .dummy()
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

import TipKit

struct WhatsNewTip: Tip {
    var title: Text {
        Text("A New Home for Your Accounts")
            .foregroundStyle(DS.Color.Text.norm)
            .fontWeight(.semibold)
            .font(.footnote)
    }

    var message: Text? {
        Text("The account switcher has moved! You can now switch accounts, log out - all from one convenient place.")
            .foregroundStyle(DS.Color.Text.weak)
            .font(.footnote)
    }
}

struct WhatsNewTipStyle: TipViewStyle {

    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(symbol: DS.SFSymbol.sparkles)
                .foregroundStyle(DS.Color.Icon.accent)
                .square(size: 20)
                .padding(6)
                .background(DS.Color.InteractionBrandWeak.norm)
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.large))
                .padding(6)
            VStack(alignment: .leading, spacing: 4) {
                configuration.title
                if let message = configuration.message {
                    message
                }
            }
            Button(action: { configuration.tip.invalidate(reason: .tipClosed) }) {
                ZStack {
                    Color.gray
                        .clipShape(.circle)
                    Image(symbol: DS.SFSymbol.xmark)
                        .foregroundStyle(DS.Color.Shade.shade60)
                }
                .square(size: 24)
            }
        }
        .frame(maxWidth: 320)
        .frame(height: 500)
    }

}

//
//struct WhatsNewTipView: View {
////    @Environment(\.openURL) private var openURL
//
//    // Create an instance of your tip content.
//    private var tip = WhatsNewTip()
//
//    var body: some View {
//        VStack(spacing: 20) {
//            Text("Use action buttons to link to more options. In this example, two actions buttons are provided. One takes the user to the Reset Password feature. The other sends them to an FAQ page.")
//
//            // Place your tip near the feature you want to highlight.
//            TipView(tip, arrowEdge: .bottom) { action in
//                // Define the closure that executes when someone presses the reset button.
//                if action.id == "reset-password", let url = URL(string: "https://iforgot.apple.com") {
//                    openURL(url) { accepted in
//                        print(accepted ? "Success Reset" : "Failure")
//                    }
//                }
//                // Define the closure that executes when someone presses the FAQ button.
//                if action.id == "faq", let url = URL(string: "https://appleid.apple.com/faq") {
//                    openURL(url) { accepted in
//                        print(accepted ? "Success FAQ" : "Failure")
//                    }
//                }
//            }
//            Button("Login") {}
//            Spacer()
//        }
//        .padding()
//        .navigationTitle("Password reset")
//    }
//}
