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
import PassKit
import Crashlytics
import Fabric

class MessageViewController: ProtonMailViewController, ViewModelProtocol{
    
    fileprivate let kToComposerSegue : String    = "toCompose"
    fileprivate let kSegueMoveToFolders : String = "toMoveToFolderSegue"
    fileprivate let kSegueToApplyLabels : String = "toApplyLabelsSegue"
    
    /// message info
    var message: Message!
    
    ///
    var emailView: EmailView?
    
    ///
    fileprivate var URL : NSURL?
    
    @IBOutlet var backButton: UIBarButtonItem!
    
    ///
    private var bodyLoaded: Bool                             = false
    fileprivate var showedShowImageView : Bool               = false
    private var isAutoLoadImage : Bool                       = false
    fileprivate var needShowShowImageView : Bool             = false
    private var actionTapped : Bool                          = false
    fileprivate var latestPresentedView : UIViewController?  = nil
    //not in used
    func setViewModel(_ vm: Any) {
    }
    
    func inactiveViewModel() {
        latestPresentedView?.dismiss(animated: true, completion: nil)
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupRightButtons()
        
        if message == nil || message.managedObjectContext == nil {
            popViewController()
            return
        }
        self.isAutoLoadImage = !sharedUserDataService.showShowImageView
        
        self.updateHeader()
        
        if (self.message.numAttachments.int32Value > 0) {
            let atts = self.message.attachments.allObjects as! [Attachment]
            self.emailView?.updateEmailAttachment(atts);
        }
        
        self.emailView!.initLayouts()
        self.emailView!.bottomActionView.delegate = self
        self.emailView!.emailHeader.actionsDelegate = self
        self.emailView!.topMessageView.delegate = self
        self.emailView?.viewDelegate = self
        self.emailView?.emailHeader.updateAttConstraints(false)
        self.updateBadgeNumberWhenRead(message, changeToRead: true)
        loadMessageDetailes()
        
    }
    
