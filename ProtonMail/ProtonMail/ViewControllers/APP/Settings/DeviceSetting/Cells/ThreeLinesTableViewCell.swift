// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import ProtonCore_UIFoundations
import UIKit

@IBDesignable class ThreeLinesTableViewCell : UITableViewCell {
    static var CellID: String {
        return "\(self)"
    }
    
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var middleLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    @IBOutlet var icon: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        let parentView: UIView = self.contentView

        self.topLabel.textColor = ColorProvider.TextNorm
        self.topLabel.font = UIFont.systemFont(ofSize: 17)
        self.topLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.topLabel.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 16),
            self.topLabel.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 44)
        ])

        self.middleLabel.textColor = ColorProvider.TextWeak
        self.middleLabel.font = UIFont.systemFont(ofSize: 14)
        self.middleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.middleLabel.topAnchor.constraint(equalTo: self.topLabel.bottomAnchor, constant: 8),
            self.middleLabel.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16),
            self.middleLabel.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -56)
        ])

        self.bottomLabel.textColor = ColorProvider.TextWeak
        self.bottomLabel.font = UIFont.systemFont(ofSize: 14)
        self.bottomLabel.translatesAutoresizingMaskIntoConstraints = false
        self.bottomLabel.numberOfLines = 0
        NSLayoutConstraint.activate([
            self.bottomLabel.topAnchor.constraint(equalTo: self.middleLabel.bottomAnchor, constant: 8),
            self.bottomLabel.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16),
            self.bottomLabel.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -56)
        ])

        self.icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.icon.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 19),
            self.icon.leftAnchor.constraint(equalTo: parentView.leftAnchor, constant: 18.5),
            self.icon.widthAnchor.constraint(equalToConstant: 18),
            self.icon.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    func configCell(_ topLine: String, _ middleLine: NSMutableAttributedString, _ bottomLine: NSMutableAttributedString, _ icon: UIImage) {
        topLabel.text = topLine
        middleLabel.attributedText = middleLine
        bottomLabel.attributedText = bottomLine

        self.icon.setImage(icon)

        self.layoutIfNeeded()
    }
}

extension ThreeLinesTableViewCell: IBDesignableLabeled {
    override func prepareForInterfaceBuilder() {
        self.labelAtInterfaceBuilder()
    }
}
