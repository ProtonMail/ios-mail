//
//  ContactCollectionViewPromptCell.swift
//  ProtonMail - Created on 4/27/18.
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

class ContactCollectionViewPromptCell: UICollectionViewCell {
    
    var _prompt : String = ContactPickerDefined.kPrompt
    var promptLabel: UILabel!
    var insets: UIEdgeInsets!
    
    @objc dynamic var font: UIFont? {
        get { return self.promptLabel.font }
        set {
            self.promptLabel.font = newValue
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init(coder: aDecoder)
        self.setup()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }
    
    func setup() {
        self.insets = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
        
        #if DEBUG_BORDERS
        self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor.purple.cgColor
        #endif
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(label)
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[label]|",
                                                           options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                           metrics: nil,
                                                           views: ["label": label]))
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[label]|",
                                                           options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                           metrics: nil,
                                                           views: ["label": label]))
        
        label.textAlignment = .left
        label.text = self.prompt
        label.textColor = UIColor(RRGGBB: UInt(0x4f4f61))
        
        self.promptLabel = label
    }
    
    var prompt : String {
        get {
            return self._prompt
        }
        set {
            self._prompt = newValue
            self.promptLabel.text = self._prompt
            self.promptLabel.accessibilityIdentifier = "\(self._prompt)Label"
        }
    }
    
    class func widthWithPrompt(prompt: String) -> CGFloat {
        let size = prompt.size(withAttributes: [NSAttributedString.Key.font:  Fonts.h6.light])
        return 5 + size.width.rounded(.up)
    }
    
}
