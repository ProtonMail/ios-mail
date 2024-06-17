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

struct MessageDetailsView: View {
    @State private(set) var isHeaderCollapsed: Bool = true
    let uiModel: MessageDetailsUIModel
    let onTap: () -> Void

    private let messageDetailsLeftColumnWidth: CGFloat = 80

    var body: some View {
        VStack {
            headerView
            extendedDetailsView
                .removeViewIf(isHeaderCollapsed)
        }
        .padding(.horizontal, DS.Spacing.large)
    }
}

// MARK: Header

extension MessageDetailsView {

    private var headerView: some View {
        HStack(alignment: .top, spacing: 0) {
            AvatarCheckboxView(isSelected: false, avatar: uiModel.avatar, onDidChangeSelection: { _ in })
                .frame(width: 40, height: 40)
            VStack(spacing: DS.Spacing.small) {
                senderNameView
                senderAddressView
                recipientsView
            }
            .padding(.leading, DS.Spacing.large)

            Spacer()

            ZStack(alignment: .top) {
                headerActionsView
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }

    private var senderNameView: some View {
        HStack(spacing: DS.Spacing.compact) {
            Text(uiModel.sender.name)
                .font(DS.Font.body3)
                .fontWeight(.semibold)
                .lineLimit(1)
                .foregroundColor(DS.Color.Text.norm)
            ProtonOfficialBadgeView()
                .removeViewIf(!uiModel.isSenderProtonOfficial)
            Text(uiModel.date.mailboxFormat())
                .font(.caption)
                .foregroundColor(DS.Color.Text.hint)
            Spacer()
        }
    }

    private var senderAddressView: some View {
        HStack(spacing: DS.Spacing.small) {
            Text(uiModel.sender.address)
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(DS.Color.Text.weak)
            Spacer()
        }
    }

    private var recipientsView: some View {
        Button {
            withAnimation(.linear(duration: 0.0)) {
                isHeaderCollapsed.toggle()
            }
        } label: {
            HStack(spacing: DS.Spacing.small) {
                Text(uiModel.recipients.recipientsUIRepresentation)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(DS.Color.Text.weak)
                Image(uiImage: isHeaderCollapsed ?  DS.Icon.icChevronDown : DS.Icon.icChevronUp)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundColor(DS.Color.Icon.weak)
                Spacer()
            }
        }
    }

    private var headerActionsView: some View {
        HStack(alignment: .top) {
            Button(action: {}, label: {
                Image(uiImage: uiModel.isSingleRecipient ? DS.Icon.icReplay : DS.Icon.icReplayAll)
            })
            Button(action: {}, label: {
                Image(uiImage: DS.Icon.icThreeDotsHorizontal)
            })
        }
        .foregroundColor(DS.Color.Icon.weak)
    }

}

// MARK: Extended details

extension MessageDetailsView {

    private var extendedDetailsView: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.moderatelyLarge) {
            fromRow
            recipientRow(.to, recipients: uiModel.recipientsTo)
            recipientRow(.cc, recipients: uiModel.recipientsCc)
                .removeViewIf(uiModel.recipientsCc.isEmpty)
            recipientRow(.bcc, recipients: uiModel.recipientsBcc)
                .removeViewIf(uiModel.recipientsBcc.isEmpty)
            dateRow
//            locationRow
            labelRow
                .removeViewIf(uiModel.labels.isEmpty)
            otherRow
                .removeViewIf(uiModel.other.isEmpty)
        }
        .padding(DS.Spacing.medium)
        .overlay {
            RoundedRectangle(cornerSize: CGSize(width: DS.Radius.extraLarge, height: DS.Radius.extraLarge))
                .stroke(DS.Color.Border.strong)
        }
    }

    private var fromRow: some View {
        HStack(alignment: .top, spacing: DS.Spacing.small) {
            Text(LocalizationTemp.MessageDetails.from)
                .font(.caption)
                .foregroundStyle(DS.Color.Text.weak)
                .frame(width: messageDetailsLeftColumnWidth, alignment: .leading)

            VStack(alignment: .leading) {
                Text(uiModel.sender.name)
                    .font(.caption)
                    .foregroundStyle(DS.Color.Text.norm)
                Text(uiModel.sender.address)
                    .font(.caption)
                    .foregroundStyle(DS.Color.Text.accent)
//                Text(uiModel.sender.encryptionInfo)
//                    .font(.caption)
//                    .foregroundStyle(DS.Color.Text.weak)
            }

            Spacer()
        }
    }

    private func recipientRow(_ group: RecipientGroup, recipients: [MessageDetail.Recipient]) -> some View {
        HStack(alignment: .top, spacing: DS.Spacing.small) {
            Text(group.localisedText)
                .font(.caption)
                .foregroundStyle(DS.Color.Text.weak)
                .frame(width: messageDetailsLeftColumnWidth, alignment: .leading)

            VStack(alignment: .leading) {

                ForEach(recipients.indices, id:\.self) { index in
                    let recipient = recipients[index]
                    Text(recipient.name)
                        .font(.caption)
                        .foregroundStyle(DS.Color.Text.norm)
                    Text(recipient.address)
                        .font(.caption)
                        .foregroundStyle(DS.Color.Text.accent)
                }
            }

            Spacer()
        }
    }

