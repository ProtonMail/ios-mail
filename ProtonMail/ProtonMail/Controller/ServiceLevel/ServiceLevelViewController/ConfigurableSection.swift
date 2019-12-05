//
//  ConfigurableSection.swift
//  ProtonMail - Created on 12/08/2018.
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

struct Section<Element: UIView> {
    fileprivate(set) var elements: Array<Element>
    var cellType: AutoLayoutSizedCell.Type
    var count: Int {
        return self.elements.count
    }
    func embed(_ elementNumber: Int, onto cell: AutoLayoutSizedCell) {
        cell.configure(with: self.elements[elementNumber])
    }
}
