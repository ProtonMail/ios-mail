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

final class MailboxAttachmentPreviewsTests: PMUIMockedNetworkTestCase {
    
    override var loginType: UITestLoginType {
        UITestLoginType.Mocked.Free.ChirpyFlamingo
    }
    
    /// TestId 443740
    func testAttachmentPreviewLoading() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_443740.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations/*",
                localPath: "conversation-id_443740.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages/*",
                localPath: "message-id_443740.json",
                wildcardMatch: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/attachments/-jN59ymYxAjO0iukRxotifr4-xTqQe6-fyJ5KiUEoyp6CIICgRdV1amqy2SWmVnBw2_g9XyFo7MS0e_qpaacIw==/metadata",
                localPath: "attachments-metadata_443740.json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/attachments/-jN59ymYxAjO0iukRxotifr4-xTqQe6-fyJ5KiUEoyp6CIICgRdV1amqy2SWmVnBw2_g9XyFo7MS0e_qpaacIw==",
                localPath: "attachment_443740.zyx",
                mimeType: .octetStream
            )
        )
        
        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.tapAttachmentCapsuleAt(forItem: 0, atIndex: 0)
        }
        
        SystemPreviewRobot {
            $0.verifyShown(withAttachmentName: "image")
        }
    }
    
    /// TestId 443741
    func testAttachmentCapsulePreview() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_443740.json",
                ignoreQueryParams: true
            )
        )
        
        let capsules = [UITestAttachmentPreviewCapsuleItemEntry(index: 0, attachmentName: "image.png")]
        let attachmentPreviews = UITestAttachmentPreviewItemEntry(items: capsules)
            
        let entry = UITestMailboxListItemEntry(
            index: 0,
            avatar: .initials("P"),
            sender: "proton898",
            subject: "Attachments Test 1",
            date: "Jul 25",
            attachmentPreviews: attachmentPreviews
        )
        
        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.hasEntries(entries: entry)
        }
    }
    
    /// TestId 443742
    func testMultipleAttachmentCapsulePreviews() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_443742.json",
                ignoreQueryParams: true
            )
        )
        
        let capsules = [
            UITestAttachmentPreviewCapsuleItemEntry(index: 0, attachmentName: "fifth.png"),
            UITestAttachmentPreviewCapsuleItemEntry(index: 1, attachmentName: "first.png")
        ]
        let attachmentPreviews = UITestAttachmentPreviewItemEntry(items: capsules, extraItemsCount: 4)
        
        let entry = UITestMailboxListItemEntry(
            index: 0,
            avatar: .initials("P"),
            sender: "proton898",
            subject: "Multiple attachments",
            date: "Jul 25",
            attachmentPreviews: attachmentPreviews
        )
        
        navigator.navigateTo(UITestDestination.inbox)
        
        MailboxRobot {
            $0.hasEntries(entries: entry)
        }
    }
}
