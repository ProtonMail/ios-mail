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

import SwiftUI

extension Color {

    /// Use in UIKit components inside `UIViewControllerRepresentable` to ensure dynamic colours updates
    var toDynamicUIColor: UIColor {
        UIColor { traits in
            /**
             Referencing `userInterfaceStyle` is the only hack I found to fix all dynamic colours problems in UIKit. Without
             this some user actions break the dynamic colours, for example, while being at the composer:
             1. switching to another app and back
             2. changing the color mode from a shortcut in Control Center
             */
            let _ = traits.userInterfaceStyle
            return UIColor(self)
        }
    }
}
