//
//  ConfigurableCell.swift
//  ProtonMail - Created on 12/08/2018.
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
