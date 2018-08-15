//
//  TableLayout.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 15/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

class TableLayout: UICollectionViewFlowLayout {
    override init() {
        super.init()
        self.register(Separator.self)
        self.scrollDirection = .vertical
        self.minimumLineSpacing = 0
        self.minimumInteritemSpacing = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private var separators: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    
    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        super.invalidateLayout(with: context)
        
        // this line is crucial for separators layout. If estimated size is too different from future real size - lower separators will be misplaces
        self.estimatedItemSize = .init(width: UIApplication.shared.keyWindow!.bounds.width * 0.70, height: 200)
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes else { return nil }
        guard let collectionView = collectionView else { return attributes }
        
        attributes.bounds.size.width = collectionView.bounds.width - sectionInset.left - sectionInset.right
        
        if indexPath.item > 0 {
            let separator = UICollectionViewLayoutAttributes(forDecorationViewOfKind: String(describing: Separator.self), with: indexPath)
            separator.frame = .init(origin: attributes.frame.origin, size: .init( width: attributes.bounds.size.width, height: 1))
            separator.zIndex = Int.max
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
