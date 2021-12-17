//
//  UITableViewCll+Extension.swift
//  ProtonMail
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

extension UITableViewCell {
    /**
     reset table view cell inset and margins to .zero
     **/
    func zeroMargin() {
        if (self.responds(to: #selector(setter: UITableViewCell.separatorInset))) {
            self.separatorInset = .zero
        }
        if (self.responds(to: #selector(setter: UIView.layoutMargins))) {
            self.layoutMargins = .zero
        }
    }
    
    class func defaultNib() -> UINib {
        let name = String(describing: self)
        return UINib(nibName: name, bundle: Bundle.main)
    }
    
    class func defaultID() -> String {
        return String(describing: self)
    }
}

