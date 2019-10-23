//
//  UITableViewHeaderFooterCustomized.swift
//  ProtonMail - Created on 14/06/2018.
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


import UIKit

protocol SectionHeaderCustomizing { }
extension SectionHeaderCustomizing {
    func customize(header view: UIView) {
        guard let header = view as? UITableViewHeaderFooterView else {
            return
        }
        if let text = header.textLabel?.text {
            header.textLabel?.text = NSLocalizedString(text, comment:"section header")
        }
        header.textLabel?.font = UIFont.preferredFont(forTextStyle: .caption1)
        header.textLabel?.textColor = .lightGray
    }
}
