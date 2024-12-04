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

import InboxCore
import InboxDesignSystem
import SwiftUI

public struct ComposerScreen: View {
    @Environment(\.dismissTestable) var dismiss: Dismissable
    @StateObject private var model: ComposerModel

    public init() {
        self._model = StateObject(wrappedValue: ComposerModel())
    }

    public var body: some View {
        VStack(spacing: 0) {
            topBarView()

            ComposerControllerRepresentable(state: model.state) { event in
                switch event {

                case let .recipientFieldEvent(recipientFieldEvent, group):
                    switch recipientFieldEvent {
                    case .onFieldTap:
                        model.startEditingRecipients(for: group)
                    case .onInputChange(let text):
                        model.matchContact(group: group, text: text)
                    case .onRecipientSelected(let index):
                        model.recipientToggleSelection(group: group, index: index)
                    case .onReturnKeyPressed(let text):
                        model.addRecipient(group: group, address: text)
                    case .onDeleteKeyPressedInsideEmptyInputField:
                        model.selectLastRecipient(group: group)
                    case .onDeleteKeyPressedOutsideInputField:
                        model.removeSelectedRecipients(group: group)
                    }

                case let .contactPickerEvent(event, group):
                    switch event {
                    case .onInputChange(let text):
                        model.matchContact(group: group, text: text)
                    case .onContactSelected(let contact):
                        model.addContact(group: group, contact: contact)
                    }

                case .onNonRecipientFieldStartEditing:
                    model.endEditingRecipients()
                }
            }
            .onLoad {
                model.onLoad()
            }

            Spacer()
        }
        .background(DS.Color.Background.norm)
    }

    func topBarView() -> some View {
        HStack(spacing: DS.Spacing.standard) {
            Button(action:{ dismiss() }) {
                Image(DS.Icon.icCross)
                    .square(size: Layout.iconSize)
                    .foregroundStyle(DS.Color.Icon.weak)
            }
            .square(size: Layout.buttonSize)

            Spacer()
            Button(action:{ }) {
                Image(DS.Icon.icClockPaperPlane)
                    .square(size: Layout.iconSize)
                    .foregroundStyle(DS.Color.InteractionBrandWeak.disabled)
            }
            .square(size: Layout.buttonSize)

            SendButton {

            }.disabled(true) // FIXME: attach to state
        }
        .padding(.leading, DS.Spacing.standard)
        .padding(.top, DS.Spacing.mediumLight)
        .padding(.trailing, DS.Spacing.medium)
        .padding(.bottom, DS.Spacing.small)
    }
}

extension ComposerScreen {

    private enum Layout {
        static let iconSize: CGFloat = 24
        static let buttonSize: CGFloat = 40
    }
}

#Preview {
    ComposerScreen()
}
