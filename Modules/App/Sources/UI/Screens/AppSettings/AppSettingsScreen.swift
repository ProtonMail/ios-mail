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

import InboxDesignSystem
import SwiftUI

struct AppSettingsScreen: View {

    var body: some View {
        ZStack {
            DS.Color.BackgroundInverted.norm
                .ignoresSafeArea(edges: .all)

            ScrollView {
                VStack(spacing: DS.Spacing.extraLarge) {
                    FormSection(header: "Device") {
                        VStack(spacing: DS.Spacing.moderatelyLarge) {
                            FormBigButton(
                                title: "Notifications",
                                icon: "arrow.up.right.square",
                                value: .readonly(get: { "On" }),
                                action: {}
                            )
                            FormBigButton(
                                title: "Language",
                                icon: "arrow.up.right.square",
                                value: .readonly(get: { "English" }),
                                action: {}
                            )
                            FormBigButton(
                                title: "Appearance",
                                icon: "chevron.up.chevron.down",
                                value: .readonly(get: { "Dark mode" }),
                                action: {}
                            )
                            FormBigButton(
                                title: "Protection",
                                icon: DS.SFSymbols.chevronRight,
                                value: .readonly(get: { "PIN code" }),
                                action: {}
                            )
                            FormSwitchView(
                                title: "Use device contacts",
                                additionalInfo: "Auto-complete email addresses using contacts from your device.",
                                isOn: .readonly(get: { true })
                            )
                        }
                    }
                    FormSection(header: "Mail experience") {
                        VStack(spacing: DS.Spacing.moderatelyLarge) {
                            FormSwitchView(
                                title: "Swipe to next email",
                                additionalInfo: "Quickly move to the next or previous message in your inbox.",
                                isOn: .readonly(get: { true })
                            )
                            FormSmallButton(
                                title: "Swipe actions",
                                additionalInfo: "Set quick actions, such as delete or archive, when you swipe left or right. ",
                                action: {}
                            )
                            FormSmallButton(
                                title: "Customize toolbar",
                                additionalInfo: nil,
                                action: {}
                            )
                        }
                    }
                    FormSection(header: "Advanced") {
                        VStack(spacing: DS.Spacing.moderatelyLarge) {
                            FormSwitchView(
                                title: "Alternative routing",
                                additionalInfo: nil,
                                isOn: .readonly(get: { true })
                            )
                            FormSmallButton(
                                title: "View application logs",
                                additionalInfo: "Set quick actions, such as delete or archive, when you swipe left or right. ",
                                action: {}
                            )
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.large)
                .padding(.bottom, DS.Spacing.extraLarge)
            }
        }
        .navigationTitle("App customisations")
        .navigationBarTitleDisplayMode(.inline)
    }

}

#Preview {
    NavigationStack {
        AppSettingsScreen()
    }
}
