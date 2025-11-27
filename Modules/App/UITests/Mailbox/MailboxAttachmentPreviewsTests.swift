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
    func testAttachmentPreviewOpening() async {
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

    /// TestId 448448
    func testAttachmentPreviewLoadingOnMetadataLoading() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_448448.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/attachments/-jN59ymYxAjO0iukRxotifr4-xTqQe6-fyJ5KiUEoyp6CIICgRdV1amqy2SWmVnBw2_g9XyFo7MS0e_qpaacIw==/metadata",
                localPath: "attachments-metadata_448448.json",
                latency: 100
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.tapAttachmentCapsuleAt(forItem: 0, atIndex: 0)
        }

        SystemPreviewRobot {
            $0.verifyLoading()
        }
    }

    /// TestId 448448/2
    func testAttachmentPreviewLoadingOnBlobLoading() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_448448.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/attachments/-jN59ymYxAjO0iukRxotifr4-xTqQe6-fyJ5KiUEoyp6CIICgRdV1amqy2SWmVnBw2_g9XyFo7MS0e_qpaacIw==/metadata",
                localPath: "attachments-metadata_448448.json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/attachments/-jN59ymYxAjO0iukRxotifr4-xTqQe6-fyJ5KiUEoyp6CIICgRdV1amqy2SWmVnBw2_g9XyFo7MS0e_qpaacIw==",
                localPath: "attachment_448448.zyx",
                latency: 100,
                mimeType: .octetStream
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.tapAttachmentCapsuleAt(forItem: 0, atIndex: 0)
        }

        SystemPreviewRobot {
            $0.verifyLoading()
        }
    }

    /// TestId 448448/3, 448449
    func testAttachmentPreviewLoadingDismissal() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_448448.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/attachments/-jN59ymYxAjO0iukRxotifr4-xTqQe6-fyJ5KiUEoyp6CIICgRdV1amqy2SWmVnBw2_g9XyFo7MS0e_qpaacIw==/metadata",
                localPath: "attachments-metadata_448448.json",
                latency: 100
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.tapAttachmentCapsuleAt(forItem: 0, atIndex: 0)
        }

        SystemPreviewRobot {
            $0.verifyLoading()

            $0.tapDoneButton()
            $0.verifyGone()
        }

        MailboxRobot {
            $0.verifyShown()
        }
    }

    /// TestId 443741
    func testAttachmentCapsulePreview() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_443741.json",
                ignoreQueryParams: true
            )
        )

        let capsules = [UITestAttachmentPreviewCapsuleItemEntry(index: 0, attachmentName: "image.png")]
        let attachmentPreviews = UITestAttachmentPreviewItemEntry(items: capsules)

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.hasAttachmentPreviewEntries(index: 0, entries: attachmentPreviews)
        }
    }

    /// TestId 443741/2
    func testAttachmentCapsulePreviewInSentFolder() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_empty.json",
                ignoreQueryParams: true
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/messages",
                localPath: "messages_443741_2.json",
                ignoreQueryParams: true
            )
        )

        let capsules = [UITestAttachmentPreviewCapsuleItemEntry(index: 0, attachmentName: "zipfile_reply.zip")]
        let attachmentPreviews = UITestAttachmentPreviewItemEntry(items: capsules)

        navigator.navigateTo(UITestDestination.sent)

        MailboxRobot {
            $0.hasAttachmentPreviewEntries(index: 0, entries: attachmentPreviews)
        }
    }

    /// TestId 443743
    func testMultipleAttachmentCapsulePreviews() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_443743.json",
                ignoreQueryParams: true
            )
        )

        let capsules = [
            UITestAttachmentPreviewCapsuleItemEntry(index: 0, attachmentName: "fifth.png"),
            UITestAttachmentPreviewCapsuleItemEntry(index: 1, attachmentName: "first.png"),
        ]
        let attachmentPreviews = UITestAttachmentPreviewItemEntry(items: capsules, extraItemsCount: 4)

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.hasAttachmentPreviewEntries(index: 0, entries: attachmentPreviews)
        }
    }

    /// TestId 448452
    func testNoAttachmentCapsuleShownOnEmbeddedImagesOnly() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_448452.json",
                ignoreQueryParams: true
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.hasNoAttachmentPreviewEntries(index: 0)
        }
    }

    /// TestId 448453
    /// To be re-enabled when ET-927 is addressed.
    func skip_testNoAttachmentCapsuleOnICSFileAttached() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_448453.json",
                ignoreQueryParams: true
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.hasNoAttachmentPreviewEntries(index: 0)
        }
    }

    /// TestId 448454
    /// To be re-enabled when ET-927 is addressed.
    func skip_testNoAttachmentCapsuleOnASCFileAttached() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_448454.json",
                ignoreQueryParams: true
            )
        )

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.hasNoAttachmentPreviewEntries(index: 0)
        }
    }

    /// TestId 448455
    func testAttachmentCapsuleOnlyShownOnStandardAttachment() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_448455.json",
                ignoreQueryParams: true
            )
        )

        let capsules = [UITestAttachmentPreviewCapsuleItemEntry(index: 0, attachmentName: "image.png")]
        let attachmentPreviews = UITestAttachmentPreviewItemEntry(items: capsules, extraItemsCount: nil)

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.hasAttachmentPreviewEntries(index: 0, entries: attachmentPreviews)
        }
    }

    /// TestId 448456
    func testAttachmentPreviewCountFiltersOutInlineImages() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_448456.json",
                ignoreQueryParams: true
            )
        )

        let capsules = [
            UITestAttachmentPreviewCapsuleItemEntry(index: 0, attachmentName: "zipfile.zip"),
            UITestAttachmentPreviewCapsuleItemEntry(index: 1, attachmentName: "fifth.png"),
        ]
        let attachmentPreviews = UITestAttachmentPreviewItemEntry(items: capsules, extraItemsCount: 5)

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.hasAttachmentPreviewEntries(index: 0, entries: attachmentPreviews)
        }
    }

    /// TestId 448457
    func testAttachmentPreviewCountOnConversationWithMultipleMessages() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_448457.json",
                ignoreQueryParams: true
            )
        )

        let capsules = [
            UITestAttachmentPreviewCapsuleItemEntry(index: 0, attachmentName: "zip_conv.zip"),
            UITestAttachmentPreviewCapsuleItemEntry(index: 1, attachmentName: "zip_rep.zip"),
        ]
        let attachmentPreviews = UITestAttachmentPreviewItemEntry(items: capsules, extraItemsCount: 7)

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.hasAttachmentPreviewEntries(index: 0, entries: attachmentPreviews)
        }
    }

    /// TestId 448458
    /// To be re-enabled when ET-927 is addressed.
    func skip_testAttachmentPreviewMultipleCountFiltersASCAndICSFiles() async {
        await environment.mockServer.addRequestsWithDefaults(
            NetworkRequest(
                method: .get,
                remotePath: "/mail/v4/conversations",
                localPath: "conversations_448458.json",
                ignoreQueryParams: true
            )
        )

        let capsules = [
            UITestAttachmentPreviewCapsuleItemEntry(index: 0, attachmentName: "zip_conv.zip"),
            UITestAttachmentPreviewCapsuleItemEntry(index: 1, attachmentName: "zip_rep.zip"),
        ]
        let attachmentPreviews = UITestAttachmentPreviewItemEntry(items: capsules, extraItemsCount: 1)

        navigator.navigateTo(UITestDestination.inbox)

        MailboxRobot {
            $0.hasAttachmentPreviewEntries(index: 0, entries: attachmentPreviews)
        }
    }
}
