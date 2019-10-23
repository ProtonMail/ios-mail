//
//  ServicePlanCapability.swift
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


class ServicePlanCapability: UIView {
    internal private(set) var context: Any?
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var serviceIcon: UIImageView!
    
    convenience init(image: UIImage? = nil,
                     title: NSAttributedString? = nil,
                     serviceIconVisible: Bool = false,
                     context: Any? = nil)
    {
        self.init(frame: .zero)
        defer {
            self.setup(image: image, title: title, serviceIconVisible: serviceIconVisible, context: context)
        }
    }
    
    func setup(image: UIImage? = nil,
               title: NSAttributedString? = nil,
               serviceIconVisible: Bool = false,
               context: Any? = nil)
    {
        if image != nil {
            self.icon.image = image?.withRenderingMode(.alwaysTemplate)
        } else {
            self.icon.isHidden = true
        }
        self.title.attributedText = title
        self.serviceIcon.isHidden = !serviceIconVisible
        self.context = context
        
        self.isAccessibilityElement = true
        self.title.isAccessibilityElement = false
        self.icon.isAccessibilityElement = false
        self.serviceIcon.isAccessibilityElement = false
        
        self.accessibilityLabel = title?.string
        self.accessibilityTraits = serviceIconVisible ? UIAccessibilityTraits.button : UIAccessibilityTraits.staticText
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadFromNib()
        self.setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadFromNib()
        self.setupSubviews()
    }
    
    private func setupSubviews() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.serviceIcon.tintColor = .gray
        self.serviceIcon.image = UIImage(named: "pin_code_confirm")?.withRenderingMode(.alwaysTemplate)
        self.icon.tintColor = UIColor.ProtonMail.ButtonBackground
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let xInset: CGFloat = 40 /* leading+trailing insets*/ + 17 /* icon constraint */ + 8 /* stack view spacing */ + (self.serviceIcon.isHidden ? 0 : (40 /* serviceIcon constraint */ + 8 /* stack view spacing */))
        
        var textSpace = CGRect(origin: .zero, size: size)
        textSpace = textSpace.insetBy(dx: xInset/2, dy: 0)
        var textSize = self.title.textRect(forBounds: textSpace, limitedToNumberOfLines: 0)
        
        textSize.size.width = size.width
        if textSize.height < 56 { /* good readible height */
            textSize = textSize.insetBy(dx: 0, dy: (textSize.height - 56)/2)
        } else {
            textSize = textSize.insetBy(dx: 0, dy: -8)
        }
        return textSize.size
    }
}
