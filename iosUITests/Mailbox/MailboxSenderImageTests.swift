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
    func testSenderImageIsShownInPlaceOfAvatar() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_441678.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/core/v4/images/logo?Address=no-reply%40notify.proton.black&Size=128&Mode=light&Format=png",
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
    
    /// TestId 441678/2, 441679
    func testSenderImageIsNotShownInPlaceOfAvatarWhenBeErrorOccurs() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_441678.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/core/v4/images/logo?Address=no-reply%40notify.proton.black&Size=128&Mode=light&Format=png",
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
}
