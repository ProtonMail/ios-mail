//
//  UICollectionView+Extension.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 12/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

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
                                                      for indexPath: IndexPath) -> T?
    {
        return self.dequeueReusableCell(withReuseIdentifier: String(describing: cellClass),
                                        for: indexPath) as? T
    }
}