    private var dateRow: some View {
        HStack(alignment: .top, spacing: DS.Spacing.small) {
            Text(LocalizationTemp.MessageDetails.date)
                .font(.caption)
                .foregroundStyle(DS.Color.Text.weak)
                .frame(width: messageDetailsLeftColumnWidth, alignment: .leading)

            Text(uiModel.date.messageDetailsFormat())
                .font(.caption)
                .foregroundStyle(DS.Color.Text.norm)

            Spacer()
        }
    }

    private var locationRow: some View {
        HStack(alignment: .center, spacing: DS.Spacing.small) {
            Text(LocalizationTemp.MessageDetails.location)
                .font(.caption)
                .foregroundStyle(DS.Color.Text.weak)
                .frame(width: messageDetailsLeftColumnWidth, alignment: .leading)

            CapsuleView(text: SystemFolderIdentifier.inbox.localisedName, color: DS.Color.Background.secondary, icon: SystemFolderIdentifier.inbox.icon, style: .attachment)

            Spacer()
        }
    }

    private var labelRow: some View {
        let capsules = uiModel.labels.map {
            CapsuleView(text: $0.text, color: $0.color, style: .label)
        }

        return HStack(alignment: .center, spacing: DS.Spacing.small) {
            Text(LocalizationTemp.MessageDetails.label)
                .font(.caption)
                .foregroundStyle(DS.Color.Text.weak)
                .frame(width: messageDetailsLeftColumnWidth, alignment: .leading)

            CapsuleCloudView(subviews: capsules, innerPadding: DS.Spacing.tiny)

            Spacer()
        }
    }

    private var otherRow: some View {
        HStack(alignment: .center, spacing: DS.Spacing.small) {
            Text(LocalizationTemp.MessageDetails.other)
                .font(.caption)
                .foregroundStyle(DS.Color.Text.weak)
                .frame(width: messageDetailsLeftColumnWidth, alignment: .leading)

            starCapsule

            Spacer()
        }
    }

    private var starCapsule: some View {
        CapsuleView(
            text: LocalizationTemp.Mailbox.starred,
            color: DS.Color.Background.secondary,
            icon: DS.Icon.icStarFilled,
            iconColor: DS.Color.Star.selected,
            style: .attachment
        )
    }

    private enum RecipientGroup {
        case to
        case cc
        case bcc

        var localisedText: String {
            switch self {
            case .to:
                LocalizationTemp.MessageDetails.to
            case .cc:
                LocalizationTemp.MessageDetails.cc
            case .bcc:
                LocalizationTemp.MessageDetails.bcc
            }
        }
    }
}

struct MessageDetailsUIModel {
    let avatar: AvatarUIModel
    let sender: MessageDetail.Sender
    let isSenderProtonOfficial: Bool
    var recipients: [MessageDetail.Recipient] {
        recipientsTo + recipientsCc + recipientsBcc
    }
    let recipientsTo: [MessageDetail.Recipient]
    let recipientsCc: [MessageDetail.Recipient]
    let recipientsBcc: [MessageDetail.Recipient]
    var isSingleRecipient: Bool {
        recipientsTo.count + recipientsCc.count + recipientsBcc.count == 1
    }
    let date: Date
    let location: MessageDetail.Location
    let labels: [LabelUIModel]
    let other: [MessageDetail.Other]
}

enum MessageDetail {

    struct Sender {
        let name: String
        let address: String
        let encryptionInfo: String
    }

    struct Recipient {
        let name: String
        let address: String
    }

    enum Location {
        case systemFolder(SystemFolderIdentifier)
        case customFolder(CustomFolder)
    }

    enum Other {
        case starred
        case pinned
    }
}

extension Array where Element == MessageDetail.Recipient {

    var recipientsUIRepresentation: String {
        let recipients = map(\.name).joined(separator: ", ")
        return "\(LocalizationTemp.MessageDetails.to) \(recipients)"
    }
}

#Preview {

    let messageDetails = MessageDetailsUIModel(
        avatar: .init(initials: "", senderImageParams: .init()),
        sender: .init(name: "Camila Hall", address: "camila.hall@protonmail.ch", encryptionInfo: "End to end encrypted and signed"),
        isSenderProtonOfficial: true,
        recipientsTo: [
            .init(name: "Me", address: "eric.norbert@protonmail.ch"),
        ],
        recipientsCc: [
            .init(name: "James Hayes", address: "james@proton.me"),
            .init(name: "Riley Scott", address: "scott375@gmail.com"),
            .init(name: "Layla Robinson", address: "layla.rob@protonmail.ch"),
        ],
        recipientsBcc: [
            .init(name: "Isabella Coleman", address: "isa_coleman@protonmail.com"),
        ],
        date: .now,
        location: .systemFolder(.inbox),
        labels: [
            .init(labelId: 1, text: "Friends and Holidays", color: .blue),
            .init(labelId: 2, text: "Work", color: .green),
            .init(labelId: 3, text: "Summer trip", color: .pink),
        ],
        other: [.starred, .pinned]
    )

    return MessageDetailsView(
        isHeaderCollapsed: false,
        uiModel: messageDetails
    ) {}
}
