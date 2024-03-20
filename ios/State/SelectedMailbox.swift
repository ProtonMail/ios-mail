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

import UIKit

final class SelectedMailbox: Equatable, Hashable, ObservableObject, Sendable {
    let localId: PMLocalLabelId
    let name: String

    init(localId: PMLocalLabelId, name: String) {
        self.localId = localId
        self.name = name
    }

    static func == (lhs: SelectedMailbox, rhs: SelectedMailbox) -> Bool {
        lhs.localId == rhs.localId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(localId)
        hasher.combine(name)
    }
}

extension SelectedMailbox {

    // TODO: Get the default localId from the Rust SDK
    static let defaultMailbox = SelectedMailbox(
        localId: 4,
        name: SystemFolderIdentifier.inbox.localisedName
    )
}
