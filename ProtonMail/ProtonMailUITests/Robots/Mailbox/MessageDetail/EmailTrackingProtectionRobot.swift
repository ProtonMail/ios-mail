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

import XCTest
import fusion

fileprivate struct id {
    static func bounceExchangeTrackerCellIdentifier(_ name: String ) -> String { return "TrackerTableViewCell.\(name)" }
    static let trackersTableIdentifier = "TrackerListViewController.tableView"
}

class EmailTrackingProtectionRobot: CoreElements {
    
    var verify = Verify()
    
    func clickOnTrackerWithLabel(_ label: String) -> Self {
        otherElement(label).tap()
        return self
    }

    /**
     * Contains all the validations that can be performed by [Drafts].
     */
    class Verify: MailboxRobotVerifyInterface {

        func trackerCountByLabelIs(label: String, count: Int) -> EmailTrackingProtectionRobot {
            otherElement(label).onDescendant(staticText().byIndex(1)).checkHasLabel(String(count))
            return EmailTrackingProtectionRobot()
        }

        func trackerCellIsShown(name: String) {
            cell(id.bounceExchangeTrackerCellIdentifier(name)).checkExists()
        }
    }
}
