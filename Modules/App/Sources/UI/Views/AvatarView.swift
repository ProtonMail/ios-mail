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

enum AvatarViewType {
    case sender(params: SenderImageDataParameters)
    case other

    var senderImageDataParameters: SenderImageDataParameters? {
        switch self {
        case .sender(let params):
            return params
        case .other:
            return nil
        }
    }

    var isSender: Bool {
        switch self {
        case .sender:
            return true
        case .other:
            return false
        }
    }
}

struct AvatarView: View {
    let avatar: AvatarUIModel

    var body: some View {
        if let senderParams = avatar.type.senderImageDataParameters {
            AsyncSenderImageView(senderImageParams: senderParams) { senderImage in
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
    let avatarUIModel1 = AvatarUIModel(
        info: .init(initials: "Gh", color: .cyan),
        type: .sender(params: senderParams)
    )
    let avatarUIModel2 = AvatarUIModel(
        info: .init(initials: "Aa", color: DS.Color.Brand.norm),
        type: .sender(params: senderParams)
    )
    let avatarUIModel3 = AvatarUIModel(
        info: .init(initials: "Ad", color: DS.Color.Brand.norm),
        type: .sender(params: senderParams)
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
