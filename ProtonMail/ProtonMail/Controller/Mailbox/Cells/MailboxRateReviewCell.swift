//
//  MailboxRationReviewCell.swift
//  ProtonMail - Created on 3/10/16.
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
import MCSwipeTableViewCell

protocol MailboxRateReviewCellDelegate {
    func mailboxRateReviewCell(_ cell: UITableViewCell, yesORno: Bool)
}

class MailboxRateReviewCell : MCSwipeTableViewCell {
    /**
    *  Constants
    */
    struct Constant {
        static let identifier = "MailboxRateReviewCell"
    }
    @IBOutlet weak var noButton: UIButton!
    @IBOutlet weak var yesButton: UIButton!
    
    var callback: MailboxRateReviewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        noButton.layer.cornerRadius = 2
        noButton.layer.borderColor = UIColor(RRGGBB: UInt(0x9199CB)).cgColor
        noButton.layer.borderWidth = 1
        
        yesButton.layer.cornerRadius = 2
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
    }
    
    @IBAction func yesAction(_ sender: UIButton) {
        callback?.mailboxRateReviewCell(self, yesORno: true)
    }
    
    @IBAction func noAction(_ sender: UIButton) {
        callback?.mailboxRateReviewCell(self, yesORno: false)
    }
}
