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
import XCTest

final class MailboxSelectionModeTests: PMUITestCase {
    private let firstSelectableItemIndex = 0
    private let secondSelectableItemIndex = 1

    /// TestId 422156
    func testLongClickSelectionMode() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_base_placeholder_multiple.json",
                ignoreQueryParams: true
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.longPressItemAt(index: firstSelectableItemIndex)
            $0.hasSelectedItemAt(index: firstSelectableItemIndex)
            $0.hasUnselectedItemAt(index: secondSelectableItemIndex)
        }
    }
    
    /// TestId 422157, 422159, 422160
    func testAvatarClickSelectionMode() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_base_placeholder_multiple.json",
                ignoreQueryParams: true
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.selectItemAt(index: firstSelectableItemIndex)

            $0.hasSelectedItemAt(index: firstSelectableItemIndex)
            $0.hasUnselectedItemAt(index: secondSelectableItemIndex)
            $0.verifySelectionState(withCount: 1)

            $0.unselectItemsAt(indexes: firstSelectableItemIndex)
            $0.hasUnselectedItemAt(index: firstSelectableItemIndex)
            $0.verifyMailboxTitle(folder: UITestFolder.system(.inbox))
        }
    }

    /// TestId 422158
    func testMultipleSelection() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_base_placeholder_multiple.json",
                ignoreQueryParams: true
            )
        )

        let selectedIndexes = [firstSelectableItemIndex, secondSelectableItemIndex]

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.selectItemsAt(indexes: selectedIndexes)
            $0.verifySelectionState(withCount: selectedIndexes.count)
        }
    }

    /// TestId 422161, 422162, 422163
    func testMultipleSelectionsPlusDismissal() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_base_placeholder_multiple.json",
                ignoreQueryParams: true
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.selectItemAt(index: firstSelectableItemIndex)
            $0.verifySelectionState(withCount: 1)
            $0.selectItemAt(index: secondSelectableItemIndex)
            $0.verifySelectionState(withCount: 2)
            $0.unselectItemAt(index: secondSelectableItemIndex)
            $0.verifySelectionState(withCount: 1)
            $0.unselectItemAt(index: firstSelectableItemIndex)

            $0.verifyMailboxTitle(folder: UITestFolder.system(.inbox))
        }
    }

    /// TestId 425645
    func testSelectionModeDismissalWithBackButton() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_base_placeholder_multiple.json",
                ignoreQueryParams: true
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.selectItemAt(index: firstSelectableItemIndex)
            $0.tapBackButton()
            $0.hasUnselectedItemAt(index: firstSelectableItemIndex)
            $0.verifyMailboxTitle(folder: UITestFolder.system(.inbox))
        }
    }
}
