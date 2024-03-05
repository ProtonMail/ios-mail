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

    static let sidebarScreenModel = SidebarScreenModel(items: [
        .init(id: UUID().uuidString, icon: MailIcon.icStar, text: "Inbox", badge: "3"),
        .init(id: UUID().uuidString, icon: MailIcon.icStar, text: "Draft", badge: nil),
        .init(id: UUID().uuidString, icon: MailIcon.icStar, text: "Sent", badge: nil),
        .init(id: UUID().uuidString, icon: MailIcon.icStar, text: "Starred", badge: "8"),
        .init(id: UUID().uuidString, icon: MailIcon.icStar, text: "Archive", badge: nil),
        .init(id: UUID().uuidString, icon: MailIcon.icStar, text: "Spam", badge: nil),
    ])

    static var mailboxConversationScreenModel: MailboxConversationScreenModel {

        let conversations: [MailboxConversationCellUIModel] = (1..<100).map { value in
            let randomSenderSubject = randomSenderSubject()
            return .init(
                id: UUID().uuidString,
                avatarImage: URL(fileURLWithPath: ""),
                senders: randomSenderSubject.0,
                subject: randomSenderSubject.1,
                date: Calendar.current.date(byAdding: .minute, value: -1 * (value*value*1005), to: Date())!,
                isRead: (value == 2 || value>5),
                isStarred: (value%6 == 0),
                isSenderProtonOfficial: (randomSenderSubject.0 == "Proton"),
                numMessages: [0, 1, 5, [0, 2, 14].randomElement()!].randomElement()!,
                labelUIModel: [0, 1, 2].randomElement()! == 0 ? mailboxLabels.randomElement()! : .init()
            )
        }
        return .init(conversations: conversations)
    }

    static let mailboxLabels: [MailboxLabelUIModel] = [
        .init(id: UUID().uuidString, labelColor: Color(hex: "179FD9"), text: "WORK", textColor: .white, numExtraLabels: [2, 3].randomElement()!),
        .init(id: UUID().uuidString, labelColor: Color(hex: "F78400"), text:  "Read later", textColor: .white, numExtraLabels: [0, 1].randomElement()!),
        .init(id: UUID().uuidString, labelColor: Color(hex: "3CBB3A"), text: "Newsletters", textColor: .white, numExtraLabels: 0),
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
