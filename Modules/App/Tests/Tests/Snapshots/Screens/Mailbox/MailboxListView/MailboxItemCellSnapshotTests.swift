// Copyright (c) 2025 Proton Technologies AG
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
import InboxDesignSystem
import InboxTesting
import InboxSnapshotTesting

@MainActor
final class MailboxItemCellSnapshotTests: BaseTestCase {

    func testMailboxItemCell_conversationWithSimpleMessage_itLayoutsCorrectOnIphoneX() {
        let cell = MailboxItemCell.testCell(model: .makeSimpleMessage(type: .regular))
        assertSnapshotsOnIPhoneX(of: cell)
    }

    func testMailboxItemCell_conversationWithLocationIcon_itLayoutsCorrectOnIphoneX() {
        let cell = MailboxItemCell.testCell(model: .makeSimpleMessage(type: .locationIcon))
        assertSnapshotsOnIPhoneX(of: cell)
    }

    func testMailboxItemCell_conversationWithOneAttachment_andOneLabel_itLayoutsCorrectOnIphoneX() {
        let cell = MailboxItemCell.testCell(model: .oneAttachmentOneLabel)
        assertSnapshotsOnIPhoneX(of: cell)
    }

    func testMailboxItemCell_conversationWithOneICSAttachment_itLayoutsCorrectOnIphoneX() {
        let cell = MailboxItemCell.testCell(model: .oneICSAttachment(previewableAttachments: []))
        assertSnapshotsOnIPhoneX(of: cell)
    }

    func testMailboxItemCell_conversationWithTwoAttachmentsWithOneICS_itLayoutsCorrectOnIphoneX() {
        let cell = MailboxItemCell.testCell(model: .oneICSAttachment(
            previewableAttachments: [
                AttachmentCapsuleUIModel(id: .init(value: 1), icon: DS.Icon.icFileTypeIconPdf, name: "sample.pdf")
            ])
        )
        assertSnapshotsOnIPhoneX(of: cell)
    }

    func testMailboxItemCell_conversationWithManyAttachments_andManyLabels_itLayoutsCorrectOnIphoneX() {
        let cell = MailboxItemCell.testCell(model: .manyAttachmentsManyLabelsManyMessages)
        assertSnapshotsOnIPhoneX(of: cell)
    }

    func testMailboxItemCell_conversationWithSnoozedMessage_itLayoutsCorrectOnIphoneX() {
        let cell = MailboxItemCell.testCell(model: .makeSimpleMessage(type: .snoozed))
        assertSnapshotsOnIPhoneX(of: cell, precision: 0.98)
    }

    func testMailboxItemCell_conversationWithExpirationTimeMessage_itLayoutsCorrectOnIphoneX() {
        let cell = MailboxItemCell.testCell(model: .makeSimpleMessage(type: .expirationTime))
        assertSnapshotsOnIPhoneX(of: cell)
    }
}

private extension MailboxItemCell {
    static func testCell(model: MailboxItemCellUIModel) -> MailboxItemCell {
        MailboxItemCell(
            uiModel: model,
            isParentListSelectionEmpty: true,
            isSending: false,
            onEvent: { _ in }
        )
    }
}

private extension MailboxItemCellUIModel {

    enum SimpleMessageType {
        case regular
        case snoozed
        case expirationTime
        case locationIcon
    }

    static func makeSimpleMessage(type: SimpleMessageType) -> MailboxItemCellUIModel {
        let snoozeTime = Date(timeIntervalSince1970: 1878451200)
        let expirationTime = Date(timeIntervalSince1970: Date.now.timeIntervalSince1970 + 3600 * 24 * 365 * 2)
        return MailboxItemCellUIModel(
            id: .random(),
            conversationID: .random(),
            type: .conversation,
            avatar: AvatarUIModel(info: AvatarInfo(initials: "A", color: .teal), type: .sender(params: .init())),
            emails: "arya.lindt@example.com",
            subject: "Making the most of Safari",
            date: Date(timeIntervalSince1970: 1717485341),
            locationIcon: type == .locationIcon ? DS.Icon.icInbox.image : nil,
            isRead: false,
            isStarred: false,
            isSelected: false,
            isSenderProtonOfficial: false,
            messagesCount: 0,
            labelUIModel: .init(labelModels: []),
            attachments: .init(
                previewable: [],
                containsCalendarInvitation: false,
                totalCount: 0
            ),
            expirationDate: type == .expirationTime ? expirationTime : nil,
            snoozeDate: type == .snoozed ? snoozeTime : nil,
            isDraftMessage: false,
            shouldUseSnoozedColorForDate: false
        )
    }

