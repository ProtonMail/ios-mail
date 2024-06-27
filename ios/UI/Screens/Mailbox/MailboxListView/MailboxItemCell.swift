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

struct MailboxItemCell: View {
    @State private(set) var isPressed: Bool = false

    let uiModel: MailboxItemCellUIModel
    let isParentListSelectionEmpty: Bool
    let onEvent: (MailboxItemCellEvent) -> Void

    private var textColor: Color {
        uiModel.isRead ? DS.Color.Text.weak : DS.Color.Text.norm
    }

    private var labelLeadingPadding: CGFloat {
        uiModel.labelUIModel.isEmpty ? 0 : DS.Spacing.small
    }

    var body: some View {
        HStack(spacing: DS.Spacing.large) {
            avatarView
            mailboxItemContentView
        }
        .padding(.horizontal, DS.Spacing.large)
        .padding(.vertical, DS.Spacing.medium)
        .background(uiModel.isSelected || isPressed ? DS.Color.Background.secondary : DS.Color.Background.norm)
    }
}

extension MailboxItemCell {

    private var avatarView: some View {
        AvatarCheckboxView(
            isSelected: uiModel.isSelected,
            avatar: uiModel.avatar,
            onDidChangeSelection: { onEvent(.onSelectedChange(isSelected: $0)) }
        )
        .frame(width: 40, height: 40)
    }

    private var mailboxItemContentView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                senderRowView
                subjectRowView
                expirationRowView
                snoozedRowView
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onEvent(.onTap)
            }
            .onLongPressGesture(perform: {
                onEvent(.onLongPress)
            }, onPressingChanged: {
                guard isParentListSelectionEmpty else { return }
                isPressed = $0
            })

            attachmentRowView
        }
    }

    private var senderRowView: some View {
        HStack(spacing: DS.Spacing.small) {
            replyIcons
            Text(uiModel.senders)
                .font(.subheadline)
                .fontWeight(uiModel.isRead ? .regular : .bold)
                .lineLimit(1)
                .foregroundColor(textColor)
                .accessibilityIdentifier(MailboxItemCellIdentifiers.senderText)
            ProtonOfficialBadgeView()
                .removeViewIf(!uiModel.isSenderProtonOfficial)
            MailboxConversationMessageCountView(numMessages: uiModel.numMessages)
                .removeViewIf(uiModel.numMessages == 0)
            Spacer()
            Text(uiModel.date.mailboxFormat())
                .font(.caption2)
                .fontWeight(uiModel.isRead ? .regular : .bold)
                .foregroundColor(uiModel.isRead ? DS.Color.Text.hint : DS.Color.Text.norm)
                .accessibilityIdentifier(MailboxItemCellIdentifiers.dateText)
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
                .accessibilityIdentifier(MailboxItemCellIdentifiers.subjectText)
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
                .accessibilityIdentifier(MailboxItemCellIdentifiers.starIcon)
        }
        .frame(height: 21.0)
        .padding(.top, DS.Spacing.small)
    }

    @ViewBuilder
    private var replyIcons: some View {
        if uiModel.replyIcons.shouldShowIcon {
            HStack(spacing: DS.Spacing.tiny) {
                if uiModel.replyIcons.shouldShowRepliedIcon {
                    imageForReplyIcon(icon: DS.Icon.icReplay)
                }
                if uiModel.replyIcons.shouldShowRepliedAllIcon {
                    imageForReplyIcon(icon: DS.Icon.icReplayAll)
                }
                if uiModel.replyIcons.shouldShowForwardedIcon {
                    imageForReplyIcon(icon: DS.Icon.icForward)
                }
            }
        } else {
            EmptyView()
        }
    }

    private func imageForReplyIcon(icon: UIImage) -> some View {
        Image(uiImage: icon)
            .resizable()
            .frame(width: 16, height: 16)
            .foregroundColor(DS.Color.Text.weak)
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

        AttachmentsView(
            uiModel: uiModel.attachmentsUIModel,
            isAttachmentHighlightEnabled: isParentListSelectionEmpty,
            onTapEvent: {
                onEvent(.onAttachmentTap(attachmentId: $0))
            }
        )
        .padding(.top, DS.Spacing.standard)
        .removeViewIf(uiModel.attachmentsUIModel.isEmpty)
    }
}

@Observable
final class MailboxItemCellUIModel: Identifiable, Sendable {
    let id: PMMailboxItemId
    let conversationId: PMLocalConversationId
    let type: MailboxItemType
    let avatar: AvatarUIModel
    let senders: String
    let subject: String
    let date: Date
    
    let isRead: Bool
    let isStarred: Bool
    let isSelected: Bool

    let isSenderProtonOfficial: Bool
    let numMessages: UInt64
    let labelUIModel: MailboxLabelUIModel
    let attachmentsUIModel: [AttachmentCapsuleUIModel]
    let replyIcons: ReplyIconsUIModel

    let expirationDate: String?
    let snoozeDate: String?

