//
//  AnyStorefrontItem.swift
//  ProtonMail - Created on 18/12/2018.
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

class AnyStorefrontItem: NSObject { }
class LogoStorefrontItem: AnyStorefrontItem {
    typealias ColoredSubtitle = (String, UIColor) // FIXME: NSAttributedString instead of color
    var imageName: String
    var title: String
    var subtitle: ColoredSubtitle
    
    init(imageName: String, title: String, subtitle: ColoredSubtitle) {
        self.imageName = imageName
        self.title = title
        self.subtitle = subtitle
    }
}
class DetailStorefrontItem: AnyStorefrontItem {
    var imageName: String
    var text: String
    
    init(imageName: String, text: String) {
        self.imageName = imageName
        self.text = text
    }
}
class AnnotationStorefrontItem: AnyStorefrontItem {
    var text: NSAttributedString
    init(text: NSAttributedString) {
        self.text = text
    }
}
class SubsectionHeaderStorefrontItem: AnyStorefrontItem {
    var text: String
    init(text: String) {
        self.text = text
    }
}
class DisclaimerStorefrontItem: AnyStorefrontItem {
    var text: String
    init(text: String) {
        self.text = text
    }
}
class LinkStorefrontItem: AnyStorefrontItem {
    var text: NSAttributedString
    init(text: NSAttributedString) {
        self.text = text
    }
}
class BuyButtonStorefrontItem: AnyStorefrontItem {
    var subtitle: String?
    var buttonTitle: NSAttributedString?
    var buttonEnabled: Bool
    
    init(subtitle: String?, buttonTitle: NSAttributedString?, buttonEnabled: Bool) {
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.buttonEnabled = buttonEnabled
    }
}
