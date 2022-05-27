// Copyright (c) 2021 Proton AG
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

import ProtonCore_UIFoundations
import UIKit

extension UIBarButtonItem {
    static func backBarButtonItem(target: Any?,
                                  action: Selector?) -> UIBarButtonItem {
        let topInset: CGFloat = -1
        let leftInset: CGFloat = -8
        return IconProvider.arrowLeft
            .toUIBarButtonItem(target: target,
                               action: action,
                               style: .plain,
                               tintColor: ColorProvider.TextNorm,
                               imageInsets: UIEdgeInsets(top: topInset, left: leftInset, bottom: .zero, right: .zero))
    }
}
