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

import proton_app_uniffi

typealias LabelAsActionClosure<T> = (
    _ mailbox: Mailbox,
    _ ids: [ID],
    _ selectedLabelIDs: [ID],
    _ partiallySelectedLabelIDs: [ID],
    _ archive: Bool
) async -> T

struct LabelAsActions {
    let labelMessagesAs: LabelAsActionClosure<LabelMessagesAsResult>
    let labelConversationsAs: LabelAsActionClosure<LabelConversationsAsResult>
}

extension LabelAsActions {

    static var productionInstance: Self {
        .init(
            labelMessagesAs: proton_app_uniffi.labelMessagesAs,
            labelConversationsAs: proton_app_uniffi.labelConversationsAs
        )
    }

    static var dummy: Self {
        .init(
            labelMessagesAs: { _, _, _, _, _ in .ok(.init(noPointer: .init())) },
            labelConversationsAs: { _, _, _, _, _ in .ok(.init(noPointer: .init())) }
        )
    }

}
