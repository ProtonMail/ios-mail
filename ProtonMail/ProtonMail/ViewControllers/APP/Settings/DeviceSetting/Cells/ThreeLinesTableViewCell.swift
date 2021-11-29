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
    @IBOutlet weak var icon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.topLabel.textColor = ColorProvider.TextNorm
        self.topLabel.font = UIFont.systemFont(ofSize: 17)
        self.topLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.topLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 16),
            self.topLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -68),
            self.topLabel.widthAnchor.constraint(equalToConstant: 243),
            self.topLabel.heightAnchor.constraint(equalToConstant: 24),
            self.topLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 44),
            self.topLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -88)
        ])
        
        self.middleLabel.textColor = ColorProvider.TextWeak
        self.middleLabel.font = UIFont.systemFont(ofSize: 14)
        self.middleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.middleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 48),
            self.middleLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -40),
            self.middleLabel.widthAnchor.constraint(equalToConstant: 303),
            self.middleLabel.heightAnchor.constraint(equalToConstant: 20),
            self.middleLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 16),
            self.middleLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -56)
        ])
        
        self.bottomLabel.textColor = ColorProvider.TextWeak
        self.bottomLabel.font = UIFont.systemFont(ofSize: 14)
        self.bottomLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.bottomLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 76),
            self.bottomLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -12),
            self.bottomLabel.widthAnchor.constraint(equalToConstant: 303),
            self.bottomLabel.heightAnchor.constraint(equalToConstant: 20),
            self.bottomLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 16),
            self.bottomLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -56)
        ])
        
        self.icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.icon.topAnchor.constraint(equalTo: self.topAnchor, constant: 23),
            self.icon.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 74.3),
            self.icon.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 18.5),
            self.icon.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -341.62),
            self.icon.widthAnchor.constraint(equalToConstant: 20),
            self.icon.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configCell(_ topLine: String, _ middleLine: String, _ bottomLine: String, _ icon: UIImageView) {
        
        topLabel.text = topLine
        middleLabel.text = middleLine
        bottomLabel.text = bottomLine
        
        self.icon = icon
        
        self.layoutIfNeeded()
    }
}

extension ThreeLinesTableViewCell: IBDesignableLabeled {
    override func prepareForInterfaceBuilder() {
        self.labelAtInterfaceBuilder()
    }
}
