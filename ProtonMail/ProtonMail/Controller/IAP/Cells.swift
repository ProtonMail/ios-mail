//
//  Cells.swift
//  ProtonMail - Created on 17/12/2018.
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
    

import Foundation

typealias StorefrontItemConfigurableCell = UICollectionViewCell&StorefrontItemConfigurable

protocol StorefrontItemConfigurable where Self: UICollectionViewCell {
    func setup(with item: StorefrontItem)
}


// concrete

class LogoCell: AutoSizedCell, StorefrontItemConfigurable {
    @IBOutlet weak var headerView: ServicePlanHeader!
    
    func setup(with item: StorefrontItem) {
        guard case StorefrontItem.logo(imageName: let imageName, title: let title, subtitle: let subtitle) = item else {
            return
        }
    
        self.headerView.setup(image: UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate),
                              title: title,
                              subicon: subtitle)
    }
}

class DetailCell: SubviewSizedCell, StorefrontItemConfigurable {
    @IBOutlet weak var capabilityView: ServicePlanCapability!
    
    func setup(with item: StorefrontItem) {
        if case StorefrontItem.detail(imageName: let imageName, description: let description) = item {
            self.capabilityView.setup(image: UIImage(named: imageName),
                                      title: NSAttributedString(string: description))
            return
        }
        
        if case StorefrontItem.link(text: let text) = item {
            self.capabilityView.setup(title: text,
                                      serviceIconVisible: true)
            return
        }
    }
}

class AnnotationCell: AutoSizedCell, StorefrontItemConfigurable {
    @IBOutlet weak var footerView: ServicePlanFooter!
    
    func setup(with item: StorefrontItem) {
        guard case StorefrontItem.annotation(text: let text) = item else {
            return
        }
        
        self.footerView.setup(title: text)
    }
}

class DisclaimerCell: SubviewSizedCell, StorefrontItemConfigurable {
    @IBOutlet weak var header: TableSectionHeader!
    
    func setup(with item: StorefrontItem) {
        if case StorefrontItem.subsectionHeader(text: let text) = item {
            self.header.setup(title: text, textAlignment: .left)
            return
        }
        
        // disclaimer
    }
}

// base

class AutoSizedCell: UICollectionViewCell {
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

class SubviewSizedCell: AutoSizedCell {
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes
    {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        guard let firstSubview = self.contentView.subviews.first else { return attributes}
        attributes.frame.size = firstSubview.sizeThatFits(attributes.frame.size)
        return attributes
    }
}
