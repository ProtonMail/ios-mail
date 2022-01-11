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

@IBDesignable class SpinnerTableViewCell: UITableViewCell {
    static var CellID: String {
        return "\(self)"
    }
    
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.topLabel.textColor = ColorProvider.TextNorm
        self.topLabel.font = UIFont.systemFont(ofSize: 17)
        self.topLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.topLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 12),
            self.topLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -66),
            self.topLabel.widthAnchor.constraint(equalToConstant: 289.7),
            self.topLabel.heightAnchor.constraint(equalToConstant: 24),
            self.topLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 16)
        ])
        
        self.bottomLabel.textColor = ColorProvider.TextWeak
        self.bottomLabel.font = UIFont.systemFont(ofSize: 13)
        self.bottomLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.bottomLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 62),
            self.bottomLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -24),
            self.bottomLabel.widthAnchor.constraint(equalToConstant: 303),
            self.bottomLabel.heightAnchor.constraint(equalToConstant: 16),
            self.bottomLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 60),
            self.bottomLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -12)
        ])
        
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.activityIndicator.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 56.67),
            self.activityIndicator.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -18.67),
            self.activityIndicator.widthAnchor.constraint(equalToConstant: 26.67),
            self.activityIndicator.heightAnchor.constraint(equalToConstant: 26.67),
            self.activityIndicator.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 18.67),
            self.activityIndicator.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -329.67)
        ])
    }
    
    func configCell(_ topLine: String, _ bottomLine: String) {
        topLabel.text = topLine
        bottomLabel.text = bottomLine
        activityIndicator.startAnimating()
        self.layoutIfNeeded()
    }
}

extension SpinnerTableViewCell: IBDesignableLabeled {
    override func prepareForInterfaceBuilder() {
        self.labelAtInterfaceBuilder()
    }
}
