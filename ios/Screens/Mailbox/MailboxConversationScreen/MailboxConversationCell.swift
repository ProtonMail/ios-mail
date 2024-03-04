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
        uiModel.isRead ? MailColor.textWeak : MailColor.textNorm
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
                    Spacer()
                    Text(uiModel.date.formatted(date: .long, time: .omitted))
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
                    Image(uiImage: uiModel.isStarred ? MailIcon.icStarFilled : MailIcon.icStar)
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundColor(uiModel.isStarred ? .yellow : MailColor.textWeak)
                        .onTapGesture {
                            onEvent(.onStarredChange(isStarred: !uiModel.isStarred))
                        }
                }
            }

        }
        .padding(14)
        .background(uiModel.isSelected ? MailColor.backgroundSecondary : Color(UIColor.systemBackground))
    }
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

    let labelUIModel: MailboxLabelUIModel

    init(
        id: String,
        avatarImage: URL,
        senders: String,
        subject: String,
        date: Date,
        isRead: Bool,
        isStarred: Bool,
        labelUIModel: MailboxLabelUIModel = .init()
    ) {
        self.id = id
        self.avatarImage = avatarImage
        self.senders = senders
        self.subject = subject
        self.date = date
        self.isRead = isRead
        self.isStarred = isStarred
        self.labelUIModel = labelUIModel
    }
}

enum MailboxConversationCellEvent {
    case onSelectedChange(isSelected: Bool)
    case onStarredChange(isStarred: Bool)
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
            labelUIModel: .init()
        )
    }
    var model1 = model
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
                date: Date(),
                isRead: false,
                isStarred: true,
                labelUIModel: .init(id: "", labelColor: .purple, text: "Offer", textColor: .white, numExtraLabels: 0)
            ),
            onEvent: { _ in }
        )

        MailboxConversationCell(
            uiModel: .init(
                id: "",
                avatarImage: URL(string: "https://proton.me")!,
                senders: "Mary, Elijah Wood, wiseman@pm.me",
                subject: "Summer holidays pictures and more!",
                date: Date(),
                isRead: true,
                isStarred: true,
                labelUIModel: .init(id: "", labelColor: .green, text: "Read later", textColor: .white, numExtraLabels: 2)
            ),
            onEvent: { _ in }
        )
    }
}
