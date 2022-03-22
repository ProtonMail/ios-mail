//
//  ExpirationWarningHeaderCell.swift
//  ProtonMail - Created on 9/14/17.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit
import ProtonCore_UIFoundations

protocol ExpirationWarningHeaderCellDelegate: AnyObject {
    func clicked(at section: Int, expend: Bool)
}

class ExpirationWarningHeaderCell: UITableViewHeaderFooterView {
    weak var delegate: ExpirationWarningHeaderCellDelegate?
    @IBOutlet weak var headerLabel: UILabel!
    var section: Int = 0
    var expend: Bool = false

    @IBOutlet weak var actionButton: UIButton!

    @IBOutlet weak var arrowImage: UIImageView!
    @IBAction func backgroundAction(_ sender: Any) {
        if self.expend {
            self.expend = false
            self.updateImage()
            delegate?.clicked(at: self.section, expend: self.expend)
        } else {
            self.expend = true
            self.updateImage()
            delegate?.clicked(at: self.section, expend: self.expend)
        }
    }

    func ConfigHeader(title: String, section: Int, expend: Bool) {
        headerLabel.text = title
        self.section = section
        self.expend = expend
        self.updateImage()
    }

    func updateImage() {
        if self.expend {
            self.arrowImage.image = IconProvider.chevronDown
        } else {
            self.arrowImage.image = IconProvider.chevronUp
        }
    }
}
