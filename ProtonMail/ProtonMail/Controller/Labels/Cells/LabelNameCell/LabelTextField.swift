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

import UIKit

final class LabelTextField: UITextField {
    // By default, this UITextField inside a UITableViewCell has a top padding of 39, this cancels it
    private let standardPadding = UIEdgeInsets(top: -40, left: 16, bottom: 0, right: 0)

    override func awakeFromNib() {
        super.awakeFromNib()
        adjustsFontSizeToFitWidth = true
        if let defaultFont = FontManager.subHeadline[.font] as? UIFont {
            minimumFontSize = defaultFont.pointSize / 1.5
        }
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: standardPadding)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: standardPadding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: standardPadding)
    }
}
