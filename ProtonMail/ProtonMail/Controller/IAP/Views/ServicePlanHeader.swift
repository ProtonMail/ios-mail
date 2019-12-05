//
//  Header.swift
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

class ServicePlanHeader: UIView {
    @IBOutlet private weak var icon: UIImageView!
    @IBOutlet private weak var subtitle: UILabel!
    @IBOutlet private weak var subicon: UILabel!
    
    convenience init(image: UIImage? = nil,
                     title: String? = nil,
                     subicon: (String, UIColor)? = nil)
    {
        self.init(frame: .zero)
        defer {
            self.setup(image: image, title: title, subicon: subicon)
        }
    }
    
    func setup(image: UIImage? = nil,
               title: String? = nil,
               subicon: (String, UIColor)? = nil)
    {
        self.icon.image = image
        self.subtitle.text = title
        self.icon.isAccessibilityElement = false
        self.subtitle.isAccessibilityElement = false
        self.subicon.isAccessibilityElement = false
        self.isAccessibilityElement = true
        
        if let subicon = subicon {
            self.subicon.text = subicon.0
            self.subicon.textColor = subicon.1
            self.accessibilityLabel = "ProtonMail " + subicon.0 + ": " + (title ?? "")
        } else {
            self.subicon.isHidden = true
            self.accessibilityLabel = title
        }
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
        self.icon.tintColor = UIColor.ProtonMail.ButtonBackground
    }
}
