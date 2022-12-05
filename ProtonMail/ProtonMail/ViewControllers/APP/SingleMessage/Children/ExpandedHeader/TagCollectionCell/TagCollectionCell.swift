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

import ProtonCore_UIFoundations
import UIKit

final class TagCollectionCell: UICollectionViewCell {
    static let cellID = "TagCollectionCell"
    @IBOutlet private var tagView: UIView!
    @IBOutlet private var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        tagView.roundCorner(9)

        titleLabel.set(text: nil,
                       preferredFont: .caption1,
                       weight: .semibold,
                       textColor: ColorProvider.TextInverted)
    }

    func setup(backgroundColor: UIColor, title: String, titleColor: UIColor) {
        tagView.backgroundColor = backgroundColor
        titleLabel.text = title
        titleLabel.textColor = titleColor
        titleLabel.sizeToFit()
    }
}
