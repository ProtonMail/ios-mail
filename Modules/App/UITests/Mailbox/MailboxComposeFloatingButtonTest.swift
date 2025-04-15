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

final class MailboxComposeFloatingButtonTest: PMUIMockedNetworkTestCase {

    override var loginType: UITestLoginType {
        UITestLoginType.Mocked.Free.ChirpyFlamingo
    }

    /// TestId 448600
    func testComposeButtonShownAsExpandedByDefault() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_448600.json",
                ignoreQueryParams: true
            )
        )

        navigator.navigateTo(.inbox)

        MailboxRobot {
            $0.hasComposeButtonExpanded()
        }
    }

    /// TestId 448601
    func testComposeButtonCollapsesOnScrollDownwardsGesture() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_448601.json",
                ignoreQueryParams: true
            )
        )

        navigator.navigateTo(.inbox)

        MailboxRobot {
            $0.hasComposeButtonExpanded()
            $0.scrollDown()

            $0.hasComposeButtonCollapsed()
        }
    }

    /// TestId 448602
    func testComposeButtonReExpandsOnScrollUpwardsGesture() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_448602.json",
                ignoreQueryParams: true
            )
        )

        navigator.navigateTo(.inbox)

        MailboxRobot {
            $0.hasComposeButtonExpanded()
            $0.scrollDown()

            $0.scrollUp()
            $0.hasComposeButtonExpanded()
        }
    }

    /// TestId 448603, 448604
    func testComposeButtonVisibilityDependsOnSelectionMode() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_448603.json",
                ignoreQueryParams: true
            )
        )

        navigator.navigateTo(.inbox)

        MailboxRobot {
            $0.selectItemAt(index: 0)
            $0.hasComposeButtonHidden()

            $0.unselectItemAt(index: 0)
            $0.hasComposeButtonExpanded()
        }
    }
}
