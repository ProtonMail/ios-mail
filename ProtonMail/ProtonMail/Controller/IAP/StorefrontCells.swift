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
    func setup(with item: AnyStorefrontItem)
}


// concrete

class StorefrontLogoCell: AutoSizedCell, StorefrontItemConfigurable {
    @IBOutlet weak var headerView: ServicePlanHeader!
    
    func setup(with item: AnyStorefrontItem) {
        if let item = item as? LogoStorefrontItem {
            self.headerView.setup(image: UIImage(named: item.imageName)?.withRenderingMode(.alwaysTemplate),
                                  title: item.title,
                                  subicon: item.subtitle)
            return
        }
    }
}

class StorefrontDetailCell: SubviewSizedCell, StorefrontItemConfigurable {
    @IBOutlet weak var capabilityView: ServicePlanCapability!
    
    func setup(with item: AnyStorefrontItem) {
        if let item = item as? DetailStorefrontItem {
            var regularAttributes = [NSAttributedString.Key: Any]()
            regularAttributes[.font] = UIFont.preferredFont(forTextStyle: .body)
            self.capabilityView.setup(image: UIImage(named: item.imageName), title: NSAttributedString(string: item.text, attributes: regularAttributes))
            return
        }
        
        if let item = item as? LinkStorefrontItem {
            self.capabilityView.setup(title: item.text, serviceIconVisible: true)
            return
        }
    }
}

class StorefrontAnnotationCell: AutoSizedCell, StorefrontItemConfigurable {
    @IBOutlet weak var footerView: ServicePlanFooter!
    
    func setup(with item: AnyStorefrontItem) {
        if let item = item as? AnnotationStorefrontItem {
            self.footerView.setup(title: item.text)
            return
        }
    }
}

@objc protocol StorefrontBuyButtonCellDelegate: class {
    func buyButtonTapped()
}
class StorefrontBuyButtonCell: AutoSizedCell, StorefrontItemConfigurable  {
    @IBOutlet weak var delegate: StorefrontBuyButtonCellDelegate?
    @IBOutlet weak var footerView: ServicePlanFooter!
    
    func setup(with item: AnyStorefrontItem) {
        if let item = item as? BuyButtonStorefrontItem {
            self.footerView.setup(subTitle: item.subtitle,
                                  buttonTitle: item.buttonTitle,
                                  buttonEnabled: item.buttonEnabled,
                                  buttonAction: { _ in self.delegate?.buyButtonTapped() })
            return
        }
    }
}

class StorefrontDisclaimerCell: SubviewSizedCell, StorefrontItemConfigurable {
    @IBOutlet weak var header: ServicePlanTableSectionHeader!
    
    func setup(with item: AnyStorefrontItem) {
        if let item = item as? SubsectionHeaderStorefrontItem {
            self.header.setup(title: item.text, textAlignment: .left)
            return
        }
        
        if let item = item as? DisclaimerStorefrontItem {
            self.header.setup(title: item.text, textAlignment: .center)
            return
        }
    }
}
