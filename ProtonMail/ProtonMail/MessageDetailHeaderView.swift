//
//  MessageDetailHeaderView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/10/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class MessageDetailHeaderView: PMView {

    override func getNibName() -> String {
        return "MessageDetailHeaderView"
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var fromView: RecipientView!
    @IBOutlet weak var toView: RecipientView!
    @IBOutlet weak var ccView: RecipientView!
    @IBOutlet weak var bccView: RecipientView!
    
    override func awakeFromNib() {
        fromView.prompt = "From:"
        toView.prompt = "To:"
        ccView.prompt = "Cc:"
        bccView.prompt = "Bcc:"
    }
    
    func getHeight() -> CGFloat {
        return 500;
    }
    
    // MARK : Private functions
    func updateHeaderData (title : String, sender : String, to : String, cc : String, bcc : String, isStarred : Bool, time : NSDate?, encType : EncryptTypes) {
        
//        self.title = title
//        self.sender = sender
//        self.toList = to
//        self.ccList = cc
//        self.bccList = bcc
//        if time != nil {
//            self.date = time
//        } else {
//            self.date = NSDate()
//        }
//        
//        self.starred = isStarred

        titleLabel.text = title;
        
        fromView.labelValue = sender
        toView.labelValue = to
        ccView.labelValue = cc
        bccView.labelValue = bcc
        
//        self.emailTitle.text = title
//        self.emailSender.text = senderText
//        self.emailDetailToLabel.text = toText
//        self.emailDetailCCLabel.text = ccText
//        self.emailDetailBCCLabel.text = bccText
//        self.emailFavoriteButton.selected = self.starred;
//        self.emailTime.text = "at \(self.date.stringWithFormat(self.kHourMinuteFormat))".lowercaseString
//        let tm = self.date.formattedWith("'On' EE, MMM d, yyyy 'at' h:mm a") ?? "";
//        self.emailDetailDateLabel.text = "Date: \(tm)"
//        
//        if encType == EncryptTypes.Internal {
//            self.emailIsEncryptedImageView.highlighted = false;
//        } else {
//            self.emailIsEncryptedImageView.highlighted = true;
//        }
    }
}
