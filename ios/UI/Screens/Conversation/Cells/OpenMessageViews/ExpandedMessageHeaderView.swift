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

struct ExpandedMessageHeaderView: View {
    let uiModel: ExpandedMessageCellUIModel

    var body: some View {
        messageDataView
    }

    private var messageDataView: some View {
        HStack(alignment: .top) {
            HStack(spacing: DS.Spacing.large) {
                AvatarCheckboxView(isSelected: false, avatar: uiModel.avatar, onDidChangeSelection: { _ in })
                    .frame(width: 40, height: 40)
                VStack(spacing: DS.Spacing.small) {
                    senderRowView
                    senderPrivacyView
                    recipientsView
                }
                Spacer()
            }
            ZStack(alignment: .top) {
                headerActionsView
            }
        }
        .onTapGesture {

        }
        .padding(.horizontal, DS.Spacing.large)
    }

    private var senderRowView: some View {
        HStack(spacing: DS.Spacing.small) {
            Text(uiModel.sender)
                .font(DS.Font.body3)
                .fontWeight(.semibold)
                .lineLimit(1)
                .foregroundColor(DS.Color.Text.norm)
            Text(uiModel.date.mailboxFormat())
                .font(.caption)
                .foregroundColor(DS.Color.Text.hint)
            Spacer()
        }
    }

    private var senderPrivacyView: some View {
        HStack(spacing: DS.Spacing.small) {
            Text(uiModel.senderPrivacy)
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(DS.Color.Text.weak)
            Spacer()
        }
    }

    private var recipientsView: some View {
        HStack(spacing: DS.Spacing.small) {
            Text(uiModel.recipients)
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(DS.Color.Text.weak)
            Image(uiImage: DS.Icon.icChevronDown)
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundColor(DS.Color.Icon.weak)
            Spacer()
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
