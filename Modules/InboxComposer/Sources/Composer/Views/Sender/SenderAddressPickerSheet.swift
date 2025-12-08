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

struct SenderAddressPickerSheet: View {
    @StateObject private var model: SenderAddressPickerSheetModel

    init(model: SenderAddressPickerSheetModel) {
        self._model = .init(wrappedValue: model)
    }

    var body: some View {
        ClosableScreen {
            VStack(spacing: DS.Spacing.medium) {
                Text(L10n.Composer.senderPickerSheetTitle)
                    .lineLimit(1)
                    .foregroundStyle(DS.Color.Text.norm)
                    .font(.body)
                    .fontWeight(.semibold)

                ScrollView {
                    VStack(spacing: .zero) {
                        ForEach(model.state.addresses, id: \.self) { address in
                            addressButton(for: address)
                        }
                    }
                    .background(DS.Color.BackgroundInverted.secondary)
                    .clipShape(.rect(cornerRadius: DS.Radius.extraLarge))
                    .padding(.all, DS.Spacing.large)
                }
            }
            .frame(maxWidth: .infinity)
            .onAppear { Task { await model.handleAction(.viewAppear) } }
            .background(DS.Color.BackgroundInverted.norm)
            .presentationDetents([.fraction(0.4), .large])
        }
    }

    private func addressButton(for address: String) -> some View {
        ActionSheetButton(
            displayBottomSeparator: address != model.state.addresses.last,
            action: {
                Task { await model.handleAction(.selected(address)) }
            }
        ) {
            HStack {
                VStack(alignment: .leading, spacing: .zero) {
                    if address == model.state.addresses.first {
                        Text(CommonL10n.default.string)
                            .font(.caption)
                            .foregroundStyle(DS.Color.Text.weak)
                            .padding(.bottom, DS.Spacing.tiny)
                    }
                    Text(address)
                        .font(.callout)
                        .foregroundStyle(DS.Color.Text.norm)
                }
                Spacer()
                if address == model.state.activeAddress {
                    Image(DS.Icon.icCheckmark)
                        .resizable()
                        .square(size: 24)
                        .padding(.trailing, DS.Spacing.large)
                        .foregroundStyle(DS.Color.Icon.accent)
                }
            }
            .padding(.vertical, DS.Spacing.moderatelyLarge)
        }
    }
}

#Preview {
    SenderAddressPickerSheet(
        model: .init(
            state: .init(),
            handler: MockChangeSenderHandler(),
            toastStateStore: .init(initialState: .initial),
            dismiss: {}
        )
    )
}