    internal func loadMessageDetailes () {
        showEmailLoading()
        if !message.isDetailDownloaded && sharedInternetReachability.currentReachabilityStatus() == NotReachable {
            self.emailView?.showNoInternetErrorMessage()
            self.updateEmailBodyWithError(NSLocalizedString("No connectivity detected...", comment: "Error"))
        } else {
            message.fetchDetailIfNeeded() { _, _, msg, error in
                if let error = error {
                    let code = error.code
                    if code == NSURLErrorTimedOut {
                        self.emailView?.showTimeOutErrorMessage()
                        self.updateEmailBodyWithError(NSLocalizedString("The request timed out.", comment: "Error"))
                    } else if code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorCannotConnectToHost {
                        self.emailView?.showNoInternetErrorMessage()
                        self.updateEmailBodyWithError(NSLocalizedString("No connectivity detected...", comment: "Error"))
                    } else if code == APIErrorCode.API_offline {
                        self.emailView?.showErrorMessage(error.localizedDescription)
                        self.updateEmailBodyWithError(error.localizedDescription)
                    } else if code == APIErrorCode.HTTP503 || code == NSURLErrorBadServerResponse {
                        self.emailView?.showErrorMessage(NSLocalizedString("API Server not reachable...", comment: "Error"))
                        self.updateEmailBodyWithError(NSLocalizedString("API Server not reachable...", comment: "Error"))
                    } else if code < 0{
                        self.emailView?.showErrorMessage(NSLocalizedString("Can't download message body, please try again.", comment: "Error"))
                        self.updateEmailBodyWithError(NSLocalizedString("Can't download message body, please try again.", comment: "Error"))
                    } else {
                        self.emailView?.showErrorMessage(NSLocalizedString("Can't download message body, please try again.", comment: "Error"))
                        self.updateEmailBodyWithError(NSLocalizedString("Can't download message body, please try again.", comment: "Error"))
                    }
                    PMLog.D("error: \(error)")
                }
                else
                {
                    self.updateContent()
                    //self.showEmbedImage()
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
    
    @objc internal func reachabilityChanged(_ note : Notification) {
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
    
    internal func updateInterfaceWithReachability(_ reachability : Reachability) {
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
        emailView = EmailView(frame: UIScreen.main.applicationFrame)
        self.view = emailView
    }
    
    fileprivate func updateHeader() {
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
                                             expiration: self.message.expirationTime,
                                             score: self.message.getScore()
            )
        } else {
            PMLog.D(" MessageViewController self.message.managedObjectContext == nil")
        }
    }
    
    func test() {
        performSegue(withIdentifier: "toLabelManagerSegue", sender: self)
    }
    
    fileprivate func setupRightButtons() {
        var rightButtons: [UIBarButtonItem] = []
        rightButtons.append(UIBarButtonItem(image: UIImage(named: "top_more"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(MessageViewController.moreButtonTapped(_:))))
        rightButtons.append(UIBarButtonItem(image: UIImage(named: "top_trash"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(MessageViewController.removeButtonTapped)))
        rightButtons.append(UIBarButtonItem(image: UIImage(named: "top_folder"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(MessageViewController.folderButtonTapped)))
        rightButtons.append(UIBarButtonItem(image: UIImage(named: "top_label"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(MessageViewController.labelButtonTapped)))
        rightButtons.append(UIBarButtonItem(image: UIImage(named: "top_unread"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(MessageViewController.unreadButtonTapped)))
        
        self.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
    }
    
    @objc internal func unreadButtonTapped() {
        if !actionTapped {
            actionTapped = true
            messagesSetRead(isRead: false)
            self.popViewController()
        }
    }
    
    internal func popViewController() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.actionTapped = false
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc internal func removeButtonTapped() {
        if !actionTapped {
            actionTapped = true
            switch(message.location) {
            case .trash, .spam:
                if self.message.managedObjectContext != nil {
                    self.message.removeLocationFromLabels(currentlocation: message.location, location: MessageLocation.deleted, keepSent: true)
                    self.messagesSetValue(setValue: MessageLocation.deleted.rawValue, forKey: Message.Attributes.locationNumber)
                }
            default:
                self.message.removeLocationFromLabels(currentlocation: message.location, location: MessageLocation.trash, keepSent: true)
                self.messagesSetValue(setValue: MessageLocation.trash.rawValue, forKey: Message.Attributes.locationNumber)
            }
            popViewController()
        }
    }
    
    @objc internal func labelButtonTapped() {
        self.performSegue(withIdentifier: kSegueToApplyLabels, sender: self)
    }
    @objc internal func folderButtonTapped() {
        self.performSegue(withIdentifier: kSegueMoveToFolders, sender: self)
    }
    internal func spamButtonTapped() {
        if !actionTapped {
            actionTapped = true
            
            self.message.removeLocationFromLabels(currentlocation: message.location, location: MessageLocation.spam, keepSent: true)
            message.needsUpdate = true
            message.location = .spam
            if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
                PMLog.D(" error: \(error)")
            }
            popViewController()
        }
    }
    
    @objc internal func moreButtonTapped(_ sender : UIBarButtonItem) {        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Action"), style: .cancel, handler: nil))
        let locations: [MessageLocation : UIAlertActionStyle] = [.inbox : .default, .spam : .default, .archive : .default]
        for (location, style) in locations {
            if !message.hasLocation(location: location) {
                if self.message.location == .outbox && location == .inbox {
                    continue
                }
                
                alertController.addAction(UIAlertAction(title: location.actionTitle, style: style, handler: { (action) -> Void in
                    self.message.removeLocationFromLabels(currentlocation: self.message.location, location: location, keepSent: true)
                    self.messagesSetValue(setValue: location.rawValue, forKey: Message.Attributes.locationNumber)
                    self.popViewController()
                }))
            }
        }
        
//        alertController.addAction(UIAlertAction(title:NSLocalizedString("Print", comment: "Action"), style: .default, handler: { (action) -> Void in
//            self.print(webView : self.emailView!.contentWebView)
//        }))
        
        alertController.popoverPresentationController?.barButtonItem = sender
        alertController.popoverPresentationController?.sourceRect = self.view.frame
        
        latestPresentedView = alertController
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    fileprivate func print(webView : UIWebView) {
        //TODO:: here need reformat the size.
        let render = UIPrintPageRenderer()
        render.addPrintFormatter(webView.viewPrintFormatter(), startingAtPageAt: 0);
        
        // 4. Create PDF context and draw
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect.zero, nil)
        
        let bounds = UIGraphicsGetPDFContextBounds()
        let page = CGRect(x: 0, y: 10, width:bounds.width, height: bounds.height) // webView.frame.size.width, height: webView.frame.size.height) // take the size of the webView
        let printable = page.insetBy(dx: 0, dy: 0)
        render.setValue(NSValue(cgRect: page), forKey: "paperRect")
        render.setValue(NSValue(cgRect: printable), forKey: "printableRect")
        for i in 1...render.numberOfPages {
            UIGraphicsBeginPDFPage();
            PMLog.D("\(bounds)")
            render.drawPage(at: i - 1, in: bounds)
        }
        UIGraphicsEndPDFContext();
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        PMLog.D(documentsPath)
        pdfData.write(toFile: "\(documentsPath)/pdfName.pdf", atomically: true)
        //TODO:: then open as pdf
//        self.pdfPath = "\(documentsPath)/pdfName.pdf"
//        self.pdfTitle = "pdfName"
//        self.performSegue(withIdentifier: "showPDFSegue", sender: nil)
    }
    
    fileprivate func messagesSetValue(setValue value: Any?, forKey key: String) {
        if let context = message.managedObjectContext {
            message.setValue(value, forKey: key)
            message.setValue(true, forKey: "needsUpdate")
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D(" error: \(error)")
            }
        }
    }
    
    fileprivate func messagesSetRead(isRead: Bool) {
        if let context = message.managedObjectContext {
            self.updateBadgeNumberWhenRead(message, changeToRead: isRead)
            message.isRead = isRead
            message.needsUpdate = true
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D(" error: \(error)")
            }
        }
    }
    
    func updateBadgeNumberWhenRead(_ message : Message, changeToRead : Bool) {
        let location = message.location
        
        if message.isRead == changeToRead {
            return
        }
        var count = lastUpdatedStore.UnreadCountForKey(location)
        count = count + (changeToRead ? -1 : 1)
        if count < 0 {
            count = 0
        }
        lastUpdatedStore.updateUnreadCountForKey(location, count: count)
        
        if message.isStarred {
            var staredCount = lastUpdatedStore.UnreadCountForKey(.starred)
            staredCount = staredCount + (changeToRead ? -1 : 1)
            if staredCount < 0 {
                staredCount = 0
            }
            lastUpdatedStore.updateUnreadCountForKey(.starred, count: staredCount)
        }
        if location == .inbox {
            UIApplication.setBadge(badge: count)
        }
    }
    
    override var shouldAutorotate : Bool {
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kToComposerSegue {
            if let enumRaw = sender as? Int, let tapped = ComposeMessageAction(rawValue: enumRaw), tapped != .newDraft{
                let composeViewController = segue.destination as! ComposeEmailViewController
                sharedVMService.actionDraftViewModel(composeViewController, msg: message, action: tapped)
            } else {
                let composeViewController = segue.destination as! ComposeEmailViewController
                sharedVMService.newDraftViewModelWithMailTo(composeViewController, url: self.URL as URL?)
            }
        } else if segue.identifier == kSegueToApplyLabels {
            let popup = segue.destination as! LablesViewController
            popup.viewModel = LabelApplyViewModelImpl(msg: [self.message])
            popup.delegate = self
            self.setPresentationStyleForSelfController(self, presentingController: popup)
        } else if segue.identifier == kSegueMoveToFolders {
            let popup = segue.destination as! LablesViewController
            popup.delegate = self
            popup.viewModel = FolderApplyViewModelImpl(msg: [self.message])
            self.setPresentationStyleForSelfController(self, presentingController: popup)
        }
    }
    
    override func shouldShowSideMenu() -> Bool {
        return false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        
        NotificationCenter.default.addObserver(self, selector: #selector(MessageViewController.statusBarHit(_:)), name: NSNotification.Name(rawValue: NotificationDefined.TouchStatusBar), object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MessageViewController.reachabilityChanged(_:)), name: NSNotification.Name.reachabilityChanged, object: nil)
        
        if message != nil {
            if let context = message.managedObjectContext {
                message.isRead = true
                message.needsUpdate = true
                if let error = context.saveUpstreamIfNeeded() {
                    PMLog.D(" error: \(error)")
                }
            }
        }
        
        self.emailView?.contentWebView.isUserInteractionEnabled = true;
        self.emailView?.contentWebView.becomeFirstResponder()
        
        self.setupExpirationTimer()
        
        self.updateHeader()
        self.emailView?.emailHeader.updateAttConstraints(false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationDefined.TouchStatusBar), object:nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.reachabilityChanged, object:nil)
        self.stopExpirationTimer()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if ProcessInfo().operatingSystemVersion.majorVersion == 9 {
            cleanSelector();
        }
    }
    
    @objc internal func statusBarHit (_ notify: Notification) {
        self.emailView?.contentWebView.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    
    fileprivate var timer : Timer!
    fileprivate func setupExpirationTimer()
    {
        if self.message.expirationTime != nil {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(MessageViewController.autoTimer), userInfo: nil, repeats: true)
            //self.timer.fire()
        }
    }
    
    internal func cleanSelector() {
        self.updateEmailBody(force: true)
    }
    
    fileprivate func stopExpirationTimer()
    {
        if self.timer != nil {
            self.timer.invalidate()
            self.timer = nil
        }
    }
    
    @objc func autoTimer()
    {
        emailView?.emailHeader.updateExpirationDate(self.message.expirationTime)
        if let time = self.message.expirationTime {
            let offset = Int(time.timeIntervalSince(Date()))
            if offset <= 0 {
                if self.message.managedObjectContext != nil {
                    self.message.isDetailDownloaded = false
                    let _ = self.message.managedObjectContext?.saveUpstreamIfNeeded()
                }
                popViewController()
            }
        }
    }
    
    fileprivate var purifiedBodyLock: Int = 0
    fileprivate var fixedBody : String? = nil
    fileprivate var bodyHasImages : Bool = false
    
    // MARK : private function
    fileprivate func updateEmailBody (force forceReload : Bool = false) {
        if (self.message.numAttachments.int32Value > 0) {
            let atts = self.message.attachments.allObjects as! [Attachment]
            self.emailView?.updateEmailAttachment(atts);
        }
        self.updateHeader()
        self.emailView?.emailHeader.updateAttConstraints(true)
        
        //let offset = Int64(NSEC_PER_SEC) / 2
       DispatchQueue.global(qos:.default).asyncAfter(deadline: DispatchTime.now() + Double(0) / Double(NSEC_PER_SEC), execute: { () -> Void in
            if (!self.bodyLoaded || forceReload) && self.emailView != nil {
                if self.message.isDetailDownloaded {  //&& forceReload == false
                    self.bodyLoaded = true
                    
                    if self.fixedBody == nil {
                        self.fixedBody = self.purifyEmailBody(self.message, autoloadimage: self.isAutoLoadImage)
                        DispatchQueue.main.async {
                            self.showEmbedImage()
                        }
                    }
                    
                    if !self.isAutoLoadImage && !self.showedShowImageView{
                        if self.bodyHasImages {
                            self.needShowShowImageView = true
                        }
                    }
                }
            }
            if self.fixedBody != nil {
                DispatchQueue.main.async {
                    self.loadEmailBody(self.fixedBody ?? "")
                }
            }
        })
    }
    
    internal func purifyEmailBody(_ message : Message!, autoloadimage : Bool) -> String?
    {
        do {
            var bodyText = try self.message.decryptBodyIfNeeded() ?? NSLocalizedString("Unable to decrypt message.", comment: "Error")
            bodyText = bodyText.stringByStrippingBodyStyle()
            bodyText = bodyText.stringByPurifyHTML()
            self.bodyHasImages = bodyText.hasImage()
            if !autoloadimage {
                bodyText = bodyText.stringByPurifyImages()
            }
            return bodyText
        } catch let ex as NSError {
            PMLog.D("purifyEmailBody error : \(ex)")
            return self.message.bodyToHtml()
        }
    }
    
    internal func showEmailLoading () {
        let body = NSLocalizedString("Loading...", comment: "")
        let meta : String = "<meta name=\"viewport\" content=\"width=device-width, target-densitydpi=device-dpi, initial-scale=1.0\" content=\"yes\">"
        self.emailView?.updateEmailBody(body, meta: meta)
    }
    
    var contentLoaded = false
    internal func loadEmailBody(_ body : String) {
        let meta : String = "<meta name=\"viewport\" content=\"width=device-width, target-densitydpi=device-dpi, initial-scale=\(emailView?.kDefautWebViewScale ?? 0.9)\" content=\"yes\">"
        self.emailView?.updateEmailBody(body, meta: meta)
        
        self.updateHeader()
        self.emailView?.emailHeader.updateAttConstraints(true)
    }
    
    // MARK : private function
    fileprivate func updateEmailBodyWithError (_ error:String) {
        if (self.message.numAttachments.int32Value > 0 ) {
            let atts = self.message.attachments.allObjects as! [Attachment]
            self.emailView?.updateEmailAttachment(atts);
        }
        let bodyText = NSLocalizedString(error, comment: "")
        let meta1 : String = "<meta name=\"viewport\" content=\"width=device-width, target-densitydpi=device-dpi, initial-scale=1.0\" content=\"yes\">"
        
        self.emailView?.updateEmailBody(bodyText, meta: meta1)
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        self.emailView?.rotate()
    }
}

extension MessageViewController : LablesViewControllerDelegate {
    
    func dismissed() {
        self.updateHeader();
        self.emailView?.emailHeader.updateHeaderLayout()
    }
    
    func apply(type: LabelFetchType) {
        if type == .folder {
            popViewController()
        }
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
            self.performSegue(withIdentifier: kToComposerSegue, sender: ComposeMessageAction.reply.rawValue)
        } else {
            self.showAlertWhenNoDetails()
        }
    }
    
    func replyAllClicked() {
        if self.message.isDetailDownloaded {
            self.performSegue(withIdentifier: kToComposerSegue, sender: ComposeMessageAction.replyAll.rawValue)
        } else {
            self.showAlertWhenNoDetails()
        }
    }
    
    func forwardClicked() {
        if self.message.isDetailDownloaded {
            self.performSegue(withIdentifier: kToComposerSegue, sender: ComposeMessageAction.forward.rawValue)
        } else {
            self.showAlertWhenNoDetails()
        }
    }
    
    func showAlertWhenNoDetails() {
        let alert = NSLocalizedString("Please wait until the email downloaded!", comment: "The").alertController();
        alert.addOKAction()
        latestPresentedView = alert
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK

extension MessageViewController :  EmailViewProtocol {
    
    func mailto(_ url: Foundation.URL?) {
        URL = url as NSURL?
        self.performSegue(withIdentifier: kToComposerSegue, sender: ComposeMessageAction.newDraft.rawValue)
    }
}


// MARK
fileprivate var tempFileUri : URL?
extension MessageViewController : EmailHeaderActionsProtocol, UIDocumentInteractionControllerDelegate {
    
    func showImage() {
        self.showedShowImageView = true
        self.needShowShowImageView = false
        self.fixedBody = self.fixedBody?.stringFixImages()
        self.updateContent()
    }
    
    func showEmbedImage() {
        if let atts = self.message.attachments.allObjects as? [Attachment] {
            var checkCount = atts.count
            for att in atts {
                if let content_id = att.contentID(), !content_id.isEmpty && att.inline() {
                    att.base64AttachmentData({ (based64String) in
                        if !based64String.isEmpty {
                            objc_sync_enter(self.purifiedBodyLock)
                            self.fixedBody = self.fixedBody?.stringBySetupInlineImage("src=\"cid:\(content_id)\"", to: "src=\"data:\(att.mimeType);base64,\(based64String)\"" )
                            objc_sync_exit(self.purifiedBodyLock)
                            checkCount = checkCount - 1
                            
                            if checkCount == 0 {
                                self.updateContent()
                            }
                            
                        } else {
                            checkCount = checkCount - 1
                        }
                    })
                } else {
                    checkCount = checkCount - 1
                }
            }
        }
    }
    
    func starredChanged(_ isStarred: Bool) {
        if isStarred {
            self.message.setLabelLocation(.starred)
            if let context = message.managedObjectContext {
                context.perform {
                    if let error = context.saveUpstreamIfNeeded() {
                        PMLog.D("error: \(error)")
                    }
                }
            }
        } else {
            self.message.removeLocationFromLabels(currentlocation: .starred, location: .deleted, keepSent: true)
        }
        self.messagesSetValue(setValue: isStarred, forKey: Message.Attributes.isStarred)
    }
    
    func quickLookAttachment (_ localURL : Foundation.URL, keyPackage:Data, fileName:String, type: String) {
        if let data : Data = try? Data(contentsOf: localURL) {
            do {
                tempFileUri = FileManager.default.attachmentDirectory.appendingPathComponent(fileName)
                if let decryptData = try data.decryptAttachment(keyPackage, passphrase: sharedUserDataService.mailboxPassword!) {
                    try? decryptData.write(to: tempFileUri!, options: [.atomic])
                    //TODO:: the hard code string need change it to enum later
                    if (type == "application/vnd.apple.pkpass" || fileName.contains(check: ".pkpass") == true),
                        let pkfile = try? Data(contentsOf: tempFileUri!) {
                        var error : NSError? = nil
                        let pass : PKPass = PKPass(data: pkfile, error: &error)
                        if error != nil {
                            let previewQL = QuickViewViewController()
                            previewQL.dataSource = self
                            latestPresentedView = previewQL
                            self.present(previewQL, animated: true, completion: nil)
                        } else {
                            let vc = PKAddPassesViewController(pass: pass) as PKAddPassesViewController
                            self.present(vc, animated: true, completion: nil)
                        }
                    } else {
                        let previewQL = QuickViewViewController()
                        previewQL.dataSource = self
                        latestPresentedView = previewQL
                        self.present(previewQL, animated: true, completion: nil)
                    }
                }
            } catch let ex as NSError {
                PMLog.D("quickLookAttachment error : \(ex)")
                let alert = NSLocalizedString("Can't decrypt this attachment!", comment: "When quick look attachment but can't decrypt it!").alertController();
                alert.addOKAction()
                latestPresentedView = alert
                self.present(alert, animated: true, completion: nil)
            }
        } else{
            let alert = NSLocalizedString("Can't find this attachment!", comment: "when quick look attachment but can't find the data").alertController();
            alert.addOKAction()
            latestPresentedView = alert
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
}

extension MessageViewController : QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        //TODO :: fix here
        return tempFileUri! as QLPreviewItem
    }
}


