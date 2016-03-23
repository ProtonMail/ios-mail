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


class MessageViewController: ProtonMailViewController, LablesViewControllerDelegate {
    
    /// message info
    var message: Message!
    
    ///
    var emailView: EmailView?
    
    ///
    private var actionTapped: ComposeMessageAction!
    private var fetchedMessageController: NSFetchedResultsController?
    
    @IBOutlet var backButton: UIBarButtonItem!
    
    private var bodyLoaded: Bool = false
    
    private var showedShowImageView : Bool = false
    private var isAutoLoadImage : Bool = false
    private var needShowShowImageView : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupRightButtons()
        
        if message == nil || message.managedObjectContext == nil {
            self.navigationController?.popViewControllerAnimated(true)
            return
        }
        self.isAutoLoadImage = !sharedUserDataService.showShowImageView
        self.setupFetchedResultsController(message.messageID)
        
        self.updateHeader()
        
        if (self.message.hasAttachments) {
            let atts = self.message.attachments.allObjects as! [Attachment]
            self.emailView?.updateEmailAttachment(atts);
        }
        
        self.emailView!.initLayouts()
        self.emailView!.bottomActionView.delegate = self
        self.emailView!.emailHeader.actionsDelegate = self
        
        showEmailLoading()
        message.fetchDetailIfNeeded() { _, _, msg, error in
            if error != nil {
                NSLog("\(__FUNCTION__) error: \(error)")
                self.updateEmailBodyWithError("Can't download message body, please try again.")
            }
            else
            {
                self.updateContent()
            }
        }
    }
    
    func updateContent () {
        self.updateEmailBody ()
    }
    
    override func loadView() {
        emailView = EmailView(frame: UIScreen.mainScreen().applicationFrame)
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
            labels : self.message.labels.allObjects as? [Label],
            
            showShowImages: self.needShowShowImageView,
            expiration: self.message.expirationTime
        )
    }
    
    func dismissed() {
        self.updateHeader();
        self.emailView?.emailHeader.updateHeaderLayout()
    }
    
    private func setupRightButtons() {
        var rightButtons: [UIBarButtonItem] = []
        rightButtons.append(UIBarButtonItem(image: UIImage(named: "top_more"), style: UIBarButtonItemStyle.Plain, target: self, action: "moreButtonTapped:"))
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
            if self.message.managedObjectContext != nil {
                self.messagesSetValue(setValue: MessageLocation.deleted.rawValue, forKey: Message.Attributes.locationNumber)
            }
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
    
    internal func moreButtonTapped(sender : UIBarButtonItem) {
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
        alertController.popoverPresentationController?.barButtonItem = sender
        alertController.popoverPresentationController?.sourceRect = self.view.frame
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toCompose" {
            let composeViewController = segue.destinationViewController as! ComposeEmailViewController
            composeViewController.viewModel = ComposeViewModelImpl(msg: message, action: self.actionTapped)
        } else if segue.identifier == "toApplyLabelsSegue" {
            let popup = segue.destinationViewController as! LablesViewController
            popup.viewModel = LabelViewModelImpl(msg: [self.message])
            popup.delegate = self
            self.setPresentationStyleForSelfController(self, presentingController: popup)
        }
    }
    
    override func shouldShowSideMenu() -> Bool {
        return false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "statusBarHit:", name: NotificationDefined.TouchStatusBar, object:nil)

        message.isRead = true
        message.needsUpdate = true
        if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
            NSLog("\(__FUNCTION__) error: \(error)")
        }
        
        self.emailView?.contentWebView.userInteractionEnabled = true;
        self.emailView?.contentWebView.becomeFirstResponder()
        
        self.setupExpirationTimer()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationDefined.TouchStatusBar, object:nil)
        self.stopExpirationTimer()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.updateEmailBody(force : true);
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
    
    
    
    private var timer : NSTimer!
    private func setupExpirationTimer()
    {
        if self.message.expirationTime != nil {
            self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "autoTimer", userInfo: nil, repeats: true)
            //self.timer.fire()
        }
    }
    
    private func stopExpirationTimer()
    {
        if self.timer != nil {
            self.timer.invalidate()
            self.timer = nil
        }
    }
    
    func autoTimer()
    {
        emailView?.emailHeader.updateExpirationDate(self.message.expirationTime)
        if let time = self.message.expirationTime {
            let offset = Int(time.timeIntervalSinceDate(NSDate()))
            if offset <= 0 {
                if self.message.managedObjectContext != nil {
                    self.message.isDetailDownloaded = false
                    self.message.managedObjectContext?.saveUpstreamIfNeeded()
                    //self.messagesSetValue(setValue: MessageLocation.deleted.rawValue, forKey: Message.Attributes.locationNumber)
                }
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
    }

    //
    var purifiedBody :  String? = nil
    var purifiedBodyWithoutImage :  String? = nil
    var bodyHasImages : Bool = false
    // MARK : private function
    private func updateEmailBody (force forceReload : Bool = false) {
        if (self.message.hasAttachments) {
            let atts = self.message.attachments.allObjects as! [Attachment]
            self.emailView?.updateEmailAttachment(atts);
        }
        //let offset = Int64(NSEC_PER_SEC) / 2
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            if (!self.bodyLoaded || forceReload) && self.emailView != nil {
                if self.message.isDetailDownloaded {  //&& forceReload == false
                    self.bodyLoaded = true
                    PMLog.D(self.message!.body);
                    if let body = self.purifiedBody {
                        
                    } else {
                        self.purifiedBody = self.purifyEmailBody(self.message)
                    }
                    
                    if !self.isAutoLoadImage && !self.showedShowImageView && self.purifiedBodyWithoutImage == nil {
                        println(self.purifiedBody)
                        if let pbody = self.purifiedBody {
                            self.bodyHasImages = pbody.hasImange()
                            if self.bodyHasImages == true {
                                self.purifiedBodyWithoutImage = pbody.stringByPurifyImages()
                            }
                        } else {
                            self.bodyHasImages = false
                        }
                        
                        if self.bodyHasImages {
                            self.needShowShowImageView = true
                        }
                    }
                }
            }
            if let body = self.purifiedBody {
                dispatch_async(dispatch_get_main_queue()) {
                    self.loadEmailBody(self.needShowShowImageView ? (self.purifiedBodyWithoutImage ?? (self.purifiedBody ?? "")) : (self.purifiedBody ?? ""))
                }
            }
        })
    }
    
    internal func purifyEmailBody(message : Message!) -> String?
    {
        var error: NSError?
        var bodyText = self.message.decryptBodyIfNeeded(&error) ?? NSLocalizedString("Unable to decrypt message.")
        bodyText = bodyText.stringByStrippingStyleHTML()
        bodyText = bodyText.stringByStrippingBodyStyle()
        bodyText = bodyText.stringByPurifyHTML()
        return bodyText
    }
    
    internal func showEmailLoading () {
        var body = NSLocalizedString("Loading...")
        let meta : String = "<meta name=\"viewport\" content=\"width=device-width, target-densitydpi=device-dpi, initial-scale=0.8\" content=\"yes\">"
        self.emailView?.updateEmailBody(body, meta: meta)
    }

    var contentLoaded = false
    internal func loadEmailBody(body : String) {
        let meta : String = "<meta name=\"viewport\" content=\"width=device-width, target-densitydpi=device-dpi, initial-scale=\(EmailView.kDefautWebViewScale)\" content=\"yes\">"
        self.emailView?.updateEmailBody(body, meta: meta)
        
        self.updateHeader()
        self.emailView?.emailHeader.updateAttConstraints(true)
    }
    
    // MARK : private function
    private func updateEmailBodyWithError (error:String) {
        if (self.message.hasAttachments) {
            let atts = self.message.attachments.allObjects as! [Attachment]
            self.emailView?.updateEmailAttachment(atts);
        }
        var bodyText = NSLocalizedString(error)
        let meta1 : String = "<meta name=\"viewport\" content=\"width=device-width, target-densitydpi=device-dpi, initial-scale=0.8\" content=\"yes\">"
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
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        self.emailView?.rotate()
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
extension MessageViewController : EmailHeaderActionsProtocol, UIDocumentInteractionControllerDelegate {
    
    func showImage() {
        self.showedShowImageView = true
        self.needShowShowImageView = false
        self.updateContent();
    }
    
    func starredChanged(isStarred: Bool) {
        self.messagesSetValue(setValue: isStarred, forKey: Message.Attributes.isStarred)
    }
    
    func quickLookAttachment (localURL : NSURL, keyPackage:NSData, fileName:String) {
        if let data : NSData = NSData(contentsOfURL: localURL) {
            tempFileUri = NSFileManager.defaultManager().attachmentDirectory.URLByAppendingPathComponent(fileName);
            var error: NSError?
            let decryptData = data.decryptAttachment(keyPackage, passphrase: sharedUserDataService.mailboxPassword!, error: &error)
            if error != nil {
                var alert = "Cant' decrypt this attachment!".alertController();
                alert.addOKAction()
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                decryptData!.writeToURL(tempFileUri!, atomically: true)

                let previewQL = QuickViewViewController()
                previewQL.dataSource = self
                self.presentViewController(previewQL, animated: true, completion: nil)
            }
        }
        else{
            var alert = "Can't find this attachment!".alertController();
            alert.addOKAction()
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func documentInteractionControllerViewControllerForPreview(controller: UIDocumentInteractionController) -> UIViewController {
        return self
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


