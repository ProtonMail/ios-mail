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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let composeViewController = segue.destinationViewController.viewControllers!.first as! HtmlEditorViewController

        
        var bodyText = NSLocalizedString("Loading...")
        
        if self.message.isDetailDownloaded {
            var error: NSError?
            bodyText = self.message.decryptBodyIfNeeded(&error) ?? NSLocalizedString("Unable to decrypt message.")
        }
        
        let htmlString = "<div><br></div><div><br></div><div><br></div><div><br></div>This is a Sign<div><br></div><div><br></div>";

        let sp = "<div>Feng wrote:</div><blockquote class=\"gmail_quote\" style=\"margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex\"><tbody><tr><td align=\"center\" valign=\"top\"> <table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" style=\"background-color:transparent;border-bottom:0;border-bottom:solid 1px #00929f\" width=\"100%\"> "

        
        composeViewController.setHTML("\(htmlString) \(sp) \(bodyText)</blockquote>");

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
