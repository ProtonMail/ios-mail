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

import ProtonCoreTestingToolkitUITestsLogin
import XCTest

final class BlockSenderTests: FixtureAuthenticatedTestCase {
    func testGivenSenderIsNotBlocked_whenBlocking_thenBannerBecomesVisible() {
        blockSender()
            .verify.senderBlockedBannerIsShown()
    }

    func testGivenSenderIsBlocked_whenUnblockingThroughBanner_thenBannerDisappears() {
        senderIsAlreadyBlocked()
            .clickMessageByIndex(0)
            .unblockSenderThroughBanner()
            .verify.senderBlockedBannerIsNotShown()
    }

    func testGivenSenderIsBlocked_whenUnblockingThroughActionSheet_thenBannerDisappears() {
        senderIsAlreadyBlocked()
            .clickMessageByIndex(0)
            .expandMessageDetails()
            .tapSenderLabel()
            .unblockSender()
            .verify.senderBlockedBannerIsNotShown()
    }

    func testGivenSenderIsBlocked_whenUnblockingThroughSettings_thenListBecomesEmpty() {
        senderIsAlreadyBlocked()
            .menuDrawer()
            .settings()
            .selectAccount(user.dynamicDomainEmail)
            .blockList()
            .unblockFirstSender()
            .verify.emptyListPlaceholderIsShown()
    }
}

private extension BlockSenderTests {
    func blockSender() -> ExpandedMessageRobot {
        var expandedMessageRobot: ExpandedMessageRobot!

        runTestWithScenario(.qaMail001) {
            expandedMessageRobot = InboxRobot()
                .clickMessageByIndex(0)
                .expandMessageDetails()
                .tapSenderLabel()
                .blockSender()
                .selectOption("Block")
        }

        return expandedMessageRobot
    }

    /// This is in lieu of having a scenario where a sender is already blocked.
    func senderIsAlreadyBlocked() -> InboxRobot {
        _ = blockSender()

        // let the block action be processed
        sleep(3)

        app.terminate()
        app.activate()

        return LoginRobot().loginUser(user)
    }
}
