//
//  ContactDetailsUpgradeCell.swift
//  ProtonMail - Created on 1/8/18.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import ProtonCore_UIFoundations

final class ContactDetailsUpgradeCell: UITableViewCell {
    
    @IBOutlet weak var frameView: UIView!
    @IBOutlet weak var upgradeButton: UIButton!
    
    private var delegate: ContactUpgradeCellDelegate?
    
    override func awakeFromNib() {
        let color = ColorProvider.BrandNorm
        frameView.layer.borderColor = color.cgColor
        frameView.layer.borderWidth = 1.0
        frameView.layer.cornerRadius = 4.0
        frameView.clipsToBounds = true
        upgradeButton.roundCorners()
    }
    @IBAction func upgradeAction(_ sender: Any) {
        self.delegate?.upgrade()
    }
    
    func configCell(delegate: ContactUpgradeCellDelegate?) {
        self.delegate = delegate
    }
}
