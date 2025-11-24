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

import InboxDesignSystem
import SwiftUI

extension MailboxItemCellUIModel {
    static let proton1 = makeModel(subject: "30% discount on all our products", isFromProton: true)
    static let proton2 = makeModel(subject: "sales up to 50%", isFromProton: true)

    static func testData() -> [MailboxItemCellUIModel] {
        [proton1] + MailboxItemCellUIModel.emailSubjects.map { makeModel(subject: $0) } + [proton2]
    }
}

private extension MailboxItemCellUIModel {

    static var randomColor: Color {
        [.green, .red, .green, .orange].randomElement()!
    }

    static var randomSender: String {
        ["Sophie Price, Dustin M., Johanna", "john@proton.me", "lauren@gmail.com, Anna"].randomElement()!
    }

    enum Attachment {
        static func randomAttachment() -> [AttachmentCapsuleUIModel] {
            if [false, false, Bool.random()].randomElement()! {
                [
                    [
                        AttachmentCapsuleUIModel(id: .init(value: 1), icon: DS.Icon.icFileTypeIconPdf, name: "#34JE3KLP.pdf"),
                        AttachmentCapsuleUIModel(id: .init(value: 2), icon: DS.Icon.icFileTypeIconWord, name: "meeting_minutes.doc"),
                        AttachmentCapsuleUIModel(id: .init(value: 1), icon: DS.Icon.icFileTypeIconExcel, name: "ARR_Q2.xls"),
                    ].randomElement()!
                ]
            } else {
                []
            }
        }
    }

    enum Avatar {
        static let j = AvatarUIModel(
            info: AvatarInfo(initials: "J", color: .indigo),
            type: .sender(.init(params: .init(), blocked: .no))
        )
        static let l = AvatarUIModel(
            info: AvatarInfo(initials: "L", color: .mint),
            type: .sender(.init(params: .init(), blocked: .no))
        )
        static let s = AvatarUIModel(
            info: AvatarInfo(initials: "S", color: .cyan),
            type: .sender(.init(params: .init(), blocked: .no))
        )

        static func randomAvatar() -> AvatarUIModel {
            return [j, l, s].randomElement()!
        }
    }

    enum Label {
        static let work = LabelUIModel(labelId: .init(value: 0), text: "Work", color: randomColor)
        static let readLater = LabelUIModel(labelId: .init(value: 0), text: "read later", color: randomColor)

        static func randomLabels() -> [LabelUIModel] {
            Bool.random()
                ? [[work, readLater].randomElement()!] + LabelUIModel.random(num: [0, 1, 2].randomElement()!)
                : []
        }
    }

    static func makeModel(subject: String, isFromProton: Bool = false) -> MailboxItemCellUIModel {
        let avatar =
            isFromProton
            ? .init(
                info: .init(initials: "P", color: .purple),
                type: .sender(.init(params: .init(), blocked: .notLoaded))
            )
            : Avatar.randomAvatar()

        return MailboxItemCellUIModel(
            id: .random(),
            conversationID: .random(),
            type: .conversation,
            avatar: avatar,
            emails: isFromProton ? "Proton" : randomSender,
            subject: subject,
            date: Date(),
            location: nil,
            locationIcon: nil,
            isRead: Bool.random(),
            isStarred: Bool.random(),
            isSelected: [false, false, Bool.random()].randomElement()!,
            isSenderProtonOfficial: isFromProton,
            messagesCount: [0, 2, 3].randomElement()!,
            labelUIModel: .init(labelModels: Label.randomLabels()),
            attachments: .init(
                previewables: Attachment.randomAttachment(),
                containsCalendarInvitation: false,
                totalCount: 4
            ),
            expirationDate: nil,
            snoozeDate: nil,
            isDraftMessage: false,
            shouldUseSnoozedColorForDate: false
        )
    }

    static let emailSubjects: [String] = [
        "Weekly Team Sync – Agenda Attached",
        "Unlock 25% Off Your Next Order – Limited Time!",
        "Happy Birthday! 🎉",
        "Follow-Up on the Budget Meeting",
        "Update: Project Milestones for Q4",
        "Can You Help Me with This Weekend’s Move?",
        "Re: Let’s Plan Our Summer Vacation",
        "Thanks for the Gift! I Loved It 😊",
        "Reminder: Client Presentation Tomorrow at 10 AM",
        "Early Access Just for You – Shop New Arrivals",
        "Can You Review the Proposal Before End of Day?",
        "Re: Questions About the Marketing Campaign",
        "Request for Approval – New Vendor Agreement",
        "FYI: Important Changes to Our Remote Work Policy",
        "Invitation: Monthly All-Hands Meeting",
        "Team Lunch on Friday – RSVP Required",
        "Action Required: Complete Your Training by Friday",
        "Here’s the Latest Draft – Please Review",
        "Performance Review Scheduling – Pick Your Time Slot",
        "Can’t Wait to Hear About Your Trip! Coffee Soon?",
        "Are You Available for a Quick Call This Afternoon?",
        "Re: Your Feedback on the Product Launch Strategy",
        "Update on the IT System Outage – All Systems Restored",
        "Please Share Your Thoughts on the New Design",
        "Minutes from Today's Meeting – Action Items",
        "It Was Great Seeing You Last Night!",
        "Let’s Set a Time to Catch Up Soon",
        "Out of Office Next Week – Contact Info Inside",
        "Join Us for a Free Webinar – Register Today",
        "Limited-Time Offer – Buy One, Get One Free",
        "Final Deadline Reminder: Submit Your Timesheets",
        "Are We Still On for Dinner This Weekend?",
        "Just Checking In – How Are Things Going?",
        "Long Time No Talk – Let’s Catch Up Soon!",
        "Here Are the Photos from Last Weekend’s Trip",
        "Get Ready for Our Black Friday Deals!",
        "Congrats on Your New Job! Let’s Celebrate!",
        "Hey, I’m in Town Next Week – Let’s Meet Up!",
        "Do You Have a Moment to Chat Tomorrow?",
        "I Wanted to Share Some Good News with You",
        "Don’t Miss Out! Exclusive Offer for You",
        "Here’s That Recipe I Mentioned to You",
        "Quick Question – Do You Have the Notes from Class?",
        "Re: Thanks for Helping Me Out Yesterday",
        "Special Invite: VIP Sale Event This Weekend",
        "Your 50% Off Coupon Expires Tonight!",
        "What Time Should I Pick You Up on Saturday?",
        "Looking Forward to Seeing You This Weekend",
        "Thanks for Being a Loyal Customer – Enjoy 10% Off",
        "Only a Few Hours Left – Final Sale Ends Soon!",
    ]

}
