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

@IBDesignable class ButtonTableViewCell: UITableViewCell {
    static var CellID: String {
        return "\(self)"
    }
    
    typealias buttonActionBlock = () -> Void
    var callback: buttonActionBlock?
    
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.topLabel.textColor = ColorProvider.TextNorm
        self.topLabel.font = UIFont.systemFont(ofSize: 17)
        self.topLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.topLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 16),
            self.topLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -56),
            self.topLabel.widthAnchor.constraint(equalToConstant: 243),
            self.topLabel.heightAnchor.constraint(equalToConstant: 24),
            self.topLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 16),
            self.topLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -116)
        ])
        
        self.bottomLabel.textColor = ColorProvider.TextNorm
        self.bottomLabel.font = UIFont.systemFont(ofSize: 14)
        self.bottomLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.bottomLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 54),
            self.bottomLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -22),
            self.bottomLabel.widthAnchor.constraint(equalToConstant: 263),
            self.bottomLabel.heightAnchor.constraint(equalToConstant: 20),
            self.bottomLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 16),
            self.bottomLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -96)
        ])
        
        //self.button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        self.button.titleLabel?.adjustsFontSizeToFitWidth = true
        self.button.setTitleColor(ColorProvider.TextNorm, for: .normal)
        self.button.tintColor = ColorProvider.InteractionWeak
        self.button.layer.cornerRadius = 8
        self.button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.button.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 48),
            self.button.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -16),
            self.button.widthAnchor.constraint(equalToConstant: 64),
            self.button.heightAnchor.constraint(equalToConstant: 32),
            self.button.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -16)
        ])
    }
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        callback?()
    }
    
    func configCell(_ topLine: String, _ bottomLine: String, _ titleOfButton: String, complete: buttonActionBlock?) {
        topLabel.text = topLine
        bottomLabel.text = bottomLine
        button.setTitle(titleOfButton, for: .normal)
        callback = complete
        
        self.layoutIfNeeded()
    }
}

extension ButtonTableViewCell: IBDesignableLabeled {
    override func prepareForInterfaceBuilder() {
        self.labelAtInterfaceBuilder()
    }
}

