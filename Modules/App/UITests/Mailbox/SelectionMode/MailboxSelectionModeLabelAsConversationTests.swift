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

final class MailboxSelectionModeLabelAsConversationTests: PMUIMockedNetworkTestCase {
    override var loginType: UITestLoginType {
        UITestLoginType.Mocked.Paid.YoungBee
    }

    /// TestId 428273
    func skip_testLabelAsBottomSheetEntriesInConversationMode() async {
        await environment.mockServer.addRequestsWithDefaults(
            useDefaultLabels: false,
            NetworkRequest(
                method: .get,
                remotePath: "/core/v4/labels?Type=1",
                localPath: "labels-type1_428273.json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_428273.json",
                ignoreQueryParams: true
            )
        )

        let expectedEntries = [
            UITestLabelAsBottomSheetEntry(
                index: 0,
                text: "Label 1",
                hasCheckmarkIcon: true
            ),
            UITestLabelAsBottomSheetEntry(
                index: 1,
                text: "Label 2",
                hasCheckmarkIcon: false
            ),
        ]

        let expectedCreationEntryIndex = 2

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.selectItemAt(index: 0)
            $0.tapAction4()
        }

        LabelAsBottomSheetRobot {
            $0.hasAlsoArchive()
            $0.hasEntries(expectedEntries)
            $0.hasCreationEntryAt(expectedCreationEntryIndex)
            $0.hasDoneButton()
        }
    }
}