    init(
        id: PMMailboxItemId,
        conversationId: PMLocalConversationId,
        type: MailboxItemType,
        avatar: AvatarUIModel,
        senders: String,
        subject: String,
        date: Date,
        isRead: Bool,
        isStarred: Bool,
        isSelected: Bool,
        isSenderProtonOfficial: Bool,
        numMessages: UInt64,
        labelUIModel: MailboxLabelUIModel = .init(),
        attachmentsUIModel: [AttachmentCapsuleUIModel] = [],
        replyIcons: ReplyIconsUIModel = .init(),
        expirationDate: Date?,
        snoozeDate: Date?
    ) {
        self.id = id
        self.conversationId = conversationId
        self.type = type
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
        self.replyIcons = replyIcons

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

extension MailboxItemCellUIModel: Hashable {
    static func == (lhs: MailboxItemCellUIModel, rhs: MailboxItemCellUIModel) -> Bool {
        lhs.type == rhs.type 
        && lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(type)
    }
}

struct ReplyIconsUIModel {
    let shouldShowRepliedIcon: Bool
    let shouldShowRepliedAllIcon: Bool
    let shouldShowForwardedIcon: Bool

    init(
        shouldShowRepliedIcon: Bool = false,
        shouldShowRepliedAllIcon: Bool = false,
        shouldShowForwardedIcon: Bool = false
    ) {
        self.shouldShowRepliedIcon = shouldShowRepliedIcon
        self.shouldShowRepliedAllIcon = shouldShowRepliedAllIcon
        self.shouldShowForwardedIcon = shouldShowForwardedIcon
    }

    var shouldShowIcon: Bool {
        shouldShowRepliedIcon || shouldShowRepliedAllIcon || shouldShowForwardedIcon
    }
}

enum MailboxItemCellEvent {
    case onTap
    case onLongPress
    case onSelectedChange(isSelected: Bool)
    case onStarredChange(isStarred: Bool)
    case onAttachmentTap(attachmentId: PMLocalAttachmentId)
}

#Preview {
    var model: MailboxItemCellUIModel {
        MailboxItemCellUIModel(
            id: 0,
            conversationId: 0,
            type: .conversation,
            avatar: .init(initials: "P", senderImageParams: .init()),
            senders: "Proton",
            subject: "30% discount on all our products",
            date: Date(),
            isRead: false,
            isStarred: false,
            isSelected: true,
            isSenderProtonOfficial: true,
            numMessages: 0,
            labelUIModel: .init(labelModels: [.init(labelId: 0, text: "New", color: .brown)]),
            expirationDate: nil,
            snoozeDate: nil
        )
    }

    return VStack {

        MailboxItemCell(uiModel: model, isParentListSelectionEmpty: true, onEvent: { _ in })

        MailboxItemCell(
            uiModel: .init(
                id: 0,
                conversationId: 0,
                type: .message,
                avatar: .init(initials: "FE", senderImageParams: .init(), backgroundColor: .yellow),
                senders: "FedEx",
                subject: "Your package is ready to ship",
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                isRead: false,
                isStarred: true,
                isSelected: false,
                isSenderProtonOfficial: false,
                numMessages: 3,
                labelUIModel: .init(labelModels: [LabelUIModel(labelId: 0, text: "Offer", color: .purple)]),
                attachmentsUIModel: [.init(attachmentId: 1, icon: DS.Icon.icFileTypeIconPdf, name: "#34JE3KLP.pdf")],
                replyIcons: .init(shouldShowForwardedIcon: true),
                expirationDate: .now,
                snoozeDate: .now + 500
            ),
            isParentListSelectionEmpty: true,
            onEvent: { _ in }
        )

        MailboxItemCell(
            uiModel: .init(
                id: 0,
                conversationId: 0,
                type: .message,
                avatar: .init(initials: "MA", senderImageParams: .init(), backgroundColor: .cyan),
                senders: "Mary, Elijah Wood, wiseman@pm.me",
                subject: "Summer holidays pictures and more!",
                date: Calendar.current.date(byAdding: .year, value: -1, to: Date())!,
                isRead: true,
                isStarred: true,
                isSelected: false,
                isSenderProtonOfficial: true,
                numMessages: 12,
                labelUIModel: MailboxLabelUIModel(
                    labelModels: [.init(labelId: 0, text: "Read later", color: .green)] + LabelUIModel.random(num: 3)),
                attachmentsUIModel: [
                    .init(attachmentId: 1, icon: DS.Icon.icFileTypeIconPdf, name: "today_meeting_minutes.doc"),
                    .init(attachmentId: 2, icon: DS.Icon.icFileTypeIconPdf, name: "appendix1.pdf"),
                    .init(attachmentId: 3, icon: DS.Icon.icFileTypeIconPdf, name: "appendix2.pdf"),
                ],
                replyIcons: .init(shouldShowRepliedAllIcon: true),
                expirationDate: .now + 500,
                snoozeDate: .now + 55000
            ),
            isParentListSelectionEmpty: true,
            onEvent: { _ in }
        )
    }
}

private struct MailboxItemCellIdentifiers {
    static let senderText = "cell.senderText"
    static let subjectText = "cell.subjectText"
    static let starIcon = "cell.starIcon"
    static let dateText = "cell.dateText"
}
