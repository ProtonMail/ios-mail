//
//  ShowImageView.swift
//  ProtonMail - Created on 3/22/16.
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

class SpamScoreWarningView: PMView {
    
    @IBOutlet weak var messageLabel: UILabel!
    
    override func getNibName() -> String {
        return "SpamScoreWarningView"
    }
    
    func setMessage(msg : String) {
        messageLabel.text = msg
    }
    
    func fitHeight() -> CGFloat {
        messageLabel.sizeToFit()
        var size = self.frame.size
        size.width -= 40
        let s = messageLabel.sizeThatFits(size)
        return s.height + 16
    }
    
    override func setup() {
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.numberOfLines = 0
        messageLabel.sizeToFit()
        messageLabel.text = ""
    }
}
