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

import DesignSystem
import SwiftUI

enum PreviewData {

    static let sideBarScreenModel = SidebarScreenModel(systemFolders: [
        .init(id: UUID().uuidString, name: "Inbox", icon: DS.Icon.icStar, badge: "3", route: .mailbox(labelId: .inbox)),
        .init(id: UUID().uuidString, name: "Draft", icon: DS.Icon.icFile, badge: "", route: .mailbox(labelId: .draft)),
        .init(id: UUID().uuidString, name: "Sent", icon: DS.Icon.icPaperPlane, badge: "", route: .mailbox(labelId: .sent)),
        .init(id: UUID().uuidString, name: "Starred", icon: DS.Icon.icStar, badge: "8", route: .mailbox(labelId: .starred)),
        .init(id: UUID().uuidString, name: "Archive", icon: DS.Icon.icArchiveBox, badge: "", route: .mailbox(labelId: .archive)),
        .init(id: UUID().uuidString, name: "Spam", icon: DS.Icon.icFire, badge: "", route: .mailbox(labelId: .spam)),
        .init(id: UUID().uuidString, name: "Settings", icon: DS.Icon.icCogWheel, badge: "", route: .settings),
    ])

    static var mailboxConversations: [MailboxConversationCellUIModel] {

        let conversations: [MailboxConversationCellUIModel] = (1..<100).map { value in
            let randomSenderSubject = randomSenderSubject()
            let expirationDate: Bool = ((1..<11).randomElement()!%10) == 0
            return .init(
                id: UUID().uuidString,
                avatar: .init(initials: randomSenderSubject.0.prefix(2).uppercased()),
                senders: randomSenderSubject.0,
                subject: randomSenderSubject.1,
                date: Calendar.current.date(byAdding: .minute, value: -1 * (value*value*1005), to: Date())!,
                isRead: (value == 2 || value>5),
                isStarred: (value%6 == 0),
                isSenderProtonOfficial: (randomSenderSubject.0 == "Proton"),
                numMessages: [0, 1, 5, [0, 2, 14].randomElement()!].randomElement()!,
                labelUIModel: [0, 1, 2].randomElement()! == 0 ? mailboxLabels.randomElement()! : .init(),
                attachmentsUIModel: [0, 1, 2].randomElement()! == 0 ? attachments.randomElement()! : [],
                expirationDate: expirationDate ? .init(text: "Expires in < 5 minutes", color: DS.Color.notificationError) : .init(text: "", color: .clear)
            )
        }
        return conversations
    }

    static let mailboxLabels: [MailboxLabelUIModel] = [
        .init(id: UUID().uuidString, color: Color(hex: "179FD9"), text: "WORK", numExtraLabels: [2, 3].randomElement()!),
        .init(id: UUID().uuidString, color: Color(hex: "F78400"), text:  "Read later", numExtraLabels: [0, 1].randomElement()!),
        .init(id: UUID().uuidString, color: Color(hex: "3CBB3A"), text: "Newsletters", numExtraLabels: 0),
    ]

    static let attachments: [[AttachmentCapsuleUIModel]] = [
        [
            .init(attachmentId: UUID().uuidString, icon: DS.Icon.icFileTypeIconPdf, name: "today_meeting_minutes.doc"),
            .init(attachmentId: UUID().uuidString, icon: DS.Icon.icFileTypeIconPdf, name: "appendix1.pdf"),
            .init(attachmentId: UUID().uuidString, icon: DS.Icon.icFileTypeIconPdf, name: "appendix2.pdf"),
        ],
        [
            .init(attachmentId: UUID().uuidString, icon: DS.Icon.icFileTypeWord, name: "notes.doc")
        ],
        [
            .init(attachmentId: UUID().uuidString, icon: DS.Icon.icFileTypeNumbers, name: "number.xls"),
            .init(attachmentId: UUID().uuidString, icon: DS.Icon.icFileTypePowerpoint, name: "slides.ppt")
        ],
        [
            .init(attachmentId: UUID().uuidString, icon: DS.Icon.icFileTypeImage, name: "01.png"),
            .init(attachmentId: UUID().uuidString, icon: DS.Icon.icFileTypeImage, name: "02.png"),
            .init(attachmentId: UUID().uuidString, icon: DS.Icon.icFileTypeImage, name: "03.png"),
            .init(attachmentId: UUID().uuidString, icon: DS.Icon.icFileTypeImage, name: "04.png"),
            .init(attachmentId: UUID().uuidString, icon: DS.Icon.icFileTypeImage, name: "05.png"),
            .init(attachmentId: UUID().uuidString, icon: DS.Icon.icFileTypeImage, name: "06.png"),
        ],
    ]

    static func randomSenderSubject() -> (String, String) {
        [
            ("Proton", "Save up to 40% on our most popular plans"),
            ("Mike Smith", "Holidays in Greece!"),
            ("Proton", "Fundraiser end next Monday: Last chance to win a Lifetime account, rare usernames"),
            ("Emma Sands", "About today's meeting"),
            ("Brad, Monica Lenders, Elisabeth", "Beers at 7pm"),
            ("customersupport@example.com", "Ticket #6457234"),
            ("Proton", "Get more out of your inbox"),
        ].randomElement()!
    }
}
