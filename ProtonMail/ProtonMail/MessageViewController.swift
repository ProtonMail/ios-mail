//
//  MessageViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/27/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class MessageViewController: ProtonMailViewController {
    
    /// message info
    var message: Message! {
        didSet {
            message.fetchDetailIfNeeded() { _, _, msg, error in
                println(self.message.isDetailDownloaded)
                println(self.message.ccList)
                NSLog("\(__FUNCTION__) error: \(self.message)")
                if error != nil {
                    NSLog("\(__FUNCTION__) error: \(error)")
                }
                else
                {
                    //self.messageDetailView?.updateHeaderView()
                    //self.messageDetailView?.updateEmailBodyWebView(true)
                }
            }
        }
    }
    
    var emailView: EmailView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.emailView.updateHeaderData(self.message.subject,
            sender: self.message.senderName ?? self.message.sender,
            to: self.message.recipientList.getDisplayAddress(),
            cc: self.message.ccList.getDisplayAddress(),
            bcc: self.message.bccList.getDisplayAddress(),
            isStarred: self.message.isStarred,
            attCount : self.message.attachments.count)
        self.emailView.initLayouts()
        self.emailView.bottomActionView.delegate = self
        self.updateEmailBody()
    }
    
    override func loadView() {
        emailView = EmailView()
        self.view = emailView
    }
    
    override func shouldShowSideMenu() -> Bool {
        return false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK : private function
    private func updateEmailBody () {
        var bodyText = NSLocalizedString("Loading...")
        
        if self.message.isDetailDownloaded {
            var error: NSError?
            bodyText = self.message.decryptBodyIfNeeded(&error) ?? NSLocalizedString("Unable to decrypt message.")
        }
        
        self.emailView.updateEmailBody(bodyText)
    }
}


extension MessageViewController : MessageDetailBottomViewProtocol {
    
    func replyClicked() {
        self.performSegueWithIdentifier("toCompose", sender: self)
    }
    
    func replyAllClicked() {
        
    }
    
    func forwardClicked() {
        
    }
    
}
