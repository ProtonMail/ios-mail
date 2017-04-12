//
//  MailboxRationReviewCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/10/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//


import UIKit

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
