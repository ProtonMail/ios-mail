//
//  UILabel+Extension.swift
//  ProtonMail
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

extension UILabel {

    convenience init(attributedString: NSAttributedString) {
        self.init()
        self.attributedText = attributedString
        self.sizeToFit()
    }
    
    convenience init(font: UIFont, text: String, textColor: UIColor) {
        self.init()
        self.font = font
        self.numberOfLines = 1
        self.text = text
        self.textColor = textColor
        self.sizeToFit()
    }
    
    func setIcons(imageNames: [String], useTintColor: Bool) {
        let myString = NSMutableAttributedString.init()
        
        for imageName in imageNames {
            let attachment = NSTextAttachment()
            let image = UIImage(named: imageName)
            
            if useTintColor {
                image?.withRenderingMode(.alwaysTemplate)
            }
            
            attachment.image = image
            
            let attachmentString = NSAttributedString(attachment: attachment)
            myString.append(attachmentString)
        }
        
        self.attributedText = myString
    }
    
    func addBottomBorder() {
        let bottomBorder = CALayer()
        bottomBorder.borderColor = UIColor.lightGray.cgColor
        bottomBorder.borderWidth = 0.7
        bottomBorder.frame = CGRect.init(x: 0, y: self.frame.height - 1,
                                         width: self.frame.width, height: 1)
        self.clipsToBounds = true
        self.layer.addSublayer(bottomBorder)
    }
}
