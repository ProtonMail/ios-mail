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

import Foundation

final class ComposerModel: ObservableObject {
    @Published var state: ComposerState

    init(state: ComposerState = .init(recipients: [])) {
        self.state = state
    }

    func recipientToggleSelection(group: RecipientGroupType, index: Int) {
        // FIXME: take group into account
        state.recipients[index].isSelected.toggle()
    }

    func removeSelectedRecipients(group: RecipientGroupType) {
        // FIXME: take group into account
        state.recipients = state.recipients.filter { $0.isSelected == false }
    }

    func onClearSelected(group: RecipientGroupType) {
        // FIXME: take group into account
        var recipients = state.recipients
        recipients.indices.forEach { recipients[$0].isSelected = false }
        state.recipients = recipients
    }

    func selectLastRecipient(group: RecipientGroupType) {
        // FIXME: take group into account
        guard !state.recipients.isEmpty else { return }
        state.recipients[state.recipients.count - 1].isSelected = true
    }

    func addRecipient(group: RecipientGroupType, address: String) {
        // FIXME: take group into account, call the SDK
        let newRecipient = RecipientUIModel(type: .single, address: address, isSelected: false, isValid: false, isEncrypted: false)
        state.recipients.append(newRecipient)
    }

    func addRandomRecipient() {
        state.recipients.append(ComposerScreenPreviewProvider.makeRandom(suffix: String(state.recipients.count)))
    }
}
