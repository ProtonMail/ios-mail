//
//  UILabel+Extension.swift
//  ProtonMail
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
