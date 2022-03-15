//
//  UICollectionView+Extension.swift
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

extension UICollectionViewFlowLayout {
    func register<A>(_ accessoryClass: A.Type) where A: UICollectionReusableView {
        self.register(accessoryClass, forDecorationViewOfKind: String(describing: accessoryClass))
    }
}

extension UICollectionView {
    func register<C>(_ cellClass: C.Type) where C: UICollectionViewCell {
        self.register(cellClass, forCellWithReuseIdentifier: String(describing: cellClass))
    }

    func dequeueReusableCell<T: UICollectionViewCell>(_ cellClass: T.Type,
                                                      for indexPath: IndexPath) -> T? {
        return self.dequeueReusableCell(withReuseIdentifier: String(describing: cellClass),
                                        for: indexPath) as? T
    }
}
