//
//  LabelCell.swift
//  ProtonMail - Created on 2/7/19.
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
    

import UIKit

class LabelCell: UICollectionViewCell {

    @IBOutlet weak var label: UILabel!
    
    /// expose this later
    private static let font = Fonts.h6.light
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.label.sizeToFit()
        self.label.clipsToBounds = true
        self.label.layer.borderWidth = 1
        self.label.layer.cornerRadius = 2
        self.label.font = LabelCell.font
    }

    func config(color: String, text: String) {
        self.label.text = LabelCell.buildText(text)
        self.label.textColor = UIColor(hexString: color, alpha: 1.0)
        self.label.layer.borderColor = UIColor(hexString: color, alpha: 1.0).cgColor
    }
    
    func size() -> CGSize {
        return self.label.sizeThatFits(CGSize.zero)
    }
    
    class private func buildText(_ text: String) -> String {
        if text.isEmpty {
            return text
        }
        return "  \(text)  "
    }
    
    class func estimateSize(_ text: String) -> CGSize {
         let size = buildText(text).size(withAttributes: [NSAttributedString.Key.font: font])
        
        return size
    }
    
}
