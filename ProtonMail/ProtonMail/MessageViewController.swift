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
                    self.updateEmailBody ()
                    //self.messageDetailView?.updateHeaderView()
                    //self.messageDetailView?.updateEmailBodyWebView(true)
                }
            }
        }
    }
    
    ///
    var emailView: EmailView?
    
    
    /// 
    private var actionTapped: ComposeMessageAction!
    private var fetchedMessageController: NSFetchedResultsController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupRightButtons()
        self.setupFetchedResultsController(message.messageID)

        self.emailView!.updateHeaderData(self.message.subject,
            sender: self.message.senderName ?? self.message.sender,
            to: self.message.recipientList.getDisplayAddress(),
            cc: self.message.ccList.getDisplayAddress(),
            bcc: self.message.bccList.getDisplayAddress(),
            isStarred: self.message.isStarred,
            attCount : self.message.attachments.count)
        self.emailView!.initLayouts()
        self.emailView!.bottomActionView.delegate = self
        self.emailView!.emailHeader.actionsDelegate = self
        self.emailView!.moreOptionsView.delegate = self
        self.updateEmailBody()
    }
    
    override func loadView() {
        emailView = EmailView()
        self.view = emailView
    }
    
        
    private func setupRightButtons() {
        var rightButtons: [UIBarButtonItem] = []
        
        rightButtons.append(UIBarButtonItem(image: UIImage(named: "arrow_down"), style: UIBarButtonItemStyle.Plain, target: self, action: "moreButtonTapped"))
        
        if message.location != .spam {
            rightButtons.append(UIBarButtonItem(image: UIImage(named: "spam_selected"), style: UIBarButtonItemStyle.Plain, target: self, action: "spamButtonTapped"))
        }
        
        rightButtons.append(UIBarButtonItem(image: UIImage(named: "trash_selected"), style: UIBarButtonItemStyle.Plain, target: self, action: "removeButtonTapped"))
        
        self.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
    }
    
    func removeButtonTapped() {
        switch(message.location) {
        case .trash, .spam:
            message.location = .deleted
        default:
            message.location = .trash
        }
        message.needsUpdate = true
        
        if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
            NSLog("\(__FUNCTION__) error: \(error)")
        }
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func spamButtonTapped() {
        message.location = .spam
        message.needsUpdate = true
        if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
            NSLog("\(__FUNCTION__) error: \(error)")
        }
        
        self.navigationController?.popViewControllerAnimated(true)
    }

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toCompose" {
            let composeViewController = segue.destinationViewController.viewControllers!.first as! ComposeEmailViewController
            composeViewController.viewModel = ComposeViewModelImpl(msg: message, action: self.actionTapped)
        }
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

    func moreButtonTapped() {
        self.emailView!.animateMoreViewOptions()
    }
    
    // MARK : private function
    private func updateEmailBody () {
        var bodyText = NSLocalizedString("Loading...")
        
        if self.message.isDetailDownloaded {
            var error: NSError?
            bodyText = self.message.decryptBodyIfNeeded(&error) ?? NSLocalizedString("Unable to decrypt message.")
        }
        

        let meta : String = "<meta name=\"viewport\" content=\"width=600\">\n"
        
        self.emailView?.updateEmailBody(bodyText, meta: self.message.isDetailDownloaded ? "" : meta)
    }
    
    private func setupFetchedResultsController(msg_id:String) {
        self.fetchedMessageController = sharedMessageDataService.fetchedMessageControllerForID(msg_id)
        if let fetchedMessageController = fetchedMessageController {
            var error: NSError?
            if !fetchedMessageController.performFetch(&error) {
                NSLog("\(__FUNCTION__) error: \(error)")
            }
        }
    }

}

// MARK
extension MessageViewController : MessageDetailBottomViewProtocol {
    
    func replyClicked() {
        self.actionTapped = ComposeMessageAction.Reply
        self.performSegueWithIdentifier("toCompose", sender: self)
    }
    
    func replyAllClicked() {
        actionTapped = ComposeMessageAction.ReplyAll
        self.performSegueWithIdentifier("toCompose", sender: self)
    }
    
    func forwardClicked() {
        actionTapped = ComposeMessageAction.Forward
        self.performSegueWithIdentifier("toCompose", sender: self)
    }
}


// MARK
extension MessageViewController : EmailHeaderActionsProtocol {
    func starredChanged(isStarred: Bool) {
        message.isStarred = isStarred
        message.needsUpdate = true
        if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
            NSLog("\(__FUNCTION__) error: \(error)")
        }
    }
}

// MARK
extension MessageViewController : MoreOptionsViewDelegate {
   
    func moreOptionsViewDidMarkAsUnread(moreOptionsView: MoreOptionsView) {
        message.isRead = false
        message.needsUpdate = true
        if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
            NSLog("\(__FUNCTION__) error: \(error)")
        }
        
        navigationController?.popViewControllerAnimated(true)

        
        self.emailView!.animateMoreViewOptions()
    }
    
    func moreOptionsViewDidSelectMoveTo(moreOptionsView: MoreOptionsView) {
        let alertController = UIAlertController(title: NSLocalizedString("Move to..."), message: nil, preferredStyle: .ActionSheet)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .Cancel, handler: nil))
        
        if message.location != .inbox {
            alertController.addAction(UIAlertAction(title: MessageLocation.inbox.description, style: .Default, handler: { (action) -> Void in
                self.message.location = .inbox
                self.message.needsUpdate = true
                if let error = self.message.managedObjectContext?.saveUpstreamIfNeeded() {
                    NSLog("\(__FUNCTION__) error: \(error)")
                }
                
                self.navigationController?.popViewControllerAnimated(true)
            }))
        }
        
        if message.location != .spam {
            alertController.addAction(UIAlertAction(title: MessageLocation.spam.description, style: .Default, handler: { (action) -> Void in
                self.message.location = .spam
                self.message.needsUpdate = true
                if let error = self.message.managedObjectContext?.saveUpstreamIfNeeded() {
                    NSLog("\(__FUNCTION__) error: \(error)")
                }
                
                self.navigationController?.popViewControllerAnimated(true)
            }))
        }
        
        if message.location != .trash {
            alertController.addAction(UIAlertAction(title: MessageLocation.trash.description, style: .Destructive, handler: { (action) -> Void in
                self.message.location = .trash
                self.message.needsUpdate = true
                if let error = self.message.managedObjectContext?.saveUpstreamIfNeeded() {
                    NSLog("\(__FUNCTION__) error: \(error)")
                }
                
                self.navigationController?.popViewControllerAnimated(true)
            }))
        }
        
        presentViewController(alertController, animated: true, completion: nil)
        
        self.emailView!.animateMoreViewOptions()
    }

}
