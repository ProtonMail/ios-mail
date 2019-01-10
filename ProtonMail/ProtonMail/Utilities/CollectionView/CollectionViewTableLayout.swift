//
//  CollectionViewTableLayout.swift
//  ProtonMail - Created on 15/08/2018.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
    }
    
    private var separators: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    
    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        self.estimatedItemSize = .init(width: (UIApplication.shared.keyWindow?.bounds.width ?? 200) * 0.70, height: 200)
        super.invalidateLayout(with: context)
    }
    
    override func shouldInvalidateLayout(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool
    {
        // every separators frame depends on frame of some cell, which is calculated twice: attributes that FlowLayout calculates according to estimatedItemSize and then modified by cell according to its AutoLayout constraints. Here we are invalidating separator layout calculated BEFORE cells constraints were applied, so it will not be mispalced.
        if originalAttributes.representedElementKind == String(describing: SeparatorDecorationView.self) {
            return true
        }
        return super.shouldInvalidateLayout(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes)
    }
    
    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.separators[indexPath]
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes else { return nil }
        guard let collectionView = collectionView else { return attributes }
        
        attributes.bounds.size.width = collectionView.bounds.width - sectionInset.left - sectionInset.right
        
        if indexPath.item > 0 {
            let inset: CGFloat = 20.0
            let thickness: CGFloat = 1
            let separator = UICollectionViewLayoutAttributes(forDecorationViewOfKind: String(describing: SeparatorDecorationView.self), with: indexPath)
            separator.zIndex = Int.max
            separator.frame = .init(x: attributes.frame.origin.x + inset,
                                    y: attributes.frame.origin.y - 1,
                                    width: attributes.bounds.size.width - inset,
                                    height: thickness)
            
            self.separators[indexPath] = separator
        }
        
        return attributes
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let allAttributes = super.layoutAttributesForElements(in: rect) else { return nil }
        
        var result: [UICollectionViewLayoutAttributes] = allAttributes.compactMap { attributes in
            return self.layoutAttributesForItem(at: attributes.indexPath)
        }
        result.append(contentsOf: self.separators.values )
        
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
