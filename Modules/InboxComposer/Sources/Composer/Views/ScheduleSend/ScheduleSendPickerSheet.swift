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

struct ScheduleSendPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    private let dateFormatter: ScheduleSendDateFormatter
    private let options: ScheduleSendOptions
    private var lastScheduleSendTime: UInt64?

    init(provider: ScheduleSendOptionsProvider, dateFormatter: ScheduleSendDateFormatter = .init(), lastScheduleSendTime: UInt64? = nil) {
        self.dateFormatter = dateFormatter
        self.options = provider.options()
        self.lastScheduleSendTime = lastScheduleSendTime
    }

    var body: some View {
        ClosableScreen {
            VStack(spacing: DS.Spacing.medium) {
                Text(L10n.ScheduleSend.title)
                    .lineLimit(1)
                    .foregroundStyle(DS.Color.Text.norm)
                    .font(.body)
                    .fontWeight(.semibold)
                    .padding(.bottom, DS.Spacing.small)

                if let lastScheduleSendTime {
                    previouslySet(time: dateFormatter.string(from: lastScheduleSendTime))
                }

                HStack(spacing: DS.Spacing.large) {
                    predefinedOption(
                        icon: DS.SFSymbols.sunMax,
                        title: L10n.ScheduleSend.tomorrow.string,
                        subtitle: dateFormatter.string(from: options.tomorrowTime)
                    )
                    predefinedOption(
                        icon: DS.SFSymbols.suitcase,
                        title: L10n.ScheduleSend.monday.string,
                        subtitle: dateFormatter.string(from: options.mondayTime)
                    )
                }

                customOption(isCustomOptionAvailable: options.isCustomOptionAvailable)

                Spacer()
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal, DS.Spacing.large)
            .background(DS.Color.BackgroundInverted.norm)
        }
        .presentationDetents([.medium])
    }

    @ViewBuilder
    private func predefinedOption(icon: String, title: String, subtitle: String) -> some View {
        Button(action: {}) {
            VStack(spacing: DS.Spacing.small) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.primary)
                    .padding(.bottom, DS.Spacing.small)
                Text(title)
                    .foregroundStyle(DS.Color.Text.norm)
                    .font(.callout)
                Text(subtitle)
                    .foregroundStyle(DS.Color.Text.weak)
                    .font(.footnote)
            }
            .frame(maxWidth: .infinity)
            .padding(DS.Spacing.moderatelyLarge)
        }
        .applyScheduledSendButtonStyle()
    }

    @ViewBuilder
    private func customOption(isCustomOptionAvailable: Bool) -> some View {
        var subtitle: String {
            isCustomOptionAvailable
                ? L10n.ScheduleSend.customSubtitle.string
                : L10n.ScheduleSend.customSubtitleFreeUser.string
        }
        Button(action: {}) {
            HStack {
                VStack(alignment: .leading, spacing: DS.Spacing.small) {
                    Text(L10n.ScheduleSend.customTitle.string)
                        .foregroundStyle(DS.Color.Text.norm)
                        .font(.callout)
                    Text(subtitle)
                        .foregroundStyle(DS.Color.Text.weak)
                        .font(.footnote)
                }

                Spacer()

                if isCustomOptionAvailable {
                    Image(systemName: DS.SFSymbols.chevronRight)
                        .foregroundStyle(DS.Color.Text.hint)
                } else {
                    Image(DS.Icon.icBrandProtonMailUpsell)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(DS.Spacing.moderatelyLarge)
            .cornerRadius(DS.Radius.extraLarge)
        }
        .applyScheduledSendButtonStyle(strokeColors: isCustomOptionAvailable ? [] : DS.Color.Gradient.crazy)
    }

    @ViewBuilder
    private func previouslySet(time: String) -> some View {
        Button(action: {}) {
            HStack {
                VStack(alignment: .leading, spacing: DS.Spacing.small) {
                    Text(L10n.ScheduleSend.previouslySet.string)
                        .foregroundStyle(DS.Color.Text.weak)
                        .font(.subheadline)
                    Text(time)
                        .foregroundStyle(DS.Color.Text.norm)
                        .font(.callout)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(DS.Spacing.moderatelyLarge)
            .cornerRadius(DS.Radius.extraLarge)
        }
        .applyScheduledSendButtonStyle()
    }
}

private extension View {
    func applyScheduledSendButtonStyle(strokeColors: [Color] = []) -> some View {
        buttonStyle(
            PressableBackgroundButtonStyle(
                normalColor: DS.Color.BackgroundInverted.secondary,
                pressedColor: DS.Color.InteractionWeak.pressed,
                cornerRadius: DS.Radius.extraLarge,
                strokeColors: strokeColors
            )
        )
    }
}

#Preview {
    VStack {
        ScheduleSendPickerSheet(provider: .dummy(isCustomAvailable: false))

        ScheduleSendPickerSheet(provider: .dummy(isCustomAvailable: true), lastScheduleSendTime: 1904565584)
    }
}
