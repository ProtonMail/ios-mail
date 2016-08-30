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
    
    var contentHeight : CGFloat = 300;
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var fromView: RecipientView!
    @IBOutlet weak var toView: RecipientView!
    @IBOutlet weak var ccView: RecipientView!
    @IBOutlet weak var bccView: RecipientView!
    
    @IBOutlet weak var starButton: UIButton!
    @IBOutlet weak var expirationView: UIView!
    
//    @IBOutlet weak var fromHeight: NSLayoutConstraint!
//    @IBOutlet weak var toHeight: NSLayoutConstraint!
//    @IBOutlet weak var ccHeight: NSLayoutConstraint!
//    @IBOutlet weak var bccHeight: NSLayoutConstraint!
    
    
    override func setup() {
        fromView.prompt = "From"
        toView.prompt = "To"
        ccView.prompt = "Cc"
        bccView.prompt = "Bcc"
        
        titleLabel.mas_makeConstraints { (make) -> Void in
            make.removeExisting = true
            make.top.equalTo()(self.pmView)
            make.left.equalTo()(self.pmView)
            make.right.equalTo()(self.pmView)
            make.height.equalTo()(10)
        }
        layoutIfNeeded()
    }
    
    func getHeight() -> CGFloat {
        return 150;
    }
    
    func makeConstraints() {
        titleLabel.sizeToFit()
        //var size = titleLabel.sizeThatFits(CGSizeZero)
        
        titleLabel.mas_updateConstraints { (make) -> Void in
            make.removeExisting = true
            make.top.equalTo()(self.pmView.mas_top)
            make.left.equalTo()(self.pmView.mas_left)
            make.right.equalTo()(self.pmView.mas_right).offset()(-50)
            make.height.equalTo()(10)
        }

        
        PMLog.D("\(titleLabel.frame)")
        
        PMLog.D("\(self.frame)")
        
        PMLog.D("\(self.pmView.frame)")

        self.updateConstraintsIfNeeded()
//        fromView.sizeToFit()
//        var s = fromView.sizeThatFits(CGSizeZero)
//        //fromHeight.constant = s.height;
//        
//        toView.sizeToFit()
//        s = toView.sizeThatFits(CGSizeZero)
//        //toHeight.constant = s.height;
//        
//        ccView.sizeToFit()
//        s = ccView.sizeThatFits(CGSizeZero)
//        //ccHeight.constant = s.height;
//        contentHeight = ccView.frame.origin.y + ccView.frame.height;
//
//        bccView.sizeToFit()
//        s = bccView.sizeThatFits(CGSizeZero)
//        //bccHeight.constant = s.height;
//        self.pmView.updateConstraintsIfNeeded()
        //self.pmView.setNeedsUpdateConstraints()
        
       // contentHeight = bccView.frame.origin.y + bccView.frame.height;
        
        contentHeight = expirationView.frame.origin.y
    }


    @IBAction func starAction(sender: UIButton) {
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
        
        fromView.label = sender
        toView.label = to
        ccView.label = cc
        bccView.label = bcc
        
//        fromView.updateValue();
//        toView.updateValue();
//        ccView.updateValue();
//        bccView.updateValue();
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
    
    
    func showDetails(){
        
    }
    
    

    
}