    static var oneAttachmentOneLabel: MailboxItemCellUIModel {
        .init(
            id: .random(),
            conversationID: .random(),
            type: .conversation,
            avatar: AvatarUIModel(info: AvatarInfo(initials: "T", color: .teal), type: .sender(params: .init())),
            emails: "Travel",
            subject: "Your booking confirmation KL877N",
            date: Date(timeIntervalSince1970: 1717483827),
            locationIcon: nil,
            isRead: true,
            isStarred: false,
            isSelected: false,
            isSenderProtonOfficial: false,
            messagesCount: 0,
            labelUIModel: .init(labelModels: [LabelUIModel(labelId: .init(value: 0), text: "MeetUp", color: .green)]),
            attachments: .init(
                previewable: [
                    AttachmentCapsuleUIModel(
                        id: .init(value: 1),
                        icon: DS.Icon.icFileTypeIconPdf,
                        name: "#KL877N.pdf"
                    )
                ],
                containsCalendarInvitation: false,
                totalCount: 1
            ),
            expirationDate: nil,
            snoozeDate: nil,
            isDraftMessage: false,
            shouldUseSnoozedColorForDate: false
        )
    }

    static func oneICSAttachment(previewableAttachments: [AttachmentCapsuleUIModel]) -> MailboxItemCellUIModel {
        .init(
            id: .random(),
            conversationID: .random(),
            type: .conversation,
            avatar: AvatarUIModel(info: AvatarInfo(initials: "T", color: .teal), type: .sender(params: .init())),
            emails: "Flights to Palo Alto - 20th of September, 2025",
            subject: "You're invited to flight KCY877N",
            date: Date(timeIntervalSince1970: 1717484927),
            locationIcon: nil,
            isRead: true,
            isStarred: false,
            isSelected: false,
            isSenderProtonOfficial: false,
            messagesCount: 0,
            labelUIModel: .init(labelModels: []),
            attachments: .init(
                previewable: previewableAttachments,
                containsCalendarInvitation: true,
                totalCount: previewableAttachments.count + 1
            ),
            expirationDate: nil,
            snoozeDate: nil,
            isDraftMessage: false,
            shouldUseSnoozedColorForDate: false
        )
    }

    static var manyAttachmentsManyLabelsManyMessages: MailboxItemCellUIModel {
        .init(
            id: .random(),
            conversationID: .random(),
            type: .conversation,
            avatar: AvatarUIModel(info: AvatarInfo(initials: "J", color: .indigo), type: .sender(params: .init())),
            emails: "Jane Doe, Mike, Laureen Smith",
            subject: "Photos from Portugal",
            date: Date(timeIntervalSince1970: 1717484830),
            locationIcon: nil,
            isRead: true,
            isStarred: false,
            isSelected: false,
            isSenderProtonOfficial: false,
            messagesCount: 7,
            labelUIModel: .init(labelModels: [
                LabelUIModel(labelId: .init(value: 0), text: "Holidays", color: .pink),
                LabelUIModel(labelId: .init(value: 0), text: "Summer 24", color: .blue),
                LabelUIModel(labelId: .init(value: 0), text: "Friends", color: .orange),
            ]),
            attachments: .init(
                previewable: [
                    AttachmentCapsuleUIModel(id: .init(value: 1), icon: DS.Icon.icFileTypeIconImage, name: "DSC_001239.jpg"),
                    AttachmentCapsuleUIModel(id: .init(value: 2), icon: DS.Icon.icFileTypeIconImage, name: "DSC_001301.jpg"),
                    AttachmentCapsuleUIModel(id: .init(value: 3), icon: DS.Icon.icFileTypeIconImage, name: "DSC_001305.jpg"),
                ],
                containsCalendarInvitation: false,
                totalCount: 4
            ),
            expirationDate: nil,
            snoozeDate: nil,
            isDraftMessage: false,
            shouldUseSnoozedColorForDate: false
        )
    }

}
