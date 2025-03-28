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

import InboxCoreUI
import InboxDesignSystem
import SwiftUI

struct AppSettingsScreen: View {
    @EnvironmentObject var toastStateStore: ToastStateStore

    var body: some View {
        ZStack {
            DS.Color.BackgroundInverted.norm
                .ignoresSafeArea(edges: .all)

            ScrollView {
                VStack(spacing: DS.Spacing.extraLarge) {
                    FormSection(header: L10n.Settings.App.deviceSectionTitle) {
                        VStack(spacing: DS.Spacing.moderatelyLarge) {
                            FormBigButton(
                                title: L10n.Settings.App.notifications,
                                icon: DS.SFSymbols.arrowUpRightSquare,
                                value: .readonly(get: { "Off" }),
                                action: { comingSoon() }
                            )
                            FormBigButton(
                                title: L10n.Settings.App.language,
                                icon: DS.SFSymbols.arrowUpRightSquare,
                                value: .readonly(get: { "English" }),
                                action: { comingSoon() }
                            )
                            FormBigButton(
                                title: L10n.Settings.App.appearance,
                                icon: DS.SFSymbols.chevronUpChevronDown,
                                value: .readonly(get: { "Dark mode" }),
                                action: { comingSoon() }
                            )
                            FormBigButton(
                                title: L10n.Settings.App.protection,
                                icon: DS.SFSymbols.chevronRight,
                                value: .readonly(get: { "PIN code" }),
                                action: { comingSoon() }
                            )
                            FormSwitchView(
                                title: L10n.Settings.App.combinedContacts,
                                additionalInfo: L10n.Settings.App.combinedContactsInfo,
                                isOn: comingSoonBinding
                            )
                        }
                    }
                    FormSection(header: L10n.Settings.App.mailExperience) {
                        VStack(spacing: DS.Spacing.moderatelyLarge) {
                            FormSwitchView(
                                title: L10n.Settings.App.swipeToNextEmail,
                                additionalInfo: L10n.Settings.App.swipeToNextEmailInfo,
                                isOn: comingSoonBinding
                            )
                        }
                    }
                    FormSection(header: L10n.Settings.App.advanced) {
                        VStack(spacing: DS.Spacing.moderatelyLarge) {
                            FormSwitchView(
                                title: L10n.Settings.App.alternativeRouting,
                                additionalInfo: L10n.Settings.App.alternativeRoutingInfo,
                                isOn: comingSoonBinding
                            )
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.large)
                .padding(.bottom, DS.Spacing.extraLarge)
            }
        }
        .navigationTitle(L10n.Settings.App.title.string)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var comingSoonBinding: Binding<Bool> {
        Binding(
            get: { false },
            set: { _ in comingSoon() }
        )
    }

    private func comingSoon() {
        toastStateStore.present(toast: .comingSoon)
    }
}

#Preview {
    NavigationStack {
        AppSettingsScreen()
    }
}
