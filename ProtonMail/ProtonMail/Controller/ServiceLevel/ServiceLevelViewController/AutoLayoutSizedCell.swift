//
//  ConfigurableCell.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 12/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

//FIXME: just got time to look into this.
//       why does this impl better than the build in table view automatic row height?
//       to me I feel your way fits in some complex situation when UITableview can't do.
//       I prefer to use UITableView for the simple listing view.
class AutoLayoutSizedCell: UICollectionViewCell {
    private var subview: UIView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func configure(with subview: UIView) {
        self.subview = subview
        
        self.contentView.subviews.forEach{ $0.removeFromSuperview() }
        self.contentView.addSubview(subview)
        subview.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        subview.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        subview.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        subview.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true    
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        guard let attributes: UICollectionViewLayoutAttributes = layoutAttributes.copy() as? UICollectionViewLayoutAttributes else {
            return layoutAttributes
        }
        
        var newFrame = attributes.frame
        self.frame = newFrame
        
        self.setNeedsLayout()
        self.layoutIfNeeded()
        
        let desiredHeight = self.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
        newFrame.size.height = desiredHeight
        attributes.frame = newFrame
        return attributes
    }
}

class FirstSubviewSizedCell: AutoLayoutSizedCell {
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes
    {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        guard let firstSubview = self.contentView.subviews.first else { return attributes}
        attributes.frame.size = firstSubview.sizeThatFits(attributes.frame.size)
        return attributes
    }
}
