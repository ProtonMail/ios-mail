//
//  UITableView+Extension.swift
//  ProtonCore-HumanVerification - Created on 03.06.2021
//
//  Copyright (c) 2019 Proton Technologies AG
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

extension UITableView {

    func noSeparatorsBelowFooter() {
        tableFooterView = UIView(frame: CGRect.zero)
    }

    /**
     reset table view inset and margins to .zero
     **/
    func zeroMargin() {
        if self.responds(to: #selector(setter: UITableViewCell.separatorInset)) {
            self.separatorInset = .zero
        }

        if self.responds(to: #selector(setter: UIView.layoutMargins)) {
            self.layoutMargins = .zero
        }
    }
}
