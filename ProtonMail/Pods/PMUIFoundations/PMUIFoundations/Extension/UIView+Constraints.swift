//
//  UIView+Constraints.swift
//  ProtonMail - Created on 20.08.20.
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

extension UIView {
    func fillSuperview() {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor),
            leftAnchor.constraint(equalTo: superview.leftAnchor),
            rightAnchor.constraint(equalTo: superview.rightAnchor)
        ])
    }

    func centerXInSuperview(constant: CGFloat = 0) {
        guard let anchor = superview?.centerXAnchor else { return }
        translatesAutoresizingMaskIntoConstraints = false
        centerXAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
    }

    func centerYInSuperview(constant: CGFloat = 0) {
        guard let anchor = superview?.centerYAnchor else { return }
        translatesAutoresizingMaskIntoConstraints = false
        centerYAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
    }

    func centerInSuperview() {
        centerXInSuperview()
        centerYInSuperview()
    }

    func setSizeContraint(height: CGFloat?, width: CGFloat?) {
        self.translatesAutoresizingMaskIntoConstraints = false
        if let _height = height {
            self.heightAnchor.constraint(equalToConstant: _height).isActive = true
        }
        if let _width = width {
            self.widthAnchor.constraint(equalToConstant: _width).isActive = true
        }
    }
}
