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
import struct proton_mail_uniffi.MessageAddress

struct AvatarUIModel {
    let initials: String
    let senderImage: UIImage?
    let senderImageParams: SenderImageDataParameters
    let backgroundColor: Color

    init(
        initials: String,
        senderImage: UIImage? = nil,
        senderImageParams: SenderImageDataParameters,
        backgroundColor: Color = DS.Color.Background.secondary
    ) {
        self.initials = initials
        self.senderImage = senderImage
        self.senderImageParams = senderImageParams
        self.backgroundColor = backgroundColor
    }
}

struct ExpirationDateUIModel {
    let text: String
    let color: Color
}
