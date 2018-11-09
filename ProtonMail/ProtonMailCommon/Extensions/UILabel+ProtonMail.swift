//
//  UIViewExtension.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

extension UILabel {
    
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
