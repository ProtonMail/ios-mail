//
//  MessageViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/27/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit
import QuickLook


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
                    self.updateHeader()
                    self.emailView?.emailHeader.updateAttConstraints(true)
                }
            }
        }
    }
    
    ///
    var emailView: EmailView?
    
    
    /// 
    private var actionTapped: ComposeMessageAction!
    private var fetchedMessageController: NSFetchedResultsController?
    
    private var bodyLoaded: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupRightButtons()
        
        self.setupFetchedResultsController(message.messageID)

        self.updateHeader()
        
        if (self.message.hasAttachments) {
            let atts = self.message.attachments.allObjects as! [Attachment]
            self.emailView?.updateEmailAttachment(atts);
        }

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
    
    private func updateHeader() {
        self.emailView?.updateHeaderData(self.message.subject,
            sender: self.message.senderName ?? self.message.sender,
            to: self.message.recipientList.getDisplayAddress(),
            cc: self.message.ccList.getDisplayAddress(),
            bcc: self.message.bccList.getDisplayAddress(),
            isStarred: self.message.isStarred,
            time: self.message.time)
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
            let composeViewController = segue.destinationViewController as! ComposeEmailViewController
            composeViewController.viewModel = ComposeViewModelImpl(msg: message, action: self.actionTapped)
        } else if segue.identifier == "toApplyLabelsSegue" {
            let popup = segue.destinationViewController as! UIViewController
            self.setPresentationStyleForSelfController(self, presentingController: popup)
        }
    }

    override func shouldShowSideMenu() -> Bool {
        return false
    }
    
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "statusBarHit:", name: "touchStatusBarClick", object:nil)
        
        message.isRead = true
        message.needsUpdate = true
        if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
            NSLog("\(__FUNCTION__) error: \(error)")
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "touchStatusBarClick", object:nil)
    }
    
    internal func statusBarHit (notify: NSNotification) {
        self.emailView?.contentWebView.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }

    func moreButtonTapped() {
        self.emailView!.animateMoreViewOptions()
        self.performSegueWithIdentifier("toApplyLabelsSegue", sender: self)
    }
    
    func setPresentationStyleForSelfController(selfController : UIViewController,  presentingController: UIViewController)
    {
        presentingController.providesPresentationContextTransitionStyle = true;
        presentingController.definesPresentationContext = true;
        presentingController.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
    }
    
    // MARK : private function
    private func updateEmailBody () {
        if (self.message.hasAttachments) {
            let atts = self.message.attachments.allObjects as! [Attachment]
            self.emailView?.updateEmailAttachment(atts);
        }
        
        if !self.bodyLoaded && self.emailView != nil {
            var bodyText = NSLocalizedString("Loading...")
            if self.message.isDetailDownloaded {
                self.bodyLoaded = true
                var error: NSError?
                bodyText = self.message.decryptBodyIfNeeded(&error) ?? NSLocalizedString("Unable to decrypt message.")
            }
            
            let meta : String = "<meta name=\"viewport\" content=\"width=600\">\n"
            self.emailView?.updateEmailBody(bodyText, meta: self.message.isDetailDownloaded ? "" : meta)
        }
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
private var tempFileUri : NSURL?
extension MessageViewController : EmailHeaderActionsProtocol {
    func starredChanged(isStarred: Bool) {
        message.isStarred = isStarred
        message.needsUpdate = true
        if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
            NSLog("\(__FUNCTION__) error: \(error)")
        }
    }
    
    func quickLookAttachment (localURL : NSURL, keyPackage:NSData, fileName:String) {
        if let data : NSData = NSData(contentsOfURL: localURL) {
            tempFileUri = NSFileManager.defaultManager().attachmentDirectory.URLByAppendingPathComponent(fileName);
            let decryptData = data.decryptAttachment(keyPackage, passphrase: sharedUserDataService.mailboxPassword!, publicKey: sharedUserDataService.userInfo!.publicKey, privateKey: sharedUserDataService.userInfo!.privateKey, error: nil)
            
            decryptData!.writeToURL(tempFileUri!, atomically: true)
            
            let previewQL = QLPreviewController()
            previewQL.dataSource = self
            self.presentViewController(previewQL, animated: true, completion: nil)
        }
        else{
            
        }
    }
}

// MARK: - UIDocumentInteractionControllerDelegate

extension MessageViewController: UIDocumentInteractionControllerDelegate {
}

extension MessageViewController : QLPreviewControllerDataSource {
    func numberOfPreviewItemsInPreviewController(controller: QLPreviewController!) -> Int {
        return 1
    }
    
    func previewController(controller: QLPreviewController!, previewItemAtIndex index: Int) -> QLPreviewItem! {
        return tempFileUri
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
        
        if message.location != .archive {
            alertController.addAction(UIAlertAction(title: MessageLocation.archive.description, style: .Destructive, handler: { (action) -> Void in
                self.message.location = .archive
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
