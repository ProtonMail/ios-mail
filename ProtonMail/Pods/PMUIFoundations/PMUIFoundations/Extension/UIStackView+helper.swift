//
//  UIStackView+helper.swift
//  ProtonMail - Created on 26.07.20.
//
//  Copyright (c) 2020 Proton Technologies AG
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
//

import UIKit

extension UIStackView {
    convenience init(_ _axis: NSLayoutConstraint.Axis,
                     alignment _alignment: UIStackView.Alignment,
                     distribution _distribution: UIStackView.Distribution,
                     useAutoLayout: Bool = false) {
        self.init(frame: .zero)
        axis = _axis
        alignment = _alignment
        distribution = _distribution
        translatesAutoresizingMaskIntoConstraints = !useAutoLayout
    }
}
