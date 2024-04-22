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
        uiModel.isRead ? DS.Color.Text.weak : DS.Color.Text.norm
    }

    private var labelLeadingPadding: CGFloat {
        uiModel.labelUIModel.isEmpty ? 0 : DS.Spacing.small
    }

    var body: some View {
        HStack(spacing: DS.Spacing.large) {
            avatarView
            VStack(spacing: 0) {
                senderRowView
                subjectRowView
                expirationRowView
                snoozedRowView
                attachmentRowView
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onEvent(.onTap)
        }
        .padding(.horizontal, DS.Spacing.large)
        .padding(.vertical, DS.Spacing.medium)
        .background(uiModel.isSelected ? DS.Color.Background.secondary : DS.Color.Background.norm)
    }
}

extension MailboxConversationCell {

    private var avatarView: some View {
        AvatarCheckboxView(
            isSelected: uiModel.isSelected,
            avatar: uiModel.avatar,
            onDidChangeSelection: { onEvent(.onSelectedChange(isSelected: $0)) }
        )
        .frame(width: 40, height: 40)
    }

    private var senderRowView: some View {
        HStack(spacing: DS.Spacing.small) {
            Text(uiModel.senders)
                .font(.subheadline)
                .fontWeight(uiModel.isRead ? .regular : .bold)
                .lineLimit(1)
                .foregroundColor(textColor)
            ProtonOfficialBadgeView()
                .removeViewIf(!uiModel.isSenderProtonOfficial)
            MailboxConversationMessageCountView(numMessages: uiModel.numMessages)
                .removeViewIf(uiModel.numMessages == 0)
            Spacer()
            Text(uiModel.date.mailboxFormat())
                .font(.caption2)
                .fontWeight(uiModel.isRead ? .regular : .bold)
                .foregroundColor(uiModel.isRead ? DS.Color.Text.hint : DS.Color.Text.norm)
        }
    }

    private var subjectRowView: some View {
        HStack(spacing: DS.Spacing.small) {
            Text(uiModel.subject)
                .font(DS.Font.body3)
                .fontWeight(uiModel.isRead ? .regular : .bold)
                .lineLimit(1)
                .foregroundColor(textColor)
                .layoutPriority(1)
            MailboxLabelView(uiModel: uiModel.labelUIModel)
                .padding(.leading, labelLeadingPadding)
                .removeViewIf(uiModel.labelUIModel.isEmpty)
            Spacer()
            Image(uiImage: uiModel.isStarred ? DS.Icon.icStarFilled : DS.Icon.icStar)
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundColor(uiModel.isStarred ? DS.Color.Star.selected : DS.Color.Star.default)
                .onTapGesture {
                    onEvent(.onStarredChange(isStarred: !uiModel.isStarred))
                }
        }
        .frame(height: 21.0)
        .padding(.top, DS.Spacing.small)
    }

    private var expirationRowView: some View {

        Text(uiModel.expirationDate ?? "")
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(DS.Color.Text.weak)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, DS.Spacing.small)
            .removeViewIf(uiModel.expirationDate == nil)
    }

    private var snoozedRowView: some View {

        Text(uiModel.snoozeDate ?? "")
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(DS.Color.Notification.warning)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, DS.Spacing.small)
            .removeViewIf(uiModel.snoozeDate == nil)
    }

    private var attachmentRowView: some View {

        AttachmentsView(uiModel: uiModel.attachmentsUIModel, onTapEvent: {
            onEvent(.onAttachmentTap(attachmentId: $0))
        })
        .padding(.top, DS.Spacing.standard)
        .removeViewIf(uiModel.attachmentsUIModel.isEmpty)
    }
}

@Observable
final class MailboxConversationCellUIModel: Identifiable, Sendable {
    let id: PMLocalConversationId
    let avatar: AvatarUIModel
    let senders: String
    let subject: String
    let date: Date
    
    let isRead: Bool
    let isStarred: Bool
    let isSelected: Bool

    let isSenderProtonOfficial: Bool
    let numMessages: Int
    let labelUIModel: MailboxLabelUIModel
    let attachmentsUIModel: [AttachmentCapsuleUIModel]

    let expirationDate: String?
    let snoozeDate: String?

