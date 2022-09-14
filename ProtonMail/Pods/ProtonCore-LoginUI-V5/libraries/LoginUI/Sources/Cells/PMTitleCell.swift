//
//  HelpDescriptionCell.swift
//  ProtonCore-Login - Created on 04/11/2020.
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
import ProtonCore_UIFoundations

final class PMTitleCell: UITableViewCell {

    static let reuseIdentifier = "PMTitleCell"
    static let nib = UINib(nibName: "PMTitleCell", bundle: LoginAndSignup.bundle)

    // MARK: - Outlets

    @IBOutlet private weak var descriptionLabel: UILabel!

    // MARK: - Properties

    var title: String? {
        didSet {
            descriptionLabel.text = title
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        descriptionLabel.textColor = ColorProvider.TextWeak
        descriptionLabel.font = .adjustedFont(forTextStyle: .subheadline)

        selectionStyle = .none
        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
    }
}
