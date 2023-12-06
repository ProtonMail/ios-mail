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
    private struct ID {
        static let title = "Blocked Senders"
        static let placeholder = "No blocked senders"
        static let editButtonLabel = "Edit"
        static let doneButtonLabel = "Done"
        static let deleteButtonLabel = "Delete"
    }

    let verify = Verify()

    func pullDownToRefresh() -> Self {
        table().firstMatch().tapThenSwipeDown(1, .slow)
        return self
    }

    func beginEditing() -> Self {
        button(ID.editButtonLabel).tap()
        return self
    }

    func endEditing() -> Self {
        button(ID.doneButtonLabel).tap()
        return self
    }

    func unblockFirstSender() -> Self {
        cell().swipeLeft()
        button(ID.deleteButtonLabel).tap()
        return self
    }

    class Verify: CoreElements {
        @discardableResult
        func expectedTitleIsShown() -> BlockListRobot {
            navigationBar(ID.title).waitUntilExists().checkExists()
            return BlockListRobot()
        }

        @discardableResult
        func emptyListPlaceholderIsShown() -> BlockListRobot {
            staticText(ID.placeholder).waitUntilExists().checkExists()
            return BlockListRobot()
        }
    }
}
