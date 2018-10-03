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
import AwaitKit
import PromiseKit

class MessageViewController: ProtonMailViewController, ViewModelProtocol {
    
    
    fileprivate let kToComposerSegue : String    = "toCompose"
    fileprivate let kSegueMoveToFolders : String = "toMoveToFolderSegue"
    fileprivate let kSegueToApplyLabels : String = "toApplyLabelsSegue"
    fileprivate let kToAddContactSegue : String  = "toAddContact"
    
    /// message info
    var message: Message!
    
    ///
    var emailView: EmailView?
    
    ///
    fileprivate var url : URL?
    
    @IBOutlet var backButton: UIBarButtonItem!
    
    ///
    private var bodyLoaded: Bool                             = false
    fileprivate var showedShowImageView : Bool               = false
    private var isAutoLoadImage : Bool                       = false
    fileprivate var needShowShowImageView : Bool             = false
    private var actionTapped : Bool                          = false
    fileprivate var latestPresentedView : UIViewController?  = nil
    
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
        self.isAutoLoadImage = sharedUserDataService.autoLoadRemoteImages
        
        self.updateHeader()
        
        if (self.message.numAttachments.int32Value > 0) {
            let atts = self.message.attachments.allObjects as! [Attachment]
            self.emailView?.updateEmailAttachment(atts);
        }
        
