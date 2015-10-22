//
//  MessageViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/27/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit
import QuickLook
import Foundation


class MessageViewController: ProtonMailViewController {
    
    /// message info
    var message: Message! {
        didSet {
            message.fetchDetailIfNeeded() { _, _, msg, error in
                if error != nil {
                    NSLog("\(__FUNCTION__) error: \(error)")
                    self.updateEmailBodyWithError(error?.localizedDescription ?? "Unknow error .")
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
    
    @IBOutlet var backButton: UIBarButtonItem!
    
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
       
        self.updateEmailBody()
    }
    
    override func loadView() {
        emailView = EmailView()
        self.view = emailView
    }
    
    private func updateHeader() {
        var a = self.message.labels.allObjects
        self.emailView?.updateHeaderData(self.message.subject,
            sender: ContactVO(id: "", name: self.message.senderName, email: self.message.sender),
            to: self.message.recipientList.toContacts(),
            cc: self.message.ccList.toContacts(),
            bcc: self.message.bccList.toContacts(),
            isStarred: self.message.isStarred,
            time: self.message.time,
            encType: self.message.encryptType,
            labels : self.message.labels.allObjects as? [Label])
    }
    
    
    private func setupRightButtons() {
        var rightButtons: [UIBarButtonItem] = []
        rightButtons.append(UIBarButtonItem(image: UIImage(named: "top_more"), style: UIBarButtonItemStyle.Plain, target: self, action: "moreButtonTapped"))
        rightButtons.append(UIBarButtonItem(image: UIImage(named: "top_trash"), style: UIBarButtonItemStyle.Plain, target: self, action: "removeButtonTapped"))
        rightButtons.append(UIBarButtonItem(image: UIImage(named: "top_label"), style: UIBarButtonItemStyle.Plain, target: self, action: "labelButtonTapped"))
        rightButtons.append(UIBarButtonItem(image: UIImage(named: "top_unread"), style: UIBarButtonItemStyle.Plain, target: self, action: "unreadButtonTapped"))
        
        self.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
    }
    
    internal func unreadButtonTapped() {
        messagesSetValue(setValue: false, forKey: Message.Attributes.isRead)
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    internal func removeButtonTapped() {
        switch(message.location) {
        case .trash, .spam:
            self.messagesSetValue(setValue: MessageLocation.deleted.rawValue, forKey: Message.Attributes.locationNumber)
        default:
            self.messagesSetValue(setValue: MessageLocation.trash.rawValue, forKey: Message.Attributes.locationNumber)
        }
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    internal func labelButtonTapped() {
        self.performSegueWithIdentifier("toApplyLabelsSegue", sender: self)
    }
    
    internal func spamButtonTapped() {
        message.location = .spam
        message.needsUpdate = true
        if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
            NSLog("\(__FUNCTION__) error: \(error)")
        }
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    internal func moreButtonTapped() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .Cancel, handler: nil))

        let locations: [MessageLocation : UIAlertActionStyle] = [.inbox : .Default, .spam : .Default, .archive : .Destructive]
        for (location, style) in locations {
            if message.location != location {
                alertController.addAction(UIAlertAction(title: location.actionTitle, style: style, handler: { (action) -> Void in
                    self.messagesSetValue(setValue: location.rawValue, forKey: Message.Attributes.locationNumber)
                    self.navigationController?.popViewControllerAnimated(true)
                }))
            }
        }
        presentViewController(alertController, animated: true, completion: nil)
    }

    private func messagesSetValue(setValue value: AnyObject?, forKey key: String) {
        message.setValue(value, forKey: key)
        message.setValue(true, forKey: "needsUpdate")
        if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
            NSLog("\(__FUNCTION__) error: \(error)")
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toCompose" {
            let composeViewController = segue.destinationViewController as! ComposeEmailViewController
            composeViewController.viewModel = ComposeViewModelImpl(msg: message, action: self.actionTapped)
        } else if segue.identifier == "toApplyLabelsSegue" {
            let popup = segue.destinationViewController as! LablesViewController
            popup.viewModel = LabelViewModelImpl(msg: [self.message])
            self.setPresentationStyleForSelfController(self, presentingController: popup)
        }
    }
    
    override func shouldShowSideMenu() -> Bool {
        return false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //UIView.setAnimationsEnabled(false)
//        let value = UIInterfaceOrientationMask.Portrait.rawValue
//        UIDevice.currentDevice().setValue(value, forKey: "orientation")

        //self.emailView?.contentWebView.hidden = false //
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "statusBarHit:", name: "touchStatusBarClick", object:nil)
        
        message.isRead = true
        message.needsUpdate = true
        if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
            NSLog("\(__FUNCTION__) error: \(error)")
        }
        
        self.emailView?.contentWebView.userInteractionEnabled = true;
        self.emailView?.contentWebView.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "touchStatusBarClick", object:nil)
        //self.emailView?.contentWebView.userInteractionEnabled = false;
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.emailView?.contentWebView.stringByEvaluatingJavaScriptFromString("window.getSelection().removeAllRanges();")
        //self.emailView?.contentWebView.reload()
    }
    
    internal func statusBarHit (notify: NSNotification) {
        self.emailView?.contentWebView.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
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
                PMLog.D(self.message!.body);
                bodyText = self.message.decryptBodyIfNeeded(&error) ?? NSLocalizedString("Unable to decrypt message.")
                
                            }
//<meta name=\"viewport\" content=\"user-scalable=yes,maximum-scale=5.0,minimum-scale=0.5\" />
            let w = UIScreen.mainScreen().bounds.width * 2
            let meta : String = "<meta name=\"viewport\" content=\"width=\(w)\">\n"
            let meta1 : String = "<meta name=\"viewport\" content=\"width=\(600)\">"
            
            self.emailView?.updateEmailBody(bodyText, meta: self.message.isDetailDownloaded ? meta : meta1)
        }
    }
    
    // MARK : private function
    private func updateEmailBodyWithError (error:String) {
        if (self.message.hasAttachments) {
            let atts = self.message.attachments.allObjects as! [Attachment]
            self.emailView?.updateEmailAttachment(atts);
        }
        var bodyText = NSLocalizedString(error)
        let meta1 : String = "<meta name=\"viewport\" content=\"width=\(600)\">"
        self.emailView?.updateEmailBody(bodyText, meta: meta1)
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
        self.messagesSetValue(setValue: isStarred, forKey: Message.Attributes.isStarred)
    }
    
    func quickLookAttachment (localURL : NSURL, keyPackage:NSData, fileName:String) {
        if let data : NSData = NSData(contentsOfURL: localURL) {
            tempFileUri = NSFileManager.defaultManager().attachmentDirectory.URLByAppendingPathComponent(fileName);
            let decryptData = data.decryptAttachment(keyPackage, passphrase: sharedUserDataService.mailboxPassword!, publicKey: sharedUserDataService.userInfo!.publicKey, privateKey: sharedUserDataService.userInfo!.privateKey, error: nil)
            
            decryptData!.writeToURL(tempFileUri!, atomically: true)
            
            let previewQL = QuickViewViewController()
            previewQL.dataSource = self
            
            self.navigationController?.pushViewController(previewQL, animated: true)
            //self.presentViewController(previewQL, animated: true, completion: nil)
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


