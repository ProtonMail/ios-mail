//
//  Cells.swift
//  ProtonMail - Created on 17/12/2018.
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

class StorefrontDisclaimerCell: AutoSizedCell, StorefrontItemConfigurable {
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
