// Copyright (c) 2022 Proton AG
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

import Foundation
import ProtonCore_UIFoundations
import UIKit

struct EncryptionIconStatus: Equatable {
    let iconColor: EncryptionIconColor
    let icon: UIImage
    let text: String
    let isPGPPinned: Bool
    let isNonePM: Bool
    let isInvalid: Bool
    let nonExisting: Bool

    init(iconColor: EncryptionIconColor,
         icon: UIImage,
         text: String,
         isPGPPinned: Bool = false,
         isNonePM: Bool = true,
         isInvalid: Bool = false,
         nonExisting: Bool = false) {
        self.iconColor = iconColor
        self.icon = icon
        self.text = text
        self.isPGPPinned = isPGPPinned
        self.isNonePM = isNonePM
        self.isInvalid = isInvalid
        self.nonExisting = nonExisting
    }

    var iconWithColor: UIImage? {
        return self.icon.maskWithColor(color: self.iconColor.color)
    }
}

enum EncryptionIconColor: Equatable {
    case black
    case blue
    case green
    case error

    var color: UIColor {
        switch self {
        case .black:
            return ColorProvider.IconNorm
        case .blue:
            return UIColor(red: 65, green: 144, blue: 199)
        case .green:
            return UIColor(red: 88, green: 204, blue: 171)
        case .error:
            return ColorProvider.NotificationError
        }
    }
}
