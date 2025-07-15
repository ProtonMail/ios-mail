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

struct ScheduleSendTimeOptionsView: View {
    private let dateFormatter: ScheduleSendDateFormatter
    private let predefinedTimeOptions: ScheduleSendTimeOptions
    private let isCustomOptionAvailable: Bool
    private let onTimeSelected: (Date) async -> Void
    private let onOpenDatePicker: () -> Void

    init(
        predefinedTimeOptions: ScheduleSendTimeOptions,
        isCustomOptionAvailable: Bool,
        dateFormatter: ScheduleSendDateFormatter,
        onTimeSelected: @escaping (Date) async -> Void,
        onOpenDatePicker: @escaping () -> Void
    ) {
        self.dateFormatter = dateFormatter
        self.predefinedTimeOptions = predefinedTimeOptions
        self.isCustomOptionAvailable = isCustomOptionAvailable
        self.onTimeSelected = onTimeSelected
        self.onOpenDatePicker = onOpenDatePicker
    }

    var body: some View {
        ClosableScreen {
            VStack(spacing: DS.Spacing.medium) {
                if let lastScheduleSendTime = predefinedTimeOptions.lastScheduleSendTime {
                    previouslySet(time: lastScheduleSendTime)
                }

                HStack(spacing: DS.Spacing.large) {
                    predefinedOption(
                        symbol: .sunMax,
                        title: L10n.ScheduleSend.tomorrow.string,
                        time: predefinedTimeOptions.tomorrow,
                        onTap: onTimeSelected
                    )
                    predefinedOption(
                        symbol: .suitcase,
                        title: L10n.ScheduleSend.monday.string,
                        time: predefinedTimeOptions.nextMonday,
                        onTap: onTimeSelected
                    )
                }

                customOption(isCustomOptionAvailable: isCustomOptionAvailable)

                Spacer()
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal, DS.Spacing.large)
            .padding(.top, DS.Spacing.medium)
            .background(DS.Color.BackgroundInverted.norm)
            .navigationTitle(L10n.ScheduleSend.title.string)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    @ViewBuilder
    private func predefinedOption(
        symbol: DS.SFSymbol,
        title: String,
        time: Date,
        onTap: @escaping (Date) async -> Void
    ) -> some View {
        Button(action: { Task { await onTap(time) } }) {
            VStack(spacing: DS.Spacing.small) {
                Image(symbol: symbol)
                    .font(.title2)
                    .foregroundColor(.primary)
                    .padding(.bottom, DS.Spacing.small)
                Text(title)
                    .foregroundStyle(DS.Color.Text.norm)
                    .font(.callout)
                Text(dateFormatter.string(from: time, format: .short))
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
        Button(action: {
            onOpenDatePicker()
        }) {
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
                    Image(symbol: .chevronRight)
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
    private func previouslySet(time: Date) -> some View {
        Button(action: { Task { await onTimeSelected(time) } }) {
            HStack {
                VStack(alignment: .leading, spacing: DS.Spacing.small) {
                    Text(L10n.ScheduleSend.previouslySet.string)
                        .foregroundStyle(DS.Color.Text.weak)
                        .font(.subheadline)
                    Text(dateFormatter.string(from: time, format: .short))
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
    var options: (Bool, UInt64?) -> ScheduleSendTimeOptions = { isCustomAvailable, lastScheduledTime in
        try! ScheduleSendOptionsProvider.dummy(isCustomAvailable: isCustomAvailable)
            .scheduleSendOptions()
            .get()
            .toScheduleSendTimeOptions(lastScheduleSendTime: lastScheduledTime)
    }

    VStack {
        ScheduleSendTimeOptionsView(
            predefinedTimeOptions: options(false, nil),
            isCustomOptionAvailable: false,
            dateFormatter: .init(),
            onTimeSelected: { _ in },
            onOpenDatePicker: {}
        )

        ScheduleSendTimeOptionsView(
            predefinedTimeOptions: options(true, 1904565584),
            isCustomOptionAvailable: true,
            dateFormatter: .init(),
            onTimeSelected: { _ in },
            onOpenDatePicker: {}
        )
    }
}
