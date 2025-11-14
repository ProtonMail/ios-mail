// Copyright (c) 2025 Proton Technologies AG
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

import ProtonUIFoundations
import SwiftUI
import UIKit

extension SecureInput.Configuration {
    public static var `default`: Self {
        .init(font: nil, alignment: .left, placeholder: nil, keyboardType: .default, allowedCharacters: nil)
    }

    public static var pinSettingsInput: Self {
        .init(font: nil, alignment: .left, placeholder: nil, keyboardType: .numberPad, allowedCharacters: CharacterSet.decimalDigits)
    }

    static var pinLock: Self {
        .init(
            font: .font(textStyle: .title3, weight: .semibold),
            alignment: .center,
            placeholder: L10n.PINLock.pinInputPlaceholder,
            keyboardType: .numberPad,
            allowedCharacters: CharacterSet.decimalDigits
        )
    }
}