    init(
        id: PMLocalConversationId,
        avatar: AvatarUIModel,
        senders: String,
        subject: String,
        date: Date,
        isRead: Bool,
        isStarred: Bool,
        isSelected: Bool,
        isSenderProtonOfficial: Bool,
        numMessages: Int,
        labelUIModel: MailboxLabelUIModel = .init(),
        attachmentsUIModel: [AttachmentCapsuleUIModel] = [],
        expirationDate: Date?,
        snoozeDate: Date?
    ) {
        self.id = id
        self.avatar = avatar
        self.senders = senders
        self.subject = subject
        self.date = date
        self.isRead = isRead
        self.isStarred = isStarred
        self.isSelected = isSelected
        self.isSenderProtonOfficial = isSenderProtonOfficial
        self.numMessages = numMessages
        self.labelUIModel = labelUIModel
        self.attachmentsUIModel = attachmentsUIModel

        var expiration: String? = nil
        if let expirationDate, expirationDate > .now {
            expiration = LocalizationTemp
                .MailboxCell
                .expiresIn(value: expirationDate.localisedRemainingTimeFromNow())
        }
        self.expirationDate = expiration

        var snoozeTime: String? = nil
        if let snoozeDate {
            snoozeTime = LocalizationTemp
                .MailboxCell
                .snoozedTill(value: snoozeDate.mailboxSnoozeFormat())
        }
        self.snoozeDate = snoozeTime
    }
}

enum MailboxConversationCellEvent {
    case onTap
    case onSelectedChange(isSelected: Bool)
    case onStarredChange(isStarred: Bool)
    case onAttachmentTap(attachmentId: String)
}

#Preview {
    var model: MailboxConversationCellUIModel {
        MailboxConversationCellUIModel(
            id: 0,
            avatar: .init(initials: "P"),
            senders: "Proton",
            subject: "30% discount on all our products",
            date: Date(),
            isRead: false,
            isStarred: false,
            isSelected: true,
            isSenderProtonOfficial: true,
            numMessages: 0,
            labelUIModel: .init(id: "", color: .brown, text: "New", allLabelIds: .init()),
            expirationDate: nil,
            snoozeDate: nil
        )
    }

    return VStack {

        MailboxConversationCell(uiModel: model, onEvent: { _ in })

        MailboxConversationCell(
            uiModel: .init(
                id: 0,
                avatar: .init(initials: "FE"),
                senders: "FedEx",
                subject: "Your package is ready to ship",
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                isRead: false,
                isStarred: true,
                isSelected: false,
                isSenderProtonOfficial: false,
                numMessages: 3,
                labelUIModel: .init(id: "", color: .purple, text: "Offer", allLabelIds: .init()),
                attachmentsUIModel: [.init(attachmentId: UUID().uuidString, icon: DS.Icon.icFileTypeIconPdf, name: "#34JE3KLP.pdf")],
                expirationDate: .now,
                snoozeDate: .now + 500
            ),
            onEvent: { _ in }
        )

        MailboxConversationCell(
            uiModel: .init(
                id: 0,
                avatar: .init(initials: "MA"),
                senders: "Mary, Elijah Wood, wiseman@pm.me",
                subject: "Summer holidays pictures and more!",
                date: Calendar.current.date(byAdding: .year, value: -1, to: Date())!,
                isRead: true,
                isStarred: true,
                isSelected: false,
                isSenderProtonOfficial: true,
                numMessages: 12,
                labelUIModel: .init(id: "", color: .green, text: "Read later", allLabelIds: Set(arrayLiteral: 0, 1, 2)),
                attachmentsUIModel: [
                    .init(attachmentId: UUID().uuidString, icon: DS.Icon.icFileTypeIconPdf, name: "today_meeting_minutes.doc"),
                    .init(attachmentId: UUID().uuidString, icon: DS.Icon.icFileTypeIconPdf, name: "appendix1.pdf"),
                    .init(attachmentId: UUID().uuidString, icon: DS.Icon.icFileTypeIconPdf, name: "appendix2.pdf"),
                ],
                expirationDate: .now + 500,
                snoozeDate: .now + 55000
            ),
            onEvent: { _ in }
        )
    }
}
