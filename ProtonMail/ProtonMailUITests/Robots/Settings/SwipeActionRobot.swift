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

fileprivate struct id {
    static let leftToRightText = LocalString._swipe_left_to_right
    static let rightToLeftText = LocalString._swipe_right_to_left
    static let moveToSpam = LocalString._move_to_spam
    static let labelAs = LocalString._label_as_
    static let backButton = LocalString._swipe_actions
    static let doneButton = LocalString._general_done_button
    static let moveToTrash = "Trash"
    static let trashIcon = "ic-trash"
    static let archiveIcon = "ic-archive-box"
    static let checkmarkButton = "checkmark"
}

class SwipeActionRobot: CoreElements {
    
    var verify = Verify()
    
    func leftToRight() -> SwipeActionRobot {
        cell(id.leftToRightText).tap()
        return self
    }
    
    func rightToLeft() -> SwipeActionRobot {
        cell(id.rightToLeftText).tap()
        return self
    }
    
    func moveToSpam() -> SwipeActionRobot {
        staticText(id.moveToSpam).tap()
        return self
    }
    
    func labelAs() -> SwipeActionRobot {
        staticText(id.labelAs).tap()
        return self
    }
    
    func backButton() -> SwipeActionRobot {
        button(id.backButton).tap()
        return self
    }
    
    func doneButton() -> SwipeActionRobot {
        button(id.doneButton).tap()
        return self
    }
}

class Verify: CoreElements {

    func leftToRightIsMoveToTrash() -> SwipeActionRobot {
        cell().hasDescendant(image(id.archiveIcon)).checkHasChild(button(id.checkmarkButton))
        return SwipeActionRobot()
    }
    
    @discardableResult
    func rightToLeftIsMoveToArchive() -> SwipeActionRobot {
        cell().hasDescendant(image(id.archiveIcon)).checkHasChild(button(id.checkmarkButton))
        return SwipeActionRobot()
    }
}
