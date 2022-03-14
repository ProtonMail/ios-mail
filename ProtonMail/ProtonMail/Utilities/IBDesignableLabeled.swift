//
//  IBDesignableCell.swift
//  ProtonMail - Created on 10/06/2018.
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

/// Calling method labelAtInterfaceBuilder() in prepareForInterfaceBuilder() of a concrete class will label cell with a class name in Interface Builder.
protocol IBDesignableLabeled: AnyObject {
    var contentView: UIView { get }
}
extension IBDesignableLabeled {
    internal func labelAtInterfaceBuilder() {
        let label = UILabel.init(frame: self.contentView.bounds)
        label.text = "\(Self.self)"
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.preferredFont(forTextStyle: .headline)

        let colors: [UIColor] = [.magenta, .green, .blue, .yellow, .red]

        self.contentView.backgroundColor = colors[Int(arc4random_uniform(UInt32(colors.count)))]
        self.contentView.addSubview(label)
    }
}
