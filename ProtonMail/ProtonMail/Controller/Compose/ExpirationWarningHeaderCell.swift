//
//  ExpirationWarningHeaderCell.swift
//  ProtonMail - Created on 9/14/17.
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

protocol ExpirationWarningHeaderCellDelegate {
    func clicked(at section : Int, expend: Bool)
}

class ExpirationWarningHeaderCell: UITableViewHeaderFooterView {
    var delegate : ExpirationWarningHeaderCellDelegate?
    @IBOutlet weak var headerLabel: UILabel!
    var section : Int = 0
    var expend : Bool = false
    
    @IBOutlet weak var actionButton: UIButton!

    @IBOutlet weak var arrowImage: UIImageView!
    @IBAction func backgroundAction(_ sender: Any) {
        if self.expend {
            self.expend = false
            self.updateImage()
            delegate?.clicked(at: self.section, expend: self.expend)
        } else {
            self.expend = true
            self.updateImage()
            delegate?.clicked(at: self.section, expend: self.expend)
        }
    }
    
    func ConfigHeader(title : String, section : Int, expend : Bool) {
        headerLabel.text = title
        self.section = section
        self.expend = expend
        self.updateImage()
    }

    func updateImage() {
        if self.expend {
            self.arrowImage.image = UIImage(named: "mail_attachment-closed")
        } else {
            self.arrowImage.image = UIImage(named: "mail_attachment-open")
        }
    }
}
