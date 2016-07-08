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
import CoreData


class MessageViewController: ProtonMailViewController, LablesViewControllerDelegate {
    
    /// message info
    var message: Message!
    
    ///
    var emailView: EmailView?
    
    ///
    private var URL : NSURL?
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
        self.emailView!.topMessageView.delegate = self
        self.emailView?.viewDelegate = self
        self.emailView?.emailHeader.updateAttConstraints(false)
        loadMessageDetailes()
    }

    internal func loadMessageDetailes () {
        showEmailLoading()
        if !message.isDetailDownloaded && sharedInternetReachability.currentReachabilityStatus() == NotReachable {
            self.emailView?.showNoInternetErrorMessage()
            self.updateEmailBodyWithError("No connectivity detected...")
        } else {
            message.fetchDetailIfNeeded() { _, _, msg, error in
                if let error = error {
                    if error.code == NSURLErrorTimedOut {
                        self.emailView?.showTimeOutErrorMessage()
                        self.updateEmailBodyWithError("The request timed out.")
                    } else if error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorCannotConnectToHost {
                        self.emailView?.showNoInternetErrorMessage()
                        self.updateEmailBodyWithError("No connectivity detected...")
                    } else if error.code < 0{
                        self.emailView?.showErrorMessage("Can't download message body, please try again.")
                        self.updateEmailBodyWithError("Can't download message body, please try again.")
                    } else {
                        self.emailView?.showErrorMessage("Save message body failed, please try again.")
                        self.updateEmailBodyWithError("Save message body failed, please try again.")
                    }
                    PMLog.D("error: \(error)")
                }
                else
                {
                    self.updateContent()
                }
            }
        }
    }
    
    internal func recheckMessageDetails () {
        self.emailView?.hideTopMessage()
        delay(0.5) {
            if !self.message.isDetailDownloaded {
                self.loadMessageDetailes ()
            }
        }
    }
    
    internal func reachabilityChanged(note : NSNotification) {
        if let curReach = note.object as? Reachability {
            self.updateInterfaceWithReachability(curReach)
        } else {
//            if let status = note.object as? Int {
//                PMLog.D("\(status)")
//                if status == 0 { //time out
//                    showTimeOutErrorMessage()
//                } else if status == 1 { //not reachable
//                    showNoInternetErrorMessage()
//                }
//            }
        }
    }
    
    internal func updateInterfaceWithReachability(reachability : Reachability) {
        let netStatus = reachability.currentReachabilityStatus()
        let connectionRequired = reachability.connectionRequired()
        PMLog.D("connectionRequired : \(connectionRequired)")
        switch (netStatus)
        {
        case NotReachable:
            PMLog.D("Access Not Available")
            if !message.isDetailDownloaded {
                self.emailView?.showNoInternetErrorMessage()
            }
        case ReachableViaWWAN:
            PMLog.D("Reachable WWAN")
            recheckMessageDetails ()
        case ReachableViaWiFi:
            PMLog.D("Reachable WiFi")
            recheckMessageDetails ()
        default:
            PMLog.D("Reachable default unknow")
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
        if self.message.managedObjectContext != nil {
            self.emailView?.updateHeaderData(self.message.subject,
                sender: self.message.senderContactVO,
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
        } else {
            PMLog.D(" MessageViewController self.message.managedObjectContext == nil")
        }
    }
    
    func dismissed() {
        self.updateHeader();
        self.emailView?.emailHeader.updateHeaderLayout()
    }
    
    private func setupRightButtons() {
        var rightButtons: [UIBarButtonItem] = []
        rightButtons.append(UIBarButtonItem(image: UIImage(named: "top_more"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MessageViewController.moreButtonTapped(_:))))
        rightButtons.append(UIBarButtonItem(image: UIImage(named: "top_trash"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MessageViewController.removeButtonTapped)))
        rightButtons.append(UIBarButtonItem(image: UIImage(named: "top_label"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MessageViewController.labelButtonTapped)))
        rightButtons.append(UIBarButtonItem(image: UIImage(named: "top_unread"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MessageViewController.unreadButtonTapped)))
        
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
            PMLog.D(" error: \(error)")
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
        if let context = message.managedObjectContext {
            message.setValue(value, forKey: key)
            message.setValue(true, forKey: "needsUpdate")
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D(" error: \(error)")
            }
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toCompose" {
            if self.actionTapped == .NewDraft {
                let composeViewController = segue.destinationViewController as! ComposeEmailViewController
                sharedVMService.newDraftViewModelWithMailTo(composeViewController, url: self.URL)
            } else {
                let composeViewController = segue.destinationViewController as! ComposeEmailViewController
                sharedVMService.actionDraftViewModel(composeViewController, msg: message, action: self.actionTapped)
            }
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MessageViewController.statusBarHit(_:)), name: NotificationDefined.TouchStatusBar, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MailboxViewController.reachabilityChanged(_:)), name: kReachabilityChangedNotification, object: nil)
        if let context = message.managedObjectContext {
            message.isRead = true
            message.needsUpdate = true
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D(" error: \(error)")
            }
        }
        
        self.emailView?.contentWebView.userInteractionEnabled = true;
        self.emailView?.contentWebView.becomeFirstResponder()
        
        self.setupExpirationTimer()
        
        self.updateHeader()
        self.emailView?.emailHeader.updateAttConstraints(false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationDefined.TouchStatusBar, object:nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kReachabilityChangedNotification, object:nil)
        self.stopExpirationTimer()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if NSProcessInfo().operatingSystemVersion.majorVersion == 9 {
            cleanSelector();
        }
    }
    
    internal func statusBarHit (notify: NSNotification) {
        self.emailView?.contentWebView.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    
    private var timer : NSTimer!
    private func setupExpirationTimer()
    {
        if self.message.expirationTime != nil {
            self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(MessageViewController.autoTimer), userInfo: nil, repeats: true)
            //self.timer.fire()
        }
    }
    
    internal func cleanSelector() {
        self.updateEmailBody(force: true)
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
        self.updateHeader()
        self.emailView?.emailHeader.updateAttConstraints(true)
        
        //let offset = Int64(NSEC_PER_SEC) / 2
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            if (!self.bodyLoaded || forceReload) && self.emailView != nil {
                if self.message.isDetailDownloaded {  //&& forceReload == false
                    self.bodyLoaded = true
                    //PMLog.D(self.message!.body);
                    if self.purifiedBody == nil {
                        self.purifiedBody = self.purifyEmailBody(self.message)
                    }
                    
                    if !self.isAutoLoadImage && !self.showedShowImageView && self.purifiedBodyWithoutImage == nil {
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
            if self.purifiedBody != nil {
                dispatch_async(dispatch_get_main_queue()) {
                    self.loadEmailBody(self.needShowShowImageView ? (self.purifiedBodyWithoutImage ?? (self.purifiedBody ?? "")) : (self.purifiedBody ?? ""))
                }
            }
        })
    }
    
    internal func purifyEmailBody(message : Message!) -> String?
    {
        do {
            var bodyText = try self.message.decryptBodyIfNeeded() ?? NSLocalizedString("Unable to decrypt message.")
            PMLog.D(bodyText)
            //bodyText = bodyText.stringByStrippingStyleHTML()
            bodyText = bodyText.stringByPurifyHTML()
            bodyText = bodyText.stringByStrippingBodyStyle()
            return bodyText
        } catch let ex as NSError {
            PMLog.D("purifyEmailBody error : \(ex)")
            return self.message.bodyToHtml()
        }
    }
    
    internal func showEmailLoading () {
        let body = NSLocalizedString("Loading...")
        let meta : String = "<meta name=\"viewport\" content=\"width=device-width, target-densitydpi=device-dpi, initial-scale=1.0\" content=\"yes\">"
        self.emailView?.updateEmailBody(body, meta: meta)
    }

    var contentLoaded = false
    internal func loadEmailBody(body : String) {
        let meta : String = "<meta name=\"viewport\" content=\"width=device-width, target-densitydpi=device-dpi, initial-scale=\(emailView?.kDefautWebViewScale ?? 0.9)\" content=\"yes\">"
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
        let bodyText = NSLocalizedString(error)
        let meta1 : String = "<meta name=\"viewport\" content=\"width=device-width, target-densitydpi=device-dpi, initial-scale=1.0\" content=\"yes\">"

        self.emailView?.updateEmailBody(bodyText, meta: meta1)
    }
    
    private func setupFetchedResultsController(msg_id:String) {
        self.fetchedMessageController = sharedMessageDataService.fetchedMessageControllerForID(msg_id)
        if let fetchedMessageController = fetchedMessageController {
            do {
                try fetchedMessageController.performFetch()
            } catch let ex as NSError {
                PMLog.D("error: \(ex)")
            }
        }
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        self.emailView?.rotate()
    }
}

