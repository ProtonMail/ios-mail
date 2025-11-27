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

final class MailboxSelectionModeLabelAsTests: PMUIMockedNetworkTestCase {
    override var loginType: UITestLoginType {
        UITestLoginType.Mocked.Paid.YoungBee
    }

    /// TestId 427477
    func skip_testLabelAsBottomSheetClosedWithDoneButton() async {
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
            $0.selectItemAt(index: 0)
            $0.tapAction4()
        }

        LabelAsBottomSheetRobot {
            $0.verifyShown()

            $0.tapDoneButton()
            $0.verifyHidden()
        }
    }

    /// TestId 427478
    func skip_testLabelAsBottomSheetClosedWithExternalTap() async {
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
            $0.selectItemAt(index: 0)
            $0.tapAction4()
        }

        LabelAsBottomSheetRobot {
            $0.verifyShown()
        }

        MailboxRobot {
            $0.selectItemAt(index: 1)
        }

        LabelAsBottomSheetRobot {
            $0.verifyHidden()
        }
    }
}
