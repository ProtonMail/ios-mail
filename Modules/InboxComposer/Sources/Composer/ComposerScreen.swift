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

import SwiftUI

public struct ComposerScreen: View {
    @StateObject private var model: ComposerModel

    public init() {
        self._model = StateObject(wrappedValue: ComposerModel())
    }

    public var body: some View {
        VStack {
            HStack {
                Button { model.addRandomRecipient() } label: {
                    Text("ADD RANDOM CONTACT".notLocalized)
                }
            }

            ComposerControllerRepresentable(state: model.state) { event in
                switch event {
                case let .recipientFieldEvent(recipientFieldEvent, group):
                    switch recipientFieldEvent {
                    case .onRecipientSelected(let index):
                        model.recipientToggleSelection(group: group, index: index)
                    case .onReturnKeyPressed(let text):
                        model.addRecipient(group: group, address: text)
                    case .onDeleteKeyPressedInsideEmptyInputField:
                        model.selectLastRecipient(group: group)
                    case .onDeleteKeyPressedOutsideInputField:
                        model.removeSelectedRecipients(group: group)
                    case .onDidEndEditing:
                        model.onClearSelected(group: group)
                    }
                }
            }

            Spacer()
        }
    }
}

#Preview {
    ComposerScreen()
}
