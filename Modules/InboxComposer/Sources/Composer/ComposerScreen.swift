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

import InboxDesignSystem
import SwiftUI

public struct ComposerScreen: View {
    @StateObject private var model: ComposerModel

    public init() {
        self._model = StateObject(wrappedValue: ComposerModel())
    }

    public var body: some View {
        VStack {
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
                    case .onDidEndEditing:
                        model.finishEditing(group: group)
                    }

                case let .contactPickerEvent(event, group):
                    switch event {
                    case .onInputChange(let text):
                        model.matchContact(group: group, text: text)
                    case .onContactSelected(let contact):
                        model.addContact(group: group, contact: contact)
                    }

                case .onBodyTap:
                    DispatchQueue.main.async {
                        model.state.toRecipients = model.state.toRecipients.copy(\.controllerState, to: .idle) // FIXME: group
                    }
                }
            }

            Spacer()
        }
        .padding(.top, DS.Spacing.extraLarge)
        .background(DS.Color.Background.norm)
    }
}

#Preview {
    ComposerScreen()
}
