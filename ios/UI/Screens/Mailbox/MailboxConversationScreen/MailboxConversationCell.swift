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

struct MailboxConversationCell: View {
    let uiModel: MailboxConversationCellUIModel
    let onEvent: (MailboxConversationCellEvent) -> Void

    private var textColor: Color {
        uiModel.isRead ? DS.Color.textWeak : DS.Color.textNorm
    }

    private var labelLeadingPadding: CGFloat {
        uiModel.labelUIModel.isEmpty ? 0 : 4
    }

    var body: some View {
        HStack(spacing: 16.0) {

            AvatarCheckboxView(
                isSelected: uiModel.isSelected,
                onDidChangeSelection: { onEvent(.onSelectedChange(isSelected: $0)) }
            )
            .frame(width: 40, height: 40)

            VStack(spacing: 2) {

                HStack {

                    Text(uiModel.senders)
                        .font(.subheadline)
                        .lineLimit(1)
                        .bold(!uiModel.isRead)
                        .foregroundColor(textColor)
                    ProtonOfficialBadgeView()
                        .removeViewIf(!uiModel.isSenderProtonOfficial)
                    MailboxConversationMessageCountView(numMessages: uiModel.numMessages)
                        .removeViewIf(uiModel.numMessages == 0)
                    Spacer()
                    Text(uiModel.date.mailboxFormat())
                        .font(.footnote)
                        .bold(!uiModel.isRead)
                        .foregroundColor(textColor)
                }

                HStack(spacing: 0) {

                    Text(uiModel.subject)
                        .font(.callout)
                        .lineLimit(1)
                        .bold(!uiModel.isRead)
                        .foregroundColor(textColor)
                        .layoutPriority(1)
                    MailboxLabelView(uiModel: uiModel.labelUIModel)
                        .padding(.leading, labelLeadingPadding)
                    Spacer()
                    Image(uiImage: uiModel.isStarred ? DS.Icon.icStarFilled : DS.Icon.icStar)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundColor(uiModel.isStarred ? .yellow : DS.Color.textWeak)
                        .onTapGesture {
                            onEvent(.onStarredChange(isStarred: !uiModel.isStarred))
                        }
                }

                Text(uiModel.expirationDate.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(uiModel.expirationDate.color)
                    .font(.callout)
                    .fontWeight(.regular)
                    .removeViewIf(uiModel.expirationDate.text.isEmpty)

                AttachmentsView(uiModel: uiModel.attachmentsUIModel, onTapEvent: {
                    onEvent(.onAttachmentTap(attachmentId: $0))
                })
                .removeViewIf(uiModel.attachmentsUIModel.isEmpty)
            }
        }
        .padding(14)
        .background(uiModel.isSelected ? DS.Color.backgroundSecondary : Color(UIColor.systemBackground))
    }
}

struct ExpirationDateUIModel {
    let text: String
    let color: Color
}

@Observable
final class MailboxConversationCellUIModel: Identifiable {
    let id: String
    let avatarImage: URL
    let senders: String
    let subject: String
    let date: Date
    
    let isRead: Bool
    let isStarred: Bool
    var isSelected: Bool = false

    let isSenderProtonOfficial: Bool
    let numMessages: Int
    let labelUIModel: MailboxLabelUIModel
    let attachmentsUIModel: [AttachmentCapsuleUIModel]

    let expirationDate: ExpirationDateUIModel

    init(
        id: String,
        avatarImage: URL,
        senders: String,
        subject: String,
        date: Date,
        isRead: Bool,
        isStarred: Bool,
        isSenderProtonOfficial: Bool,
        numMessages: Int,
        labelUIModel: MailboxLabelUIModel = .init(),
        attachmentsUIModel: [AttachmentCapsuleUIModel] = [],
        expirationDate: ExpirationDateUIModel
    ) {
        self.id = id
        self.avatarImage = avatarImage
        self.senders = senders
        self.subject = subject
        self.date = date
        self.isRead = isRead
        self.isStarred = isStarred
        self.isSenderProtonOfficial = isSenderProtonOfficial
        self.numMessages = numMessages
        self.labelUIModel = labelUIModel
        self.attachmentsUIModel = attachmentsUIModel
        self.expirationDate = expirationDate
    }
}

enum MailboxConversationCellEvent {
    case onSelectedChange(isSelected: Bool)
    case onStarredChange(isStarred: Bool)
    case onAttachmentTap(attachmentId: String)
}

#Preview {
    var model: MailboxConversationCellUIModel {
        MailboxConversationCellUIModel(
            id: "",
            avatarImage: URL(string: "https://proton.me")!,
            senders: "Proton",
            subject: "30% discount on all our products",
            date: Date(),
            isRead: false,
            isStarred: false,
            isSenderProtonOfficial: true,
            numMessages: 0,
            labelUIModel: .init(),
            expirationDate: .init(text: "Expires in < 5 minutes", color: DS.Color.notificationError)
        )
    }
    let model1 = model
    model1.isSelected = true

    return VStack {

        MailboxConversationCell(uiModel: model, onEvent: { _ in })
        MailboxConversationCell(uiModel: model1, onEvent: { _ in })

        MailboxConversationCell(
            uiModel: .init(
                id: "",
                avatarImage: URL(string: "https://proton.me")!,
                senders: "FedEx",
                subject: "Your package is ready to ship",
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                isRead: false,
                isStarred: true,
                isSenderProtonOfficial: false,
                numMessages: 3,
                labelUIModel: .init(id: "", color: .purple, text: "Offer", numExtraLabels: 0),
                attachmentsUIModel: [.init(attachmentId: UUID().uuidString, icon: DS.Icon.icFileTypeIconPdf, name: "#34JE3KLP.pdf")],
                expirationDate: .init(text: "", color: .clear)
            ),
            onEvent: { _ in }
        )

        MailboxConversationCell(
            uiModel: .init(
                id: "",
                avatarImage: URL(string: "https://proton.me")!,
                senders: "Mary, Elijah Wood, wiseman@pm.me",
                subject: "Summer holidays pictures and more!",
                date: Calendar.current.date(byAdding: .year, value: -1, to: Date())!,
                isRead: true,
                isStarred: true,
                isSenderProtonOfficial: true,
                numMessages: 12,
                labelUIModel: .init(id: "", color: .green, text: "Read later", numExtraLabels: 2),
                attachmentsUIModel: [
                    .init(attachmentId: UUID().uuidString, icon: DS.Icon.icFileTypeIconPdf, name: "today_meeting_minutes.doc"),
                    .init(attachmentId: UUID().uuidString, icon: DS.Icon.icFileTypeIconPdf, name: "appendix1.pdf"),
                    .init(attachmentId: UUID().uuidString, icon: DS.Icon.icFileTypeIconPdf, name: "appendix2.pdf"),
                ],
                expirationDate: .init(text: "", color: .clear)
            ),
            onEvent: { _ in }
        )
    }
}
