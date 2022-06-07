//
//  CountryCodeTableViewCell.swift
//  ProtonCore-UIFoundations - Created on 12.03.21.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import UIKit
import ProtonCore_Foundations

class CountryCodeTableViewCell: UITableViewCell, AccessibleCell {

    @IBOutlet weak var flagImageView: UIImageView!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var codeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        imageView?.contentMode = .scaleAspectFit
        flagImageView.layer.cornerRadius = 4
        flagImageView.layer.masksToBounds = true
        countryLabel.textColor = ColorProvider.TextNorm
        codeLabel.textColor = ColorProvider.TextWeak
    }

    func configCell(_ countryCode: CountryCode) {
        flagImageView.image = IconProvider.flag(forCountryCode: countryCode.country_code)
        countryLabel.text = countryCode.country_en
        codeLabel.text = "+ \(countryCode.phone_code)"
        generateCellAccessibilityIdentifiers(countryCode.country_en)
        backgroundColor = ColorProvider.BackgroundNorm
    }
}
