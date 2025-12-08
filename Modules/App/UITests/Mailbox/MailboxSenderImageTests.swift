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

final class MailboxSenderImageTests: PMUIMockedNetworkTestCase {
    override var loginType: UITestLoginType {
        UITestLoginType.Mocked.Free.ChirpyFlamingo
    }

    /// TestId 441678
    func testSenderImageIsNotShownOnHideSenderImagesFeatureEnabled() async {
        await environment.mockServer.addRequestsWithDefaults(
            useDefaultMailSettings: false,
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/settings",
                localPath: "mail-v4-settings_441678.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_441678.json",
                ignoreQueryParams: true
            ),
            // Keep the request since if it loads, the test is expected to fail.
            NetworkRequest(
                method: .get,
                remotePath: "/core/v4/images/logo?Address=no-reply%40notify.proton.black&Format=png&Mode=light&Size=128",
                localPath: "proton_logo.png",
                mimeType: .imagePng
            )
        )

        let mailboxEntry = UITestMailboxListItemEntry(
            index: 0,
            avatar: .initials("P"),
            sender: "Proton",
            subject: "Set up automatic forwarding from Gmail in one click",
            date: "Mar 6, 2023",
            count: nil
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.hasEntries(entries: mailboxEntry)
        }
    }

    /// TestId 448445
    func testSenderImageIsShownOnHideSenderImagesFeatureNotEnabledAndImageAvailable() async {
        await environment.mockServer.addRequestsWithDefaults(
            useDefaultMailSettings: false,
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/settings",
                localPath: "mail-v4-settings_448445.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_448445.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/core/v4/images/logo?Address=no-reply%40notify.proton.black&Format=png&Mode=light&Size=128",
                localPath: "proton_logo.png",
                mimeType: .imagePng
            )
        )

        let mailboxEntry = UITestMailboxListItemEntry(
            index: 0,
            avatar: .image,
            sender: "Proton",
            subject: "Set up automatic forwarding from Gmail in one click",
            date: "Mar 6, 2023",
            count: nil
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.hasEntries(entries: mailboxEntry)
        }
    }

    /// TestId 448445/2, 448446
    func testSenderImageIsNotShownOnHideSenderImagesFeatureNotEnabledAndBeErrorOccurs() async {
        await environment.mockServer.addRequestsWithDefaults(
            useDefaultMailSettings: false,
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/settings",
                localPath: "mail-v4-settings_448445.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_448445.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/core/v4/images/logo?Address=no-reply%40notify.proton.black&Format=png&Mode=light&Size=128",
                localPath: "error_mock.json",
                status: 500
            )
        )

        let mailboxEntry = UITestMailboxListItemEntry(
            index: 0,
            avatar: .initials("P"),
            sender: "Proton",
            subject: "Set up automatic forwarding from Gmail in one click",
            date: "Mar 6, 2023",
            count: nil
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.hasEntries(entries: mailboxEntry)
        }
    }

    /// TestId 448445/3, 448447
    func testSenderImageIsNotShownOnHideSenderImagesFeatureNotEnabledButNoImageAvailable() async {
        await environment.mockServer.addRequestsWithDefaults(
            useDefaultMailSettings: false,
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/settings",
                localPath: "mail-v4-settings_448445.json",
                serveOnce: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_448447.json",
                ignoreQueryParams: true
            )
        )

        let mailboxEntry = UITestMailboxListItemEntry(
            index: 0,
            avatar: .initials("P"),
            sender: "Proton",
            subject: "Set up automatic forwarding from Gmail in one click",
            date: "Mar 6, 2023",
            count: nil
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.hasEntries(entries: mailboxEntry)
        }
    }
}
