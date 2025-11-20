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
import InboxCore
import proton_app_uniffi

enum RecipientControllerStateType {
    case collapsed /* only first recipient and remaining recipient count are visible */
    case expanded /* all recipients are visible */
    case editing /* all recipients are visible and also the cursor to add more recipients */
    case contactPicker /* only the content of the cursor cell is visible */
}

struct RecipientFieldState: Equatable, Copying {
    let group: RecipientGroupType
    var recipients: [RecipientUIModel]

    var input: String
    var matchingContacts: [ComposerContact]
    var controllerState: RecipientControllerStateType
}

extension RecipientFieldState {
    static func initialState(group: RecipientGroupType, recipients: [RecipientUIModel] = []) -> RecipientFieldState {
        .init(group: group, recipients: recipients, input: .empty, matchingContacts: [], controllerState: .collapsed)
    }
}
