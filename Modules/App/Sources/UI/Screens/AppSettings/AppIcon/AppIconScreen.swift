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
                        Text(L10n.Settings.AppIcon.title)
                            .font(.title3.bold())
                            .foregroundStyle(DS.Color.Text.norm)
                        Text(L10n.Settings.AppIcon.description)
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

                    FormSwitchView(title: L10n.Settings.AppIcon.discreetToggle, isOn: $store.state.isDiscretAppIconOn)
                        .padding(.bottom, DS.Spacing.compact)
                }
                .frame(maxWidth: .infinity)
                .background(DS.Color.Background.norm)
                .roundedRectangleStyle()

                if store.state.isDiscretAppIconOn {
                    FormSection {
                        LazyVGrid(columns: Array(repeating: .init(), count: 4)) {
                            ForEach(AppIcon.allCases, id: \.self) { icon in
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

private struct AppIconItemViewModel {
    let overlayLineWidth: CGFloat
    let borderLineColor: Color
    let borderLineWidth: CGFloat
}

private extension AppIconState {
    func viewModel(for icon: AppIcon) -> AppIconItemViewModel {
        let isSelected = appIcon == icon
        return AppIconItemViewModel(
            overlayLineWidth: isSelected ? 12 : 0,
            borderLineColor: isSelected ? DS.Color.Text.accent : DS.Color.Border.norm,
            borderLineWidth: isSelected ? 3 : 1
        )
    }
}
