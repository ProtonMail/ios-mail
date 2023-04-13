// Copyright (c) 2023 Proton Technologies AG
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

import fusion

class BlockListRobot: CoreElements {
    private enum ID: String {
        case title = "Blocked Senders"
        case placeholder = "No blocked senders"
        case editButtonLabel = "Edit"
        case doneButtonLabel = "Done"
    }

    let verify = Verify()

    func pullDownToRefresh() -> Self {
        table().firstMatch().tapThenSwipeDown(1, .slow)
        return self
    }

    func beginEditing() -> Self {
        button(ID.editButtonLabel.rawValue).tap()
        return self
    }

    func endEditing() -> Self {
        button(ID.doneButtonLabel.rawValue).tap()
        return self
    }

    class Verify: CoreElements {
        @discardableResult
        func expectedTitleIsShown() -> Self {
            navigationBar(ID.title.rawValue).waitUntilExists().checkExists()
            return self
        }

        @discardableResult
        func emptyListPlaceholderIsShown() -> Self {
            staticText(ID.placeholder.rawValue).waitUntilExists().checkExists()
            return self
        }
    }
}
