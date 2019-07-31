//
//  TableCellLabelView.swift
//  ProtonMail - Created on 8/16/15.
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

class TableCellLabelView: UIView {
    fileprivate let kCoverImageViewWidth : CGFloat = 3.0
    
    fileprivate var textLabel:UILabel!
    fileprivate var contentView : UIView!
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        contentView = UIView(frame: CGRect(x: 0,y: 0, width: 50, height: 13))
        textLabel = UILabel(frame: CGRect(x: 0,y: 0, width: 50, height: 13))
        
        textLabel.text = ""
        textLabel.textColor = UIColor.green
        textLabel.layer.borderWidth = 1
        textLabel.layer.cornerRadius = 2
        textLabel.layer.borderColor = UIColor.green.cgColor
        textLabel.font = Fonts.h7.light
        self.contentView.addSubview(textLabel)
        self.addSubview(contentView)
        
        textLabel.mas_makeConstraints { (make) -> Void in
            let _ = make?.top.equalTo()(self.contentView)
            let _ = make?.bottom.equalTo()(self.contentView)
            let _ = make?.right.equalTo()(self.contentView)
            let _ = make?.left.equalTo()(self.contentView)
        }
        
        contentView.mas_makeConstraints { (make) -> Void in
            let _ = make?.top.equalTo()(self)
            let _ = make?.bottom.equalTo()(self)
            let _ = make?.left.equalTo()(self)?.offset()(self.kCoverImageViewWidth)
            let _ = make?.right.equalTo()(self)
        }
        self.clipsToBounds = true
        self.contentView.clipsToBounds = true
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    func updateTextFont (_ font: UIFont){
        self.textLabel.font = font
    }
    
    func setText(_ label: String, color: UIColor) ->CGFloat {
        self.textLabel.text = "  \(label)  "

        let s = self.textLabel.sizeThatFits(CGSize.zero)
                textLabel.textColor = color
        textLabel.layer.borderColor = color.cgColor
        
        return s.width + self.kCoverImageViewWidth
    }    
}
