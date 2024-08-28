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

    static var mailboxConversations: [MailboxItemCellUIModel] {

        let conversations: [MailboxItemCellUIModel] = (1..<100).map { value in
            let randomSenderSubject = randomSenderSubject()
            let expirationDate: Bool = ((1..<11).randomElement()!%10) == 0
            let snoozeDate: Bool = ((1..<11).randomElement()!%10) == 0
            return .init(
                id: .random(),
                type: .conversation,
                avatar: .init(initials: randomSenderSubject.0.prefix(2).uppercased(), type: .sender(params: .init())),
                senders: randomSenderSubject.0,
                subject: randomSenderSubject.1,
                date: Calendar.current.date(byAdding: .minute, value: -1 * (value*value*1005), to: Date())!,
                isRead: (value == 2 || value>5),
                isStarred: (value%6 == 0),
                isSelected: false,
                isSenderProtonOfficial: (randomSenderSubject.0 == "Proton"),
                numMessages: [0, 1, 5, [0, 2, 14].randomElement()!].randomElement()!,
                labelUIModel: [0, 1, 2].randomElement()! == 0 ? mailboxLabels.randomElement()! : .init(),
                attachmentsUIModel: [0, 1, 2].randomElement()! == 0 ? attachments.randomElement()! : [],
                expirationDate: expirationDate ? .now + 1000 : nil,
                snoozeDate: snoozeDate ? .now + 5000 : nil
            )
        }
        return conversations
    }

    static let mailboxLabels: [MailboxLabelUIModel] = [
        MailboxLabelUIModel(
            labelModels: [.init(labelId: .init(value: 0), text: "Work", color: Color(hex: "179FD9"))]
            + LabelUIModel.random(num: [2, 3].randomElement()!)
        ),
        MailboxLabelUIModel(
            labelModels: [.init(labelId: .init(value: 0), text: "Read later", color: Color(hex: "F78400"))]
            + LabelUIModel.random(num: [2, 3].randomElement()!)
        ),
        MailboxLabelUIModel(
            labelModels: [.init(labelId: .init(value: 0), text: "Newsletters", color: Color(hex: "3CBB3A"))]
            + LabelUIModel.random(num: [2, 3].randomElement()!)
        )
    ]
    
    static let attachments: [[AttachmentCapsuleUIModel]] = [
        [
            .init(id: .init(value: 1), icon: DS.Icon.icFileTypeIconPdf, name: "today_meeting_minutes.doc"),
            .init(id: .init(value: 2), icon: DS.Icon.icFileTypeIconPdf, name: "appendix1.pdf"),
            .init(id: .init(value: 3), icon: DS.Icon.icFileTypeIconPdf, name: "appendix2.pdf"),
        ],
        [
            .init(id: .init(value: 4), icon: DS.Icon.icFileTypeIconWord, name: "notes.doc")
        ],
        [
            .init(id: .init(value: 5), icon: DS.Icon.icFileTypeIconNumbers, name: "number.xls"),
            .init(id: .init(value: 6), icon: DS.Icon.icFileTypeIconPowerPoint, name: "slides.ppt")
        ],
        [
            .init(id: .init(value: 7), icon: DS.Icon.icFileTypeIconImage, name: "01.png"),
            .init(id: .init(value: 8), icon: DS.Icon.icFileTypeIconImage, name: "02.png"),
            .init(id: .init(value: 9), icon: DS.Icon.icFileTypeIconImage, name: "03.png"),
            .init(id: .init(value: 10), icon: DS.Icon.icFileTypeIconImage, name: "04.png"),
            .init(id: .init(value: 11), icon: DS.Icon.icFileTypeIconImage, name: "05.png"),
            .init(id: .init(value: 12), icon: DS.Icon.icFileTypeIconImage, name: "06.png"),
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

    static let senderImage = ImageResource.avatarFedex
}

extension LabelUIModel {

    static func random(num: Int) -> [LabelUIModel] {
        (0..<num).map { _ in
            LabelUIModel(
                labelId: .random(),
                text: ["a", "b", "c"].randomElement()!,
                color: [Color.blue, .red, .green].randomElement()!
            )
        }
    }
}