extension MessageViewController : TopMessageViewDelegate {
    
    func close() {
        self.emailView?.hideTopMessage()
    }
    
    func retry() {
        self.recheckMessageDetails ()
    }
}

// MARK
extension MessageViewController : MessageDetailBottomViewProtocol {
    
    func replyClicked() {
        if self.message.isDetailDownloaded {
            self.actionTapped = ComposeMessageAction.Reply
            self.performSegueWithIdentifier("toCompose", sender: self)
        } else {
            self.showAlertWhenNoDetails()
        }
    }
    
    func replyAllClicked() {
        if self.message.isDetailDownloaded {
            actionTapped = ComposeMessageAction.ReplyAll
            self.performSegueWithIdentifier("toCompose", sender: self)
        } else {
            self.showAlertWhenNoDetails()
        }
    }
    
    func forwardClicked() {
        if self.message.isDetailDownloaded {
            actionTapped = ComposeMessageAction.Forward
            self.performSegueWithIdentifier("toCompose", sender: self)
        } else {
            self.showAlertWhenNoDetails()
        }
    }
    
    func showAlertWhenNoDetails() {
        let alert = NSLocalizedString("Please wait until the email downloaded!").alertController();
        alert.addOKAction()
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

// MARK

extension MessageViewController :  EmailViewProtocol {

    func mailto(url: NSURL?) {
        URL = url
        actionTapped = ComposeMessageAction.NewDraft
        self.performSegueWithIdentifier("toCompose", sender: self)
    }
}


// MARK
private var tempFileUri : NSURL?
extension MessageViewController : EmailHeaderActionsProtocol, UIDocumentInteractionControllerDelegate {
    
    func showImage() {
        self.showedShowImageView = true
        self.needShowShowImageView = false
        self.showEmbedImage()
        self.updateContent()
    }
    
    func updateEmailEmbedImage(att: Attachment) {
        //self.purifiedBody.
        //src="cid:jira-generated-image-avatar-d97f1fd2-bc86-460e-921f-d7a7790c26dc"
        if let localURL = att.localURL {
            if let data : NSData = NSData(contentsOfURL: localURL) {
                do {
                    if let key_packet = att.keyPacket {
                        if let keydata: NSData = NSData(base64EncodedString:key_packet, options: NSDataBase64DecodingOptions(rawValue: 0)) {
                            if let decryptData = try data.decryptAttachment(keydata, passphrase: sharedUserDataService.mailboxPassword!) {
                                if let content_id = att.getContentID() {
                                    let strBase64:String = decryptData.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
                                    self.purifiedBody = self.purifiedBody?.stringBySetupInlineImage("src=\"cid:\(content_id)\"", to: "src=\"data:\(att.mimeType);base64,\(strBase64)\"" )
                                    
                                    self.updateContent()
                                }
                            }
                        }
                    }
                    
                    
                } catch let ex as NSError{
                    PMLog.D("\(ex)")
                }
            }
        }

    }
    
    func showEmbedImage() {
        
        if let atts = self.message.attachments.allObjects as? [Attachment] {
            for att in atts {
                if let localURL = att.localURL where NSFileManager.defaultManager().fileExistsAtPath(localURL.path!, isDirectory: nil) {
                    PMLog.D(localURL)
                    self.updateEmailEmbedImage(att)
                } else {
                    att.localURL = nil
                    sharedMessageDataService.fetchAttachmentForAttachment(att, downloadTask: { (taskOne : NSURLSessionDownloadTask) -> Void in
                        }, completion: { (_, url, error) -> Void in
                            if let localURL = att.localURL {
                                if NSFileManager.defaultManager().fileExistsAtPath(att.localURL!.path!, isDirectory: nil) {
                                    PMLog.D("\(localURL)")
                                    self.updateEmailEmbedImage(att)
                                }
                            }
                    })
                }
            }
        }
    }

    func starredChanged(isStarred: Bool) {
        self.messagesSetValue(setValue: isStarred, forKey: Message.Attributes.isStarred)
    }
    
    func quickLookAttachment (localURL : NSURL, keyPackage:NSData, fileName:String) {
        PMLog.D(localURL)
        if let data : NSData = NSData(contentsOfURL: localURL) {
            do {
                tempFileUri = NSFileManager.defaultManager().attachmentDirectory.URLByAppendingPathComponent(fileName)
                if let decryptData = try data.decryptAttachment(keyPackage, passphrase: sharedUserDataService.mailboxPassword!) {
                    decryptData.writeToURL(tempFileUri!, atomically: true)
                    let previewQL = QuickViewViewController()
                    previewQL.dataSource = self
                    self.presentViewController(previewQL, animated: true, completion: nil)
                }
            } catch {
                let alert = NSLocalizedString("Cant' decrypt this attachment!").alertController();
                alert.addOKAction()
                self.presentViewController(alert, animated: true, completion: nil)
            }
        } else{
            let alert = NSLocalizedString("Can't find this attachment!").alertController();
            alert.addOKAction()
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func documentInteractionControllerViewControllerForPreview(controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
}

extension MessageViewController : QLPreviewControllerDataSource {
    func numberOfPreviewItemsInPreviewController(controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(controller: QLPreviewController, previewItemAtIndex index: Int) -> QLPreviewItem {
        //TODO :: fix here
        return tempFileUri!
    }
}


