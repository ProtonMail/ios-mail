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

@testable import ProtonMail
import XCTest

final class SwipeActionTests: BaseTestCase {

    func testIsActionAssigned_whenNone() {
        XCTAssertFalse(SwipeAction.none.isActionAssigned(systemFolder: nil))
        SystemFolderLabel.allFolders().forEach {
            XCTAssertFalse(SwipeAction.none.isActionAssigned(systemFolder: $0), $0.testFailDescription)
        }
    }

    func testIsActionAssigned_whenMoveToTrash() {
        XCTAssertTrue(SwipeAction.moveToTrash.isActionAssigned(systemFolder: nil))
        SystemFolderLabel.allFolders(except: .trash).forEach {
            XCTAssertTrue(SwipeAction.moveToTrash.isActionAssigned(systemFolder: $0), $0.testFailDescription)
        }
        XCTAssertFalse(SwipeAction.moveToTrash.isActionAssigned(systemFolder: .trash))
    }

    func testIsActionAssigned_whenToggleReadStatus() {
        XCTAssertTrue(SwipeAction.toggleReadStatus.isActionAssigned(systemFolder: nil))
        SystemFolderLabel.allFolders().forEach {
            XCTAssertTrue(SwipeAction.toggleReadStatus.isActionAssigned(systemFolder: $0), $0.testFailDescription)
        }
    }

    func testIsActionAssigned_whenDelete() {
        XCTAssertTrue(SwipeAction.delete.isActionAssigned(systemFolder: nil))
        SystemFolderLabel.allFolders().forEach {
            XCTAssertTrue(SwipeAction.delete.isActionAssigned(systemFolder: $0), $0.testFailDescription)
        }
    }

}

private extension SystemFolderLabel {

    static func allFolders(except systemFolder: SystemFolderLabel? = nil) -> [SystemFolderLabel] {
        var allFolders: Set<SystemFolderLabel> = [
            .inbox,
            .allDrafts,
            .allSent,
            .trash,
            .spam,
            .allMail,
            .archive,
            .sent,
            .drafts,
            .outbox,
            .starred,
            .scheduled,
            .almostAllMail,
            .snoozed,
            .categorySocial,
            .categoryPromotions,
            .catergoryUpdates,
            .categoryForums,
            .categoryDefault
        ]
        if let systemFolder {
            allFolders.remove(systemFolder)
        }
        return Array(allFolders)
    }

    var testFailDescription: String {
        "test failed for folder '\(self)'"
    }
}