        self.emailView?.showDetails(show: self.message.hasLocation(location: .outbox))
        self.emailView!.initLayouts()
        self.emailView!.bottomActionView.delegate = self
        self.emailView!.emailHeader.delegate = self
        self.emailView?.delegate = self
        self.emailView?.emailHeader.updateAttConstraints(false)
        self.updateBadgeNumberWhenRead(message, unRead: false)
        loadMessageDetailes()
        
    }
    
    internal func loadMessageDetailes () {
        showEmailLoading()
        message.fetchDetailIfNeeded() { _, _, msg, error in
            if let error = error {
                self.processError(error: error)
            } else {
                self.updateContent()
            }
        }
    }
    
    internal func processError(error: NSError, errorInBody: Bool = true) {
        let code = error.code
        if code == NSURLErrorTimedOut {
            self.emailView?.showTimeOutErrorMessage()
            if errorInBody {
                self.updateEmailBodyWithError(LocalString._general_request_timed_out)
            }
        } else if code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorCannotConnectToHost {
            self.emailView?.showNoInternetErrorMessage()
            if errorInBody {
                self.updateEmailBodyWithError(LocalString._general_no_connectivity_detected)
            }
        } else if code == APIErrorCode.API_offline {
            self.emailView?.showErrorMessage(error.localizedDescription)
            if errorInBody {
                self.updateEmailBodyWithError(error.localizedDescription)
            }
        } else if code == APIErrorCode.HTTP503 || code == NSURLErrorBadServerResponse {
            self.emailView?.showErrorMessage(LocalString._general_api_server_not_reachable)
            if errorInBody {
                self.updateEmailBodyWithError(LocalString._general_api_server_not_reachable)
            }
        } else if code < 0{
            self.emailView?.showErrorMessage(LocalString._cant_download_message_body_please_try_again)
            if errorInBody {
                self.updateEmailBodyWithError(LocalString._cant_download_message_body_please_try_again)
            }
        } else {
            self.emailView?.showErrorMessage(LocalString._cant_download_message_body_please_try_again)
            if errorInBody {
                self.updateEmailBodyWithError(LocalString._cant_download_message_body_please_try_again)
            }
        }
        PMLog.D("error: \(error)")
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
        emailView = EmailView(frame: UIScreen.main.bounds)
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
                                             score: self.message.getScore(),
                                             isSent: self.message.hasLocation(location: .outbox))
        } else {
            PMLog.D(" MessageViewController self.message.managedObjectContext == nil")
        }
    }
    
    func test() {
        performSegue(withIdentifier: "toLabelManagerSegue", sender: self)
    }
    
    fileprivate func setupRightButtons() {
        var rightButtons: [UIBarButtonItem] = []
        rightButtons.append(UIBarButtonItem(image: UIImage(named: "top_more"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(MessageViewController.moreButtonTapped(_:))))
        rightButtons.append(UIBarButtonItem(image: UIImage(named: "top_trash"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(MessageViewController.removeButtonTapped)))
        rightButtons.append(UIBarButtonItem(image: UIImage(named: "top_folder"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(MessageViewController.folderButtonTapped)))
        rightButtons.append(UIBarButtonItem(image: UIImage(named: "top_label"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(MessageViewController.labelButtonTapped)))
        rightButtons.append(UIBarButtonItem(image: UIImage(named: "top_unread"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(MessageViewController.unreadButtonTapped)))
        
        self.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
    }
    
    @objc internal func unreadButtonTapped() {
        if !actionTapped {
            actionTapped = true
            messagesSetRead(unRead: true)
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
            
            self.message.removeLocationFromLabels(currentlocation: self.message.location, location: .spam, keepSent: true)
            self.messagesSetValue(setValue: MessageLocation.spam.rawValue, forKey: Message.Attributes.locationNumber)
            self.popViewController()
        }
    }
    
    @objc internal func moreButtonTapped(_ sender : UIBarButtonItem) {

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
        let locations: [MessageLocation : UIAlertAction.Style] = [.inbox : .default, .spam : .default, .archive : .default]
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
        
        alertController.addAction(UIAlertAction(title: LocalString._print, style: .default, handler: { (action) -> Void in
            self.print(webView : self.emailView!.contentWebView)
        }))
        
        alertController.addAction(UIAlertAction.init(title: LocalString._view_message_headers, style: .default, handler: { _ in
            let headers = self.message.header
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            let filename = formatter.string(from: self.message.time!) + "-" + self.message.title.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "-")
            tempFileUri = FileManager.default.temporaryDirectoryUrl.appendingPathComponent(filename, isDirectory: false).appendingPathExtension("txt")
            try? FileManager.default.removeItem(at: tempFileUri!)
            try? headers?.write(to: tempFileUri!, atomically: true, encoding: .utf8)
            let previewQL = QuickViewViewController()
            previewQL.dataSource = self
            self.latestPresentedView = previewQL
            self.present(previewQL, animated: true, completion: nil)
        }))
        
        alertController.addAction(UIAlertAction(title: LocalString._report_phishing, style: .destructive, handler: { (action) -> Void in
            let alert = UIAlertController(title: LocalString._confirm_phishing_report,
                                          message: LocalString._reporting_a_message_as_a_phishing_,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: { (action) in
                
            }))
            alert.addAction(UIAlertAction(title: LocalString._general_confirm_action, style: .default, handler: { (action) in
                ActivityIndicatorHelper.showActivityIndicator(at: self.view)
                if let _ = self.message.managedObjectContext {
                    BugDataService().reportPhishing(messageID: self.message.messageID, messageBody: self.fixedBody ?? "") { error in
                        ActivityIndicatorHelper.showActivityIndicator(at: self.view)
                        if let error = error {
                            let alert = error.alertController()
                            alert.addOKAction()
                            self.present(alert, animated: true, completion: nil)
                        } else {
                            self.spamButtonTapped()
                        }
                    }
                }
                
            }))
            self.present(alert, animated: true, completion: {
                
            })
        }))
        
        
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
        let documentsPath = FileManager.default.attachmentDirectory.appendingPathComponent("\(self.message.subject).pdf")
        PMLog.D(documentsPath.absoluteString)
        try? pdfData.write(to: documentsPath, options: [.atomic])
//        pdfData.write(toFile: documentsPath, atomically: true)
        
        tempFileUri = documentsPath
        let previewQL = QuickViewViewController()
        previewQL.dataSource = self
        latestPresentedView = previewQL
        self.present(previewQL, animated: true, completion: nil)
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
    
    fileprivate func messagesSetRead(unRead: Bool) {
        if let context = message.managedObjectContext {
            self.updateBadgeNumberWhenRead(message, unRead: unRead)
            message.unRead = unRead
            message.needsUpdate = true
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D(" error: \(error)")
            }
        }
    }
    
    func updateBadgeNumberWhenRead(_ message : Message, unRead : Bool) {
        let location = message.location
        
        if message.unRead == unRead {
            return
        }
        var count = lastUpdatedStore.UnreadCountForKey(location)
        count = count + (unRead ? 1 : -1)
        if count < 0 {
            count = 0
        }
        lastUpdatedStore.updateUnreadCountForKey(location, count: count)
        
        if message.isStarred {
            var staredCount = lastUpdatedStore.UnreadCountForKey(.starred)
            staredCount = staredCount + (unRead ? 1 : -1)
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
            if let contact = sender as? ContactVO {
                let composeViewController = segue.destination as! ComposeEmailViewController
                sharedVMService.newDraft(vmp: composeViewController, with: contact)
            } else if let enumRaw = sender as? Int, let tapped = ComposeMessageAction(rawValue: enumRaw), tapped != .newDraft{
                let composeViewController = segue.destination as! ComposeEmailViewController
                sharedVMService.newDraft(vmp: composeViewController, with: message, action: tapped)
            } else {
                let composeViewController = segue.destination as! ComposeEmailViewController
                sharedVMService.newDraft(vmp: composeViewController, with: self.url)
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
        } else if segue.identifier == kToAddContactSegue {
            if let contact = sender as? ContactVO {
                let addContactViewController = segue.destination.children[0] as! ContactEditViewController
                sharedVMService.contactAddViewModel(addContactViewController, contactVO: contact)
            }
        }
    }
    
    func shouldShowSideMenu() -> Bool {
        return false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MessageViewController.statusBarHit(_:)),
                                               name: .touchStatusBar,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MessageViewController.reachabilityChanged(_:)),
                                               name: .reachabilityChanged,
                                               object: nil)
        
        if message != nil {
            if let context = message.managedObjectContext {
                message.unRead = false
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
        NotificationCenter.default.removeObserver(self, name: .touchStatusBar, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.reachabilityChanged, object: nil)
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
    
    internal func purifyEmailBody(_ message : Message!, autoloadimage : Bool) -> String? {
        do {
            var bodyText = try self.message.decryptBodyIfNeeded() ?? LocalString._unable_to_decrypt_message
            bodyText = bodyText.stringByStrippingStyleHTML()
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
        let body = LocalString._loading_
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
        let alert = LocalString._please_wait_until_the_email_downloaded.alertController();
        alert.addOKAction()
        latestPresentedView = alert
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK

extension MessageViewController :  EmailViewActionsProtocol {
    func mailto(_ url: Foundation.URL?) {
        self.url = url
        self.performSegue(withIdentifier: kToComposerSegue, sender: ComposeMessageAction.newDraft.rawValue)
    }
}


// MARK
fileprivate var tempFileUri : URL?
extension MessageViewController : EmailHeaderActionsProtocol, UIDocumentInteractionControllerDelegate {
    func downloadFailed(error: NSError) {
        self.processError(error: error, errorInBody: false)
    }
    
    func recipientView(lockCheck model: ContactPickerModelProtocol, progress: () -> Void, complete: LockCheckComplete?) {
        if !self.message.isDetailDownloaded {
            progress()
        } else {
            //TODO:: put this to view model
            if let c = model as? ContactVO {
                if self.message.hasLocation(location: .outbox) {
                    c.pgpType = self.message.getSentLockType(email: c.displayEmail ?? "")
                    complete?(nil, -1)
                } else {
                    c.pgpType = self.message.getInboxType(email: c.displayEmail ?? "", signature: .notSigned)
                    if self.message.checkedSign {
                        c.pgpType = self.message.pgpType
                        complete?(nil, -1)
                    } else {
                        if self.message.checkingSign {
                            
                        } else {
                            self.message.checkingSign = true
                            guard let emial = model.displayEmail else {
                                self.message.checkingSign = false
                                complete?(nil, -1)
                                return
                            }
                            let context = sharedCoreDataService.newManagedObjectContext()
                            let getEmail = UserEmailPubKeys(email: emial).run()
                            let getContact = sharedContactDataService.fetch(byEmails: [emial], context: context)
                            when(fulfilled: getEmail, getContact).done { keyRes, contacts in
                                //internal emails
                                if keyRes.recipientType == 1 {
                                    if let contact = contacts.first, let pgpKeys = contact.pgpKeys {
                                        let status = self.message.verifyBody(verifier: pgpKeys)
                                        switch status {
                                        case .ok:
                                            c.pgpType = .internal_trusted_key
                                        case .notSigned:
                                            c.pgpType = .internal_normal
                                        case .noVerifier:
                                            c.pgpType = .internal_normal
                                        case .failed:
                                            c.pgpType = .internal_trusted_key_verify_failed
                                        }
                                    }
                                    //get all keys compromised
//                                    var iscompromised = false
//                                    if  let compromisedKeys = keyRes.getCompromisedKeys(), compromisedKeys.count > 0 {
//                                        let status = self.message.verifyBody(verifier: compromisedKeys)
//                                        switch status {
//                                        case .ok:
//                                            iscompromised = true
//                                            c.pgpType = .internal_trusted_key_verify_failed
//                                        case .notSigned, .noVerifier, .failed:
//                                            break
//                                        }
//                                    }
//
//                                    if !iscompromised {
//                                        var verifier = Data()
//                                        //get verify keys from getEmail
//                                        if  let verifyKeys = keyRes.getVerifyKeys(), verifyKeys.count > 0 {
//                                            verifier.append(verifyKeys)
//                                        }
//                                        //get verify keys from pgpkeys
//                                        if let contact = contacts.first, let pgpKeys = contact.pgpKeys, pgpKeys.count > 0 {
//                                            verifier.append(pgpKeys)
//                                        }
//                                        
//                                        if verifier.count > 0 {
//                                            let status = self.message.verifyBody(verifier: verifier)
//                                            switch status {
//                                            case .ok:
//                                                c.pgpType = .internal_trusted_key
//                                            case .notSigned:
//                                                c.pgpType = .internal_normal
//                                            case .noVerifier:
//                                                c.pgpType = .internal_normal
//                                            case .failed:
//                                                c.pgpType = .internal_trusted_key_verify_failed
//                                            }
//                                        }
//                                    }
                                } else {
                                    if let contact = contacts.first, let pgpKeys = contact.pgpKeys {
                                        let status = self.message.verifyBody(verifier: pgpKeys)
                                        switch status {
                                        case .ok:
                                            if c.pgpType == .zero_access_store {
                                                c.pgpType = .pgp_signed_verified
                                            } else {
                                                c.pgpType = .pgp_encrypt_trusted_key
                                            }
                                        case .notSigned, .noVerifier:
                                            break
                                        case .failed:
                                            if c.pgpType == .zero_access_store {
                                                c.pgpType = .pgp_signed_verify_failed
                                            } else {
                                                c.pgpType = .pgp_encrypt_trusted_key_verify_failed
                                            }
                                        }
                                    }
                                }
                                self.message.pgpType = c.pgpType
                                self.message.checkedSign = true
                                self.message.checkingSign = false
                                complete?(c.lock, c.pgpType.rawValue)
                            }.catch({ (error) in
                                self.message.checkingSign = false
                                PMLog.D(error.localizedDescription)
                                complete?(nil, -1)
                            })
                            
                        }
                    }
                }
            }
        }
    }
    
    func quickLook(attachment tempfile: URL, keyPackage: Data, fileName: String, type: String) {

        guard let data: Data = try? Data(contentsOf: tempfile) else {
            let alert = LocalString._cant_find_this_attachment.alertController()
            alert.addOKAction()
            latestPresentedView = alert
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        do {
            tempFileUri = FileManager.default.attachmentDirectory.appendingPathComponent(fileName)
            guard let decryptData = try data.decryptAttachment(keyPackage, passphrase: sharedUserDataService.mailboxPassword!),
                let _ = try? decryptData.write(to: tempFileUri!, options: [.atomic]) else
            {
                throw NSError()
            }
            
            //TODO:: the hard code string need change it to enum later
            guard (type == "application/vnd.apple.pkpass" || fileName.contains(check: ".pkpass") == true),
                let pkfile = try? Data(contentsOf: tempFileUri!) else
            {
                let previewQL = QuickViewViewController()
                previewQL.dataSource = self
                latestPresentedView = previewQL
                self.present(previewQL, animated: true, completion: nil)
                return
            }
            
            //TODO:: I add some change here for conflict but not sure if it is ok -- from Feng
            guard let pass = try? PKPass(data: pkfile),
                let vc = PKAddPassesViewController(pass: pass),
                // as of iOS 12.0 SDK, PKAddPassesViewController will not be initialized on iPads without any warning 🤯
                (vc as UIViewController?) != nil else
            {
                let previewQL = QuickViewViewController()
                previewQL.dataSource = self
                latestPresentedView = previewQL
                self.present(previewQL, animated: true, completion: nil)
                return
            }

            self.present(vc, animated: true, completion: nil)
        } catch _ {
            let alert = LocalString._cant_decrypt_this_attachment.alertController();
            alert.addOKAction()
            latestPresentedView = alert
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func star(changed isStarred: Bool) {
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
    
    func recipientView(at cell: RecipientCell, arrowClicked arrow: UIButton, model: ContactPickerModelProtocol) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
        
        alertController.addAction(UIAlertAction(title: LocalString._copy_address, style: .default, handler: { (action) -> Void in
            UIPasteboard.general.string = model.displayEmail
        }))
        alertController.addAction(UIAlertAction(title: LocalString._copy_name, style: .default, handler: { (action) -> Void in
            UIPasteboard.general.string = model.displayName
        }))
        alertController.addAction(UIAlertAction(title: LocalString._compose_to, style: .default, handler: { (action) -> Void in
            let contactVO = ContactVO(id: "",
                                      name: model.displayName,
                                      email: model.displayEmail,
                                      isProtonMailContact: false)
            self.performSegue(withIdentifier: self.kToComposerSegue, sender: contactVO)
        }))
        alertController.addAction(UIAlertAction(title: LocalString._add_to_contacts, style: .default, handler: { (action) -> Void in
            let contactVO = ContactVO(id: "",
                                      name: model.displayName,
                                      email: model.displayEmail,
                                      isProtonMailContact: false)
            self.performSegue(withIdentifier: self.kToAddContactSegue, sender: contactVO)
        }))
        alertController.popoverPresentationController?.sourceView = arrow
        alertController.popoverPresentationController?.sourceRect = arrow.frame
        
        latestPresentedView = alertController
        self.present(alertController, animated: true, completion: nil)
    }
    
    func recipientView(at cell: RecipientCell, lockClicked lock: UIButton, model: ContactPickerModelProtocol) {
        let notes = model.notes(type: self.message.hasLocation(location: .outbox) ? 2 : 1)
        notes.alertToastBottom()
    }
    
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


