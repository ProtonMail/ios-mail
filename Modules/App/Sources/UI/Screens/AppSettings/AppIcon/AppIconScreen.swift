// Copyright (c) 2025 Proton Technologies AG
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

import InboxCore
import InboxCoreUI
import InboxDesignSystem
import ProtonUIFoundations
import SwiftUI

struct AppIconState: Copying {
    var appIcon: AppIcon
    var isDiscretAppIconOn: Bool
}

extension AppIconState {
    static func initial(appIcon: AppIcon) -> Self {
        .init(appIcon: appIcon, isDiscretAppIconOn: true)
    }
}

enum AppIconScreenAction {
    case iconTapped(icon: AppIcon)
    case discreetAppIconSwitched(isEnbaled: Bool)
}

class AppIconStateStore: StateStore {
    @Published var state: AppIconState
    private let appIconConfigurator: AppIconConfigurable

    init(state: AppIconState, appIconConfigurator: AppIconConfigurable) {
        self.state = state
        self.appIconConfigurator = appIconConfigurator
    }

    func handle(action: AppIconScreenAction) async {
        switch action {
        case .iconTapped(let icon):
            guard icon != state.appIcon else { return }
            await changeIcon(to: icon)
        case .discreetAppIconSwitched(let isEnabled):
            let icon = (isEnabled ? AppIcon.allCases.first : nil) ?? .default
            await changeIcon(to: icon)
        }
    }

    private func changeIcon(to appIcon: AppIcon) async {
        state = state.copy(\.appIcon, to: appIcon)
        try? await appIconConfigurator.setAlternateIconName(appIcon.alternateIconName)
    }
}

struct AppIconScreen: View {
    @StateObject var store: AppIconStateStore

    init(appIconConfigurator: AppIconConfigurable = UIApplication.shared) {
        _store = .init(
            wrappedValue: .init(
                state: .initial(appIcon: appIconConfigurator.currentIcon),
                appIconConfigurator: appIconConfigurator
            ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.extraLarge) {
                FormSection {
                    VStack(spacing: DS.Spacing.standard) {
                        Image(store.state.appIcon.preview)
                            .resizable()
                            .square(size: 60)
                            .clippedRoundedBorder(cornerRadius: DS.Radius.extraLarge, lineColor: DS.Color.Border.norm)
                        Text("App icon")
                            .font(.title3.bold())
                            .foregroundStyle(DS.Color.Text.norm)
                        Text(
                            "Keep the default Proton Mail icon, or disguise it with a more discreet one for extra privacy. Notifications will always show the Proton Mail name and icon. [Learn more...](https://www.example.com)"
                        )
                        .font(.footnote)
                        .tint(DS.Color.Text.accent)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.Spacing.large)
                    }
                    .padding(.vertical, DS.Spacing.extraLarge)
                    .padding(.horizontal, DS.Spacing.large)

                    DS.Color.Border.norm
                        .frame(height: 1)
                        .padding(.leading, DS.Spacing.large)

                    FormSwitchView(title: "Discreet app icon", isOn: $store.state.isDiscretAppIconOn)
                        .padding(.bottom, DS.Spacing.compact)
                }
                .frame(maxWidth: .infinity)
                .background(DS.Color.Background.norm)
                .roundedRectangleStyle()

                if store.state.isDiscretAppIconOn {
                    FormSection {
                        LazyVGrid(columns: Array(repeating: .init(), count: 4)) {
                            ForEach(icons, id: \.self) { icon in
                                Button(action: { store.handle(action: .iconTapped(icon: icon)) }) {
                                    let viewModel = store.state.viewModel(for: icon)
                                    Image(icon.preview)
                                        .resizable()
                                        .square(size: 60)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: DS.Radius.extraLarge)
                                                .stroke(DS.Color.Background.norm, lineWidth: viewModel.overlayLineWidth)
                                        }
                                        .clippedRoundedBorder(
                                            cornerRadius: DS.Radius.extraLarge,
                                            lineColor: viewModel.borderLineColor,
                                            lineWidth: viewModel.borderLineWidth
                                        )
                                }
                            }
                        }

                    }
                    .padding(.horizontal, DS.Spacing.standard)
                    .padding(.bottom, DS.Spacing.large)
                    .background(DS.Color.Background.norm)
                    .roundedRectangleStyle()
                    .transition(.opacity)
                }
            }
            .animation(.default, value: store.state.isDiscretAppIconOn)
            .padding(.horizontal, DS.Spacing.large)
            .padding(.bottom, DS.Spacing.extraLarge)
        }
        .frame(maxWidth: .infinity)
        .background(DS.Color.BackgroundInverted.norm)
    }

}

#Preview {
    AppIconScreen()
}

private extension AppIconConfigurable {
    var currentIcon: AppIcon {
        if let alternateIconName {
            AppIcon(rawValue: alternateIconName)
        } else {
            AppIcon.default
        }
    }
}

let icons: [AppIcon] = [
    .default, .calculator, .notes, .weather,
]

extension View {
    func clippedRoundedBorder(cornerRadius: CGFloat, lineColor: Color, lineWidth: CGFloat = 1) -> some View {
        modifier(ClippedRoundedBorder(cornerRadius: cornerRadius, lineColor: lineColor, lineWidth: lineWidth))
    }
}

struct AppIconItemViewModel {
    let overlayLineWidth: CGFloat
    let borderLineColor: Color
    let borderLineWidth: CGFloat
}

extension AppIconState {
    func viewModel(for icon: AppIcon) -> AppIconItemViewModel {
        let isSelected = appIcon == icon
        return AppIconItemViewModel(
            overlayLineWidth: isSelected ? 12 : 0,
            borderLineColor: isSelected ? DS.Color.Text.accent : DS.Color.Border.norm,
            borderLineWidth: isSelected ? 3 : 1
        )
    }
}

struct ClippedRoundedBorder: ViewModifier {
    private let cornerRadius: CGFloat
    private let lineColor: Color
    private let lineWidth: CGFloat

    init(cornerRadius: CGFloat, lineColor: Color, lineWidth: CGFloat) {
        self.cornerRadius = cornerRadius
        self.lineWidth = lineWidth
        self.lineColor = lineColor
    }

    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(lineColor, lineWidth: lineWidth))
    }

}
