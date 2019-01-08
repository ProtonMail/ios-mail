//
//  MessageViewController.swift
//  ProtonMail - on 7/27/15.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import UIKit
import QuickLook
import Foundation
import CoreData
import PassKit
import AwaitKit
import PromiseKit
import JavaScriptCore

class MessageViewController: ProtonMailViewController, ViewModelProtocol {
    typealias viewModelType = MessageViewModel
    func set(viewModel: MessageViewModel) {
        
    }
    func inactiveViewModel() {
        latestPresentedView?.dismiss(animated: true, completion: nil)
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    
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
    fileprivate var needShowShowImageView : Bool             = false
    private lazy var autoLoadImageMode: EmailBodyContents.RemoteContentLoadingMode = {
        return sharedUserDataService.autoLoadRemoteImages ? .allowed : .disallowed
    }()

    private var actionTapped : Bool                          = false
    fileprivate var latestPresentedView : UIViewController?  = nil

    
    let jsContext = JSContext()
    func initJSContact() {
        // Specify the path to the jssource.js file.
        if let jsSourcePath = Bundle.main.path(forResource: "purify", ofType: "js") {
            do {
                // Load its contents to a String variable.
                let jsSourceContents = try String(contentsOfFile: jsSourcePath)
                
                // Add the Javascript code that currently exists in the jsSourceContents to the Javascript Runtime through the jsContext object.
                self.jsContext?.evaluateScript(jsSourceContents)
            }
            catch {
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //self.initJSContact(
        
        self.setupRightButtons()
        
        if message == nil || message.managedObjectContext == nil {
            popViewController()
            return
        }
        
        self.updateHeader()
        
        let atts = self.message.attachments.allObjects as? [Attachment]
        self.emailView?.updateEmail(attachments: atts, inline: self.message.tempAtts)
        
        self.emailView?.backgroundColor = UIColor.ProtonMail.Gray_E2E6E8
        
        self.emailView?.showDetails(show: false)
        self.emailView!.initLayouts()
        self.emailView!.bottomActionView.delegate = self
        self.emailView!.emailHeader.delegate = self
        self.emailView?.delegate = self
        self.emailView?.emailHeader.updateAttConstraints(false)
        loadMessageDetailes()
        
    }
    
    internal func loadMessageDetailes () {
        showEmailLoading()
        message.fetchDetailIfNeeded() { _, _, _, error in
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
        case .NotReachable:
            PMLog.D("Access Not Available")
            if !message.isDetailDownloaded {
                self.emailView?.showNoInternetErrorMessage()
            }
        case .ReachableViaWWAN:
            PMLog.D("Reachable WWAN")
            recheckMessageDetails ()
        case .ReachableViaWiFi:
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
                                             to: self.message.toList.toContacts(),
                                             cc: self.message.ccList.toContacts(),
                                             bcc: self.message.bccList.toContacts(),
                                             isStarred: self.message.starred,
                                             time: self.message.time,
                                             encType: self.message.encryptType,
                                             labels : self.message.labels.allObjects as? [Label],
                                             showShowImages: self.needShowShowImageView,
                                             expiration: self.message.expirationTime,
                                             score: self.message.getScore(),
                                             isSent: self.message.contains(label: Message.Location.sent))
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
            if message.contains(label: .trash) || message.contains(label: .spam) {
                sharedMessageDataService.delete(message: message, label: Message.Location.trash.rawValue)
            } else {
                if let label = message.firstValidFolder() {
                    sharedMessageDataService.move(message: message, from: label, to: Message.Location.trash.rawValue)
                }
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
            if let label = message.firstValidFolder() {
                sharedMessageDataService.move(message: message, from: label, to: Message.Location.spam.rawValue)
            }
            self.popViewController()
        }
    }
    
    @objc internal func moreButtonTapped(_ sender : UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
        let locations: [Message.Location : UIAlertAction.Style] = [.inbox : .default, .spam : .default, .archive : .default]
        for (location, style) in locations {
            if !message.contains(label: location) {
                if self.message.contains(label: .sent) && location == .inbox {
                    continue
                }

                alertController.addAction(UIAlertAction(title: location.actionTitle,
                                                        style: style,
                                                        handler: { (action) -> Void in
                    if let label = self.message.firstValidFolder() {
                        sharedMessageDataService.move(message: self.message, from: label, to: location.rawValue)
                    }
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
                    BugDataService().reportPhishing(messageID: self.message.messageID, messageBody: self.htmlBody ?? "") { error in
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
    
    
    fileprivate func print(webView : PMWebView) {
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
        var filename = self.message.subject
        filename = filename.preg_replace("[^a-zA-Z0-9_]+", replaceto: "-")
        let documentsPath = FileManager.default.attachmentDirectory.appendingPathComponent("\(filename).pdf")
        PMLog.D(documentsPath.absoluteString)
        try? pdfData.write(to: documentsPath, options: [.atomic])
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
        sharedMessageDataService.mark(message: message, unRead: unRead)
    }
    
    override var shouldAutorotate : Bool {
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kToComposerSegue {
            if let contact = sender as? ContactVO {
                let composeViewController = segue.destination.children[0] as! ComposeViewController
                sharedVMService.newDraft(vmp: composeViewController)
                let viewModel = ComposeViewModelImpl(msg: nil, action: ComposeMessageAction.newDraft)
                viewModel.addToContacts(contact)
                let coordinator = ComposeCoordinator(vc: composeViewController,
                                                     vm: viewModel, services: ServiceFactory.default) //set view model
                coordinator.start()
            } else if let enumRaw = sender as? Int, let tapped = ComposeMessageAction(rawValue: enumRaw), tapped != .newDraft {
                let composeViewController = segue.destination.children[0] as! ComposeViewController
                sharedVMService.newDraft(vmp: composeViewController)
                let viewModel = ComposeViewModelImpl(msg: message, action: tapped)
                let coordinator = ComposeCoordinator(vc: composeViewController,
                                                     vm: viewModel, services: ServiceFactory.default) //set view model
                coordinator.start()
            } else {
                let composeViewController = segue.destination.children[0] as! ComposeViewController
                sharedVMService.newDraft(vmp: composeViewController)
                let viewModel = ComposeViewModelImpl(msg: nil, action: ComposeMessageAction.newDraft)
                if let mailTo : NSURL = self.url as NSURL?, mailTo.scheme == "mailto", let resSpecifier = mailTo.resourceSpecifier {
                    var rawURLparts = resSpecifier.components(separatedBy: "?")
                    if (rawURLparts.count > 2) {
                        
                    } else {
                        let defaultRecipient = rawURLparts[0]
                        if defaultRecipient.count > 0 { //default to
                            if defaultRecipient.isValidEmail() {
                                viewModel.addToContacts(ContactVO(name: defaultRecipient, email: defaultRecipient))
                            }
                            PMLog.D("to: \(defaultRecipient)")
                        }
                        
                        if (rawURLparts.count == 2) {
                            let queryString = rawURLparts[1]
                            let params = queryString.components(separatedBy: "&")
                            for param in params {
                                var keyValue = param.components(separatedBy: "=")
                                if (keyValue.count != 2) {
                                    continue
                                }
                                let key = keyValue[0].lowercased()
                                var value = keyValue[1]
                                value = value.removingPercentEncoding ?? ""
                                if key == "subject" {
                                    PMLog.D("subject: \(value)")
                                    viewModel.setSubject(value)
                                }
                                
                                if key == "body" {
                                    PMLog.D("body: \(value)")
                                    viewModel.setBody(value)
                                }
                                
                                if key == "to" {
                                    PMLog.D("to: \(value)")
                                    if value.isValidEmail() {
                                        viewModel.addToContacts(ContactVO(name: value, email: value))
                                    }
                                }
                                
                                if key == "cc" {
                                    PMLog.D("cc: \(value)")
                                    if value.isValidEmail() {
                                        viewModel.addCcContacts(ContactVO(name: value, email: value))
                                    }
                                }
                                
                                if key == "bcc" {
                                    PMLog.D("bcc: \(value)")
                                    if value.isValidEmail() {
                                        viewModel.addBccContacts(ContactVO(name: value, email: value))
                                    }
                                }
                            }
                        }
                    }
                }
                //TODO:: finish up here
                let coordinator = ComposeCoordinator(vc: composeViewController,
                                                     vm: viewModel, services: ServiceFactory.default) //set view model
                coordinator.start()
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
    fileprivate var htmlBody: String? = nil
    
    // MARK : private function
    fileprivate func updateEmailBody (force forceReload : Bool = false) {
        let atts = self.message.attachments.allObjects as? [Attachment]
        self.emailView?.updateEmail(attachments: atts, inline: self.message.tempAtts)
        
        self.updateHeader()
        self.emailView?.emailHeader.updateAttConstraints(true)
        
        if (!self.bodyLoaded || forceReload) && self.emailView != nil {
            if self.message.isDetailDownloaded {  //&& forceReload == false
                self.bodyLoaded = true
                
                if self.htmlBody == nil {
                    self.htmlBody = self.prepareHTMLBody(self.message)
                    self.showEmbedImage()
                }
                
                if self.autoLoadImageMode == .disallowed && !self.showedShowImageView{
                    if self.htmlBody?.hasImage() == true {
                        self.needShowShowImageView = true
                    }
                }
            }
        }
        if self.htmlBody != nil {
            self.loadEmailBody(self.htmlBody ?? "")
        }
    }
    
    internal func prepareHTMLBody(_ message : Message!) -> String? {
        do {
            let bodyText = try self.message.decryptBodyIfNeeded() ?? LocalString._unable_to_decrypt_message
            return bodyText
        } catch let ex as NSError {
            PMLog.D("purifyEmailBody error : \(ex)")
            return self.message.bodyToHtml()
        }
    }
    
    func jsDemo3(_ body : String) {
        if let functionGenerateLuckyNumbers = self.jsContext!.objectForKeyedSubscript("DOMPurify.sanitize") {
            let out = functionGenerateLuckyNumbers.call(withArguments: [body.escaped])
            Swift.print(out?.toString())
        }
    }
    
    internal func showEmailLoading () {
        let body = LocalString._loading_
        let contents = EmailBodyContents(body: body, remoteContentMode: self.autoLoadImageMode)
        self.emailView?.updateEmailContent(contents)
    }
    
    var contentLoaded = false
    internal func loadEmailBody(_ body : String) {
        let contents = EmailBodyContents(body: body, remoteContentMode: self.autoLoadImageMode)
        self.emailView?.updateEmailContent(contents)
        
        self.updateHeader()
        self.emailView?.emailHeader.updateAttConstraints(true)
    }
    
    // MARK : private function
    fileprivate func updateEmailBodyWithError (_ error:String) {
        let atts = self.message.attachments.allObjects as? [Attachment]
        self.emailView?.updateEmail(attachments: atts, inline: self.message.tempAtts)

        let body = NSLocalizedString(error, comment: "")
        let contents = EmailBodyContents(body: body, remoteContentMode: self.autoLoadImageMode)
        self.emailView?.updateEmailContent(contents)
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

// MARK -- impl MessageDetailBottomViewDelegate
extension MessageViewController : MessageDetailBottomViewDelegate {
    func replyAction() {
        if self.message.isDetailDownloaded {
            self.performSegue(withIdentifier: kToComposerSegue, sender: ComposeMessageAction.reply.rawValue)
        } else {
            self.showAlertWhenNoDetails()
        }
    }
    
    func replyAllAction() {
        if self.message.isDetailDownloaded {
            self.performSegue(withIdentifier: kToComposerSegue, sender: ComposeMessageAction.replyAll.rawValue)
        } else {
            self.showAlertWhenNoDetails()
        }
    }
    
    func forwardAction() {
        if self.message.isDetailDownloaded {
            self.performSegue(withIdentifier: kToComposerSegue, sender: ComposeMessageAction.forward.rawValue)
        } else {
            self.showAlertWhenNoDetails()
        }
    }
    
    private func showAlertWhenNoDetails() {
        let alert = LocalString._please_wait_until_the_email_downloaded.alertController();
        alert.addOKAction()
        latestPresentedView = alert
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK -- impl EmailViewActionsProtocol

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
                if self.message.contains(label: .sent) {
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
                            let context = sharedCoreDataService.backgroundManagedObjectContext
                            let getEmail = UserEmailPubKeys(email: emial).run()
                            let getContact = sharedContactDataService.fetch(byEmails: [emial], context: context)
                            when(fulfilled: getEmail, getContact).done { keyRes, contacts in
                                //internal emails
                                if keyRes.recipientType == 1 {
                                    if let contact = contacts.first, let pgpKeys = contact.pgpKeys {
                                        let status = self.message.verifyBody(verifier: pgpKeys, passphrase: sharedUserDataService.mailboxPassword!)
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
                                        let status = self.message.verifyBody(verifier: pgpKeys, passphrase: sharedUserDataService.mailboxPassword!)
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
            guard let decryptData = try data.decryptAttachment(keyPackage, passphrase: sharedUserDataService.mailboxPassword!, privKeys: sharedUserDataService.addressPrivKeys),
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
    
    func quickLook(file : URL, fileName:String, type: String) {
        tempFileUri = file
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
    }
    
    func star(changed isStarred: Bool) {
        if isStarred {
            sharedMessageDataService.label(message: message, label: Message.Location.starred.rawValue, apply: true)
        } else {
            sharedMessageDataService.label(message: message, label: Message.Location.starred.rawValue, apply: false)
        }
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
        let notes = model.notes(type: self.message.contains(label: .sent) ? 2 : 1)
        notes.alertToastBottom()
    }
    
    func showImage() {
        self.showedShowImageView = true
        self.needShowShowImageView = false
        self.autoLoadImageMode = .allowed
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
                            self.htmlBody = self.htmlBody?.stringBySetupInlineImage("src=\"cid:\(content_id)\"", to: "src=\"data:\(att.mimeType);base64,\(based64String)\"" )
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


