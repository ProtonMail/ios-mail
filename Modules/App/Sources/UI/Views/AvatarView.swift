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

import InboxCore
import InboxDesignSystem
import SwiftUI

struct AvatarView: View {
    let avatar: AvatarUIModel

    var body: some View {
        if let senderInfo = avatar.type.senderInfo {
            AsyncSenderImageView(senderImageParams: senderInfo.params) { senderImage in
                switch senderImage {
                case .empty:
                    initialsView
                case .image(let uiImage):
                    senderImageView(image: Image(uiImage: uiImage))
                }
            }
        } else {
            initialsView
        }
    }

    private func senderImageView(image: Image) -> some View {
        image
            .resizable()
            .accessibilityIdentifier(AvatarViewIdentifiers.avatarImage)
    }

    private var initialsView: some View {
        Text(avatar.info.initials)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(DS.Color.Global.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(avatar.info.color)
            .accessibilityIdentifier(AvatarViewIdentifiers.avatarText)
    }
}

private struct AvatarViewIdentifiers {
    static let avatarText = "avatar.text"
    static let avatarImage = "avatar.image"
}

#Preview {
    let senderParams = SenderImageDataParameters(address: "aaron@proton.me", displaySenderImage: true)
    let info = SenderInfo(params: senderParams, blocked: .no)
    let avatarUIModel1 = AvatarUIModel(
        info: .init(initials: "Gh", color: .cyan),
        type: .sender(info)
    )
    let avatarUIModel2 = AvatarUIModel(
        info: .init(initials: "Aa", color: DS.Color.Brand.norm),
        type: .sender(info)
    )
    let avatarUIModel3 = AvatarUIModel(
        info: .init(initials: "Ad", color: DS.Color.Brand.norm),
        type: .sender(info)
    )

    return VStack {
        AvatarView(avatar: avatarUIModel1)
            .square(size: 70)
        AvatarView(avatar: avatarUIModel2)
            .square(size: 70)
            .clipShape(Circle())
        AvatarView(avatar: avatarUIModel3)
            .square(size: 70)
            .clipShape(RoundedRectangle(cornerSize: .init(width: 20, height: 20)))
    }
}
