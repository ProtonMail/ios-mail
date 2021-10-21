//
//  CollectionViewTableLayout.swift
//  ProtonMail - Created on 15/08/2018.
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

class CollectionViewTableLayout: UICollectionViewFlowLayout {
    override init() {
        super.init()
        self.register(SeparatorDecorationView.self)
        self.scrollDirection = .vertical
        self.minimumLineSpacing = 0
        self.minimumInteritemSpacing = 0
    }
    
    var invalidatedOnce: Bool = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.register(SeparatorDecorationView.self)
        self.scrollDirection = .vertical
        self.minimumLineSpacing = 0
        self.minimumInteritemSpacing = 0
    }
    
    private var separators: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    
    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        self.estimatedItemSize = .init(width: (UIApplication.shared.keyWindow?.bounds.width ?? 200), height: 200)
        super.invalidateLayout(with: context)
    }

    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
            return self.separators[indexPath]
    }

    override func prepare() {
        super.prepare()

        // get rows
        guard let numberOfSections = self.collectionView?.numberOfSections else {
            return
        }

        separators.removeAll()

        for section in 0..<numberOfSections {
            guard let rows = self.collectionView?.numberOfItems(inSection: section) else {
                continue
            }
            for row in 0..<rows {
                let indexPath = IndexPath(row: row, section: section)
                guard let attribute = self.layoutAttributesForItem(at: indexPath) else {
                    continue
                }

                let rowFrame = attribute.frame
                let frame = CGRect(x: rowFrame.minX, y: rowFrame.maxY - 1, width: rowFrame.width, height: 1)
                let decoration = UICollectionViewLayoutAttributes(forDecorationViewOfKind: String(describing: SeparatorDecorationView.self), with: indexPath)
                decoration.frame = frame
                decoration.zIndex = Int.max - 1

                separators[indexPath] = decoration
            }
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let allAttributes = super.layoutAttributesForElements(in: rect) else { return nil }
        
        var result: [UICollectionViewLayoutAttributes] = allAttributes.compactMap { attributes in
            return self.layoutAttributesForItem(at: attributes.indexPath)
        }
        result.append(contentsOf: separators.values)
        return result
    }
}

extension CollectionViewTableLayout {
    class SeparatorDecorationView: UICollectionReusableView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.backgroundColor = UIColor.ProtonMail.TableSeparatorGray
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            self.backgroundColor = UIColor.ProtonMail.TableSeparatorGray
        }
        
        override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
            self.frame = layoutAttributes.frame
        }
        
        override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
            guard let attributes: UICollectionViewLayoutAttributes = layoutAttributes.copy() as? UICollectionViewLayoutAttributes else {
                return layoutAttributes
            }
            attributes.zIndex = Int.max - 1
            return attributes
        }
    }
}
