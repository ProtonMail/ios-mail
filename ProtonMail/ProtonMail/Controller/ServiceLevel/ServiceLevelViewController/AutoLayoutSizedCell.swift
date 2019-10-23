//
//  ConfigurableCell.swift
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
        
        let desiredHeight = self.contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
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
