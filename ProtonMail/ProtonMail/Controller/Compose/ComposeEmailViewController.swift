//
//  ComposeEmailViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/21/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit
import ZSSRichTextEditor
import PromiseKit
import AwaitKit


fileprivate let learnMoreUrl = URL(string: "https://protonmail.com/support/knowledge-base/encrypt-for-outside-users/")!

class ComposeEmailViewController: ZSSRichTextEditor, ViewModelProtocolNew {
    // view model
    fileprivate var viewModel : ComposeViewModel!

    func set(viewModel: ComposeViewModel) {
        self.viewModel = viewModel
    }
    
    typealias argType = ComposeViewModel
    
    func inactiveViewModel() { 
        self.stopAutoSave()
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.willResignActiveNotification,
                                                  object:nil)
        self.dismissKeyboard()
        if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    // private views
    fileprivate var webView : UIWebView!
    fileprivate var composeView : ComposeView!
    fileprivate var cancelButton: UIBarButtonItem!
    
    // private vars
    fileprivate var timer : Timer!
    fileprivate var draggin : Bool! = false
    fileprivate var contacts: [ContactPickerModelProtocol] = []
    fileprivate var actualEncryptionStep = EncryptionStep.DefinePassword
    fileprivate var encryptionPassword: String = ""
    fileprivate var encryptionConfirmPassword: String = ""
    fileprivate var encryptionPasswordHint: String = ""
    fileprivate var hasAccessToAddressBook: Bool = false
    
    fileprivate var attachments: [Any]?
    
    @IBOutlet weak var expirationPicker: UIPickerView!
    // offsets
    fileprivate var composeViewSize : CGFloat = 186
    
    // MARK : const values
    fileprivate let kNumberOfColumnsInTimePicker: Int = 2
    fileprivate let kNumberOfDaysInTimePicker: Int = 30
    fileprivate let kNumberOfHoursInTimePicker: Int = 24
    
    fileprivate let kPasswordSegue : String = "to_eo_password_segue"
    fileprivate let kExpirationWarningSegue : String = "expiration_warning_segue"
    
    fileprivate var isShowingConfirm : Bool = false
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        if let wv = self.webView {
            wv.delegate = nil
            wv.stopLoading()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cancelButton = UIBarButtonItem(title: LocalString._general_cancel_button,
                                            style: UIBarButtonItem.Style.plain,
                                            target: self,
                                            action: #selector(ComposeEmailViewController.cancel_clicked(_:)))
        self.navigationItem.leftBarButtonItem = cancelButton
        
        configureNavigationBar()
        setNeedsStatusBarAppearanceUpdate()
        
        self.baseURL = URL(fileURLWithPath: "https://protonmail.ch")
        self.webView = self.getWebView()
        
        // init views
        self.composeView = ComposeView(nibName: "ComposeView", bundle: nil)
        if #available(iOS 11.0, *) {
            self.updateComposeFrame()
        } else {
            let w = UIScreen.main.applicationFrame.width
            self.composeView.view.frame = CGRect(x: 0, y: 0, width: w, height: composeViewSize + 60)
        }
        
        self.composeView.delegate = self
        self.composeView.datasource = self
        self.webView.scrollView.addSubview(composeView.view)
        self.webView.scrollView.bringSubviewToFront(composeView.view)
        
        // update content values
        updateMessageView()
        
        // load all contacts and groups
        firstly {
            () -> Promise<Void> in
            
            self.contacts = sharedContactDataService.allContactVOs()
            return retrieveAllContacts()
            }.done {
                () -> Void in
                
                // TODO: figure what to put this thing
                self.contacts.append(contentsOf: sharedContactGroupsDataService.getAllContactGroupVOs())
                
                // This is done for contact also
                self.contacts.sort {
                    (first: ContactPickerModelProtocol, second: ContactPickerModelProtocol) -> Bool in
                    
                    if let first = first as? ContactVO,
                        let second = second as? ContactVO {
                        return first.name.lowercased() == second.name.lowercased() ?
                            first.email.lowercased() < second.email.lowercased() :
                            first.name.lowercased() < second.name.lowercased()
                    } else if let first = first as? ContactGroupVO,
                        let second = second as? ContactGroupVO {
                        return first.contactTitle.lowercased() < second.contactTitle.lowercased()
                    } else {
                        // same title, the one with email goes second
                        if first.contactTitle.lowercased() == second.contactTitle.lowercased() {
                            if let _ = first as? ContactVO {
                                return false
                            }
                            return true
                        }
                        return first.contactTitle.lowercased() < second.contactTitle.lowercased()
                    }
                }
                
                self.composeView.toContactPicker.reloadData()
                self.composeView.ccContactPicker.reloadData()
                self.composeView.bccContactPicker.reloadData()
                
                self.composeView.toContactPicker.contactCollectionView!.layoutIfNeeded()
                self.composeView.bccContactPicker.contactCollectionView!.layoutIfNeeded()
                self.composeView.ccContactPicker.contactCollectionView!.layoutIfNeeded()
                
                switch self.viewModel.messageAction!
                {
                case .openDraft, .reply, .replyAll:
                    if !self.isShowingConfirm {
                        self.focus()
                    }
                    self.composeView.notifyViewSize(true)
                    break
                default:
                    if !self.isShowingConfirm {
                        let _ = self.composeView.toContactPicker.becomeFirstResponder()
                    }
                    break
                }
            }.catch {
                error in
                
                // TODO: handle error
                PMLog.D("Load all contacts and groups error \(error)")
        }
        
        self.expirationPicker.alpha = 0.0
        self.expirationPicker.dataSource = self
        self.expirationPicker.delegate = self
        
        self.attachments = viewModel.getAttachments()
        
        // update header layout
        updateContentLayout(false)
        
        //change message as read
        self.viewModel.markAsRead();
        
        self.formatHTML = true
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if #available(iOS 11.0, *) {
            self.updateComposeFrame()
        } else {
            // Fallback on earlier versions
        }
    }
    
    @available(iOS 11.0, *)
    internal func updateComposeFrame() {
        let inset = self.view.safeAreaInsets
        let offset = inset.left + inset.right
        var w = UIScreen.main.applicationFrame.width - offset
        if w < 0 {
            w = 0
        }
        self.composeView.view.frame = CGRect(x: 0, y: 0, width: w, height: composeViewSize)
    }
    
    
    internal func retrieveAllContacts() -> Promise<Void> {
        return Promise {
            seal in
            
            sharedContactDataService.getContactVOs { (contacts, error) in
                if let error = error {
                    PMLog.D(" error: \(error)")
                    
                    // seal.reject(error) // TODO: should I?
                }
                
                self.contacts = contacts
                
                seal.fulfill(())
            }
        }
    }
    
    internal func updateEmbedImages() {
        if let atts = viewModel.getAttachments() {
            for att in atts {
                if let content_id = att.contentID(), !content_id.isEmpty && att.inline() {
                    att.base64AttachmentData({ (based64String) in
                        if !based64String.isEmpty {
                            self.updateEmbedImage(byCID: "cid:\(content_id)", blob:  "data:\(att.mimeType);base64,\(based64String)")
                        }
                    })
                }
            }
        }
    }
    
    override func webViewDidFinishLoad(_ webView: UIWebView) {
        super.webViewDidFinishLoad(webView)
        updateEmbedImages()
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        self.composeView.notifyViewSize(true)
    }
    
    fileprivate func dismissKeyboard() {
        self.composeView.subject.becomeFirstResponder()
        self.composeView.subject.resignFirstResponder()
    }
    
    fileprivate func updateMessageView() {
        self.composeView.subject.text = self.viewModel.getSubject()
        self.shouldShowKeyboard = false
        self.setHTML(self.viewModel.getHtmlBody())
        
        guard let addr = self.viewModel.getDefaultSendAddress() else {
            return
        }
        self.composeView.updateFromValue(addr.email, pickerEnabled: true)
        if let origAddr = self.viewModel.fromAddress() {
            if origAddr.send == 0 {
                self.viewModel.updateAddressID(addr.address_id).done {
                    //
                }.catch({ (_) in
                    
                })
                
                if origAddr.email.lowercased().range(of: "@pm.me") != nil {
                    guard userCachedStatus.isPMMEWarningDisabled == false else {
                        return
                    }
                    let msg = String(format: LocalString._composer_sending_messages_from_a_paid_feature, origAddr.email, addr.email)
                    let alertController = msg.alertController(LocalString._general_notice_alert_title)
                    alertController.addOKAction()
                    alertController.addAction(UIAlertAction(title: LocalString._general_dont_remind_action, style: .destructive, handler: { action in
                        userCachedStatus.isPMMEWarningDisabled = true
                    }))
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.updateAttachmentButton()
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ComposeEmailViewController.statusBarHit(_:)),
                                               name: .touchStatusBar,
                                               object:nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ComposeEmailViewController.willResignActiveNotification(_:)),
                                               name: UIApplication.willResignActiveNotification,
                                               object:nil)
        setupAutoSave()
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        stopAutoSave()
    }
    
    @objc internal func willResignActiveNotification (_ notify: Notification) {
        self.autoSaveTimer()
        dismissKeyboard()
    }
    
    @objc internal func statusBarHit (_ notify: Notification) {
        webView.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    func configureNavigationBar() {
        self.navigationController?.navigationBar.barStyle = UIBarStyle.black
        self.navigationController?.navigationBar.barTintColor = UIColor.ProtonMail.Nav_Bar_Background
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        let navigationBarTitleFont = Fonts.h2.light
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: navigationBarTitleFont
        ]
        
        self.navigationItem.leftBarButtonItem?.title = LocalString._general_cancel_button
        cancelButton.title = LocalString._general_cancel_button
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kPasswordSegue {
            let popup = segue.destination as! ComposePasswordViewController
            popup.pwdDelegate = self
            popup.setupPasswords(self.encryptionPassword, confirmPassword: self.encryptionConfirmPassword, hint: self.encryptionPasswordHint)
            self.setPresentationStyleForSelfController(self, presentingController: popup)
        } else if segue.identifier == kExpirationWarningSegue {
            let popup = segue.destination as! ExpirationWarningViewController
            popup.delegate = self
            let nonePMEmail = self.encryptionPassword.count <= 0 ? self.composeView.nonePMEmails : [String]()
            popup.config(needPwd: nonePMEmail,
                         pgp: self.composeView.pgpEmails)
        }
    }
    
    internal func setPresentationStyleForSelfController(_ selfController : UIViewController,  presentingController: UIViewController) {
        presentingController.providesPresentationContextTransitionStyle = true
        presentingController.definesPresentationContext = true
        presentingController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
    }
    
    
    override func editorDidScroll(withPosition position: Int) {
        super.editorDidScroll(withPosition: position)
        
        //let new_position = self.getCaretPosition().toInt() ?? 0
        //self.delegate?.editorSizeChanged(self.getContentSize())
        //self.delegate?.editorCaretPosition(new_position)
    }
    
    fileprivate func updateContentLayout(_ animation: Bool) {
        UIView.animate(withDuration: animation ? 0.25 : 0, animations: { () -> Void in
            for subview in self.webView.scrollView.subviews {
                let sub = subview
                if sub == self.composeView.view {
                    continue
                } else if sub is UIImageView {
                    continue
                } else {
                    let h : CGFloat = self.composeViewSize
                    self.updateFooterOffset(h)
                    sub.frame = CGRect(x: sub.frame.origin.x, y: h, width: sub.frame.width, height: sub.frame.height)
                }
            }
        })
    }
    
    
    @IBAction func send_clicked(_ sender: AnyObject) {
        self.dismissKeyboard()
        
        if let suject = self.composeView.subject.text {
            if !suject.isEmpty {
                self.sendMessage()
                return
            }
        }
        
        let alertController = UIAlertController(title: LocalString._composer_compose_action,
                                                message: LocalString._composer_send_no_subject_desc,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: LocalString._general_send_action,
                                                style: .destructive, handler: { (action) -> Void in
            self.sendMessage()
        }))
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    internal func sendMessage () {
        if self.composeView.expirationTimeInterval > 0 {
            if self.composeView.hasPGPPinned ||
                (self.composeView.hasNonePMEmails && self.encryptionPassword.count <= 0 ) {
                
                self.performSegue(withIdentifier: self.kExpirationWarningSegue, sender: self)
                return
            }
            
        }
        delay(0.3) {
            self.sendMessageStepTwo()
        }
    }
    
    internal func sendMessageStepTwo() {
        if self.viewModel.toSelectedContacts.count <= 0 &&
            self.viewModel.ccSelectedContacts.count <= 0 &&
            self.viewModel.bccSelectedContacts.count <= 0 {
            let alert = UIAlertController(title: LocalString._general_alert_title,
                                          message: LocalString._composer_no_recipient_error,
                                          preferredStyle: .alert)
            alert.addAction((UIAlertAction.okAction()))
            present(alert, animated: true, completion: nil)
            return
        }
        
        stopAutoSave()
        self.collectDraft()
        self.viewModel.sendMessage()
        
        // show messagex
        delay(0.5) {
            NSError.alertMessageSendingToast()
        }
        
        if presentingViewController != nil {
            dismiss(animated: true, completion: nil)
        } else {
            let _ = navigationController?.popToRootViewController(animated: true)
        }
    }
    
    @IBAction func cancel_clicked(_ sender: UIBarButtonItem) {
        let dismiss: (() -> Void) = {
            self.isShowingConfirm = false
            self.dismissKeyboard()
            if self.presentingViewController != nil {
                self.dismiss(animated: true, completion: nil)
            } else {
                let _ = self.navigationController?.popViewController(animated: true)
            }
        }
        
        if self.viewModel.hasDraft || composeView.hasContent || ((attachments?.count ?? 0) > 0) {
            self.isShowingConfirm = true
            let alertController = UIAlertController(title: LocalString._general_confirmation_title,
                                                    message: nil, preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: LocalString._composer_save_draft_action,
                                                    style: .default, handler: { (action) -> Void in
                self.stopAutoSave()
                self.collectDraft()
                self.viewModel.updateDraft()
                dismiss()
            }))
            
            alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button,
                                                    style: .cancel, handler: { (action) -> Void in
                self.isShowingConfirm = false
            }))
            
            alertController.addAction(UIAlertAction(title: LocalString._composer_discard_draft_action,
                                                    style: .destructive, handler: { (action) -> Void in
                self.stopAutoSave()
                self.viewModel.deleteDraft()
                dismiss()
            }))
            
            alertController.popoverPresentationController?.barButtonItem = sender
            alertController.popoverPresentationController?.sourceRect = self.view.frame
            present(alertController, animated: true, completion: nil)
        } else {
            dismiss()
        }
    }
    
    // MARK: - Private methods
    fileprivate func setupAutoSave() {
        self.timer = Timer.scheduledTimer(timeInterval: 120, target: self, selector: #selector(ComposeEmailViewController.autoSaveTimer), userInfo: nil, repeats: true)
        if viewModel.getActionType() != .openDraft {
            self.timer.fire()
        }
    }
    
    fileprivate func stopAutoSave() {
        if self.timer != nil {
            self.timer.invalidate()
            self.timer = nil
        }
    }
    
    @objc func autoSaveTimer() {
        self.collectDraft()
        self.viewModel.updateDraft()
    }
    
    fileprivate func collectDraft() {
        let orignal = self.getOrignalEmbedImages()
        let edited = self.getEditedEmbedImages()
        self.checkEmbedImageEdit(orignal!, edited: edited!)
        var body = self.getHTML()
        if (body?.isEmpty)! {
            body = "<div><br></div>"
        }
        
        self.viewModel.collectDraft (
            self.composeView.subject.text!,
            body: body!,
            expir: self.composeView.expirationTimeInterval,
            pwd:self.encryptionPassword,
            pwdHit:self.encryptionPasswordHint
        )
    }
    
    override func getHTML() -> String! {
        // this method is copy of super's with one difference: it escapes backslash before calling private removeQuotesFromHTML: and tidyHTML:, since they are messing up backslash with some other special symbols and replace it with other unexpected things. This problem is implementation detail of ZSSRichTextEditor.
        guard var html = self.webView.stringByEvaluatingJavaScript(from: "zss_editor.getHTML();") else {
            return ""
        }
        html = html.replacingOccurrences(of: "\\", with: "&#92;", options: .caseInsensitive, range: nil)
        html = self.perform(Selector(("removeQuotesFromHTML:")), with: html).takeUnretainedValue() as! String
        html = self.perform(Selector(("tidyHTML:")), with: html).takeUnretainedValue() as! String
        
        return html
    }
    
    fileprivate func checkEmbedImageEdit(_ orignal: String, edited: String) {
        PMLog.D(edited)
        if let atts = viewModel.getAttachments() {
            for att in atts {
                if let content_id = att.contentID(), !content_id.isEmpty && att.inline() {
                    PMLog.D(content_id)
                    if orignal.contains(content_id) {
                        if !edited.contains(content_id) {
                            self.viewModel.deleteAtt(att)
                        }
                    }
                }
            }
        }
    }
    
    fileprivate func updateAttachmentButton () {
        if attachments?.count > 0 {
            self.composeView.updateAttachmentButton(true)
        } else {
            self.composeView.updateAttachmentButton(false)
        }
    }
}

extension ComposeEmailViewController : ComposePasswordViewControllerDelegate {
    
    func Cancelled() {
        
    }
    
    func Apply(_ password: String, confirmPassword: String, hint: String) {
        self.encryptionPassword = password
        self.encryptionConfirmPassword = confirmPassword
        self.encryptionPasswordHint = hint
        self.composeView.showEncryptionDone()
        self.updateEO()
    }
    
    func Removed() {
        self.encryptionPassword = ""
        self.encryptionConfirmPassword = ""
        self.encryptionPasswordHint = ""
        
        self.composeView.showEncryptionRemoved()
        self.updateEO()
    }
}

// MARK : - view extensions
extension ComposeEmailViewController : ComposeViewDelegate {
    func composeViewWillPresentSubview() {
        self.webView?.scrollView.isScrollEnabled = false
    }
    func composeViewWillDismissSubview() {
        self.webView?.scrollView.isScrollEnabled = true
    }
    
    func lockerCheck(model: ContactPickerModelProtocol, progress: () -> Void, complete: LockCheckComplete?) {
        self.viewModel.lockerCheck(model: model, progress: progress, complete: complete)
    }
    
    func composeViewPickFrom(_ composeView: ComposeView) {
        var needsShow : Bool = false
        let alertController = UIAlertController(title: LocalString._composer_change_sender_address_to, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
        let multi_domains = self.viewModel.getAddresses()
        let defaultAddr = self.viewModel.getDefaultSendAddress()
        for addr in multi_domains {
            if addr.status == 1 && addr.receive == 1 && defaultAddr != addr {
                needsShow = true
                alertController.addAction(UIAlertAction(title: addr.email, style: .default, handler: { (action) -> Void in
                    if addr.send == 0 {
                        let alertController = String(format: LocalString._composer_change_paid_plan_sender_error, addr.email).alertController()
                        alertController.addOKAction()
                        self.present(alertController, animated: true, completion: nil)
                    } else {
                        if let signature = self.viewModel.getCurrrentSignature(addr.address_id) {
                            self.updateSignature("\(signature)")
                        }
                        ActivityIndicatorHelper.showActivityIndicator(at: self.view)
                        self.viewModel.updateAddressID(addr.address_id).done {
                            self.composeView.updateFromValue(addr.email, pickerEnabled: true)
                        }.catch { (error ) in
                            let alertController = error.localizedDescription.alertController()
                            alertController.addOKAction()
                            self.present(alertController, animated: true, completion: nil)
                        }.finally {
                            ActivityIndicatorHelper.hideActivityIndicator(at: self.view)
                        }
                    }
                }))
            }
        }
        if needsShow {
            alertController.popoverPresentationController?.sourceView = self.composeView.fromView
            alertController.popoverPresentationController?.sourceRect = self.composeView.fromView.frame
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func ComposeViewDidSizeChanged(_ size: CGSize, showPicker: Bool) {
        self.composeViewSize = size.height
        if #available(iOS 11.0, *) {
            self.updateComposeFrame()
        } else {
            let w = UIScreen.main.applicationFrame.width
            self.composeView.view.frame = CGRect(x: 0, y: 0, width: w, height: composeViewSize)
        }
        self.updateContentLayout(true)
        self.webView.scrollView.isScrollEnabled = !showPicker

    }
    
    func ComposeViewDidOffsetChanged(_ offset: CGPoint) {
    
    }
    
    func composeViewDidTapNextButton(_ composeView: ComposeView) {
        switch(actualEncryptionStep) {
        case EncryptionStep.DefinePassword:
            self.encryptionPassword = (composeView.encryptedPasswordTextField.text ?? "").trim()
            if !self.encryptionPassword.isEmpty {
                self.actualEncryptionStep = EncryptionStep.ConfirmPassword
                self.composeView.showConfirmPasswordView()
            } else {
                self.composeView.showPasswordAndConfirmDoesntMatch(LocalString._composer_eo_empty_pwd_desc)
            }
        case EncryptionStep.ConfirmPassword:
            self.encryptionConfirmPassword = (composeView.encryptedPasswordTextField.text ?? "").trim()
            
            if (self.encryptionPassword == self.encryptionConfirmPassword) {
                self.actualEncryptionStep = EncryptionStep.DefineHintPassword
                self.composeView.hidePasswordAndConfirmDoesntMatch()
                self.composeView.showPasswordHintView()
            } else {
                self.composeView.showPasswordAndConfirmDoesntMatch(LocalString._composer_eo_dismatch_pwd_desc)
            }
            
        case EncryptionStep.DefineHintPassword:
            self.encryptionPasswordHint = (composeView.encryptedPasswordTextField.text ?? "").trim()
            self.actualEncryptionStep = EncryptionStep.DefinePassword
            self.composeView.showEncryptionDone()
        default:
            PMLog.D("No step defined.")
        }
    }
    
    func composeViewDidTapEncryptedButton(_ composeView: ComposeView) {
        self.performSegue(withIdentifier: kPasswordSegue, sender: self)
    }
    
    func composeViewDidTapAttachmentButton(_ composeView: ComposeView) {
        if let viewController = UIStoryboard.instantiateInitialViewController(storyboard: .attachments) as? UINavigationController {
            if let attachmentsViewController = viewController.viewControllers.first as? AttachmentsTableViewController {
                attachmentsViewController.delegate = self
                attachmentsViewController.message = viewModel.message
                if let _ = attachments {
                    attachmentsViewController.attachments = viewModel.getAttachments() ?? []
                }
            }
            present(viewController, animated: true, completion: nil)
        }
    }
    
    func composeViewDidTapExpirationButton(_ composeView: ComposeView) {
        self.expirationPicker.alpha = 1
        self.view.bringSubviewToFront(expirationPicker)
    }
    
    func composeViewHideExpirationView(_ composeView: ComposeView) {
        self.expirationPicker.alpha = 0
    }
    
    func composeViewCancelExpirationData(_ composeView: ComposeView) {
        self.expirationPicker.selectRow(0, inComponent: 0, animated: true)
        self.expirationPicker.selectRow(0, inComponent: 1, animated: true)
    }
    
    func composeViewCollectExpirationData(_ composeView: ComposeView) {
        let selectedDay = expirationPicker.selectedRow(inComponent: 0)
        let selectedHour = expirationPicker.selectedRow(inComponent: 1)
        if self.composeView.setExpirationValue(selectedDay, hour: selectedHour) {
            self.expirationPicker.alpha = 0
        }
        self.updateEO()
    }
    
    func updateEO() {
        self.viewModel.updateEO(expir: self.composeView.expirationTimeInterval,
                                pwd: self.encryptionPassword,
                                pwdHit: self.encryptionPasswordHint)
        self.composeView.reloadPicker()
    }
    
    func composeView(_ composeView: ComposeView, didAddContact contact: ContactPickerModelProtocol, toPicker picker: ContactPicker) {
        if (picker == composeView.toContactPicker) {
            self.viewModel.toSelectedContacts.append(contact)
        } else if (picker == composeView.ccContactPicker) {
            self.viewModel.ccSelectedContacts.append(contact)
        } else if (picker == composeView.bccContactPicker) {
            self.viewModel.bccSelectedContacts.append(contact)
        }
        
        if self.viewModel.isValidNumberOfRecipients() == false {
            // rollback
            if (picker == composeView.toContactPicker) {
                self.viewModel.toSelectedContacts.removeLast()
            } else if (picker == composeView.ccContactPicker) {
                self.viewModel.ccSelectedContacts.removeLast()
            } else if (picker == composeView.bccContactPicker) {
                self.viewModel.bccSelectedContacts.removeLast()
            }
            
            // present error
            let alert = UIAlertController(title: LocalString._too_many_recipients,
                                          message: LocalString._max_number_of_recipients_is,
                                          preferredStyle: .alert)
            alert.addAction(.init(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            picker.reloadData()
            return
        }
    }
    
    func composeView(_ composeView: ComposeView, didRemoveContact contact: ContactPickerModelProtocol, fromPicker picker: ContactPicker) {
        // here each logic most same, need refactor later
        if (picker == composeView.toContactPicker) {
            var contactIndex = -1
            let selectedContacts = self.viewModel.toSelectedContacts
            for (index, selectedContact) in selectedContacts.enumerated() {
                if let contact = contact as? ContactVO {
                    if (contact.displayEmail == selectedContact.displayEmail) {
                        contactIndex = index
                    }
                } else if let contactGroup = contact as? ContactGroupVO {
                    if (contact.contactTitle == selectedContact.contactTitle) {
                        contactIndex = index
                    }
                }
            }
            if (contactIndex >= 0) {
                self.viewModel.toSelectedContacts.remove(at: contactIndex)
            }
        } else if (picker == composeView.ccContactPicker) {
            var contactIndex = -1
            let selectedContacts = self.viewModel.ccSelectedContacts
            for (index, selectedContact) in selectedContacts.enumerated() {
                if let contact = contact as? ContactVO {
                    if (contact.displayEmail == selectedContact.displayEmail) {
                        contactIndex = index
                    }
                } else if let contactGroup = contact as? ContactGroupVO {
                    if (contact.contactTitle == selectedContact.contactTitle) {
                        contactIndex = index
                    }
                }
            }
            if (contactIndex >= 0) {
                self.viewModel.ccSelectedContacts.remove(at: contactIndex)
            }
        } else if (picker == composeView.bccContactPicker) {
            var contactIndex = -1
            let selectedContacts = self.viewModel.bccSelectedContacts
            for (index, selectedContact) in selectedContacts.enumerated() {
                if let contact = contact as? ContactVO {
                    if (contact.displayEmail == selectedContact.displayEmail) {
                        contactIndex = index
                    }
                } else if let contactGroup = contact as? ContactGroupVO {
                    if (contact.contactTitle == selectedContact.contactTitle) {
                        contactIndex = index
                    }
                }
            }
            if (contactIndex >= 0) {
                self.viewModel.bccSelectedContacts.remove(at: contactIndex)
            }
        }
    }
}


// MARK : compose data source
extension ComposeEmailViewController : ComposeViewDataSource {

    func composeViewContactsModelForPicker(_ composeView: ComposeView, picker: ContactPicker) -> [ContactPickerModelProtocol] {
        return contacts
    }
    
    func composeViewSelectedContactsForPicker(_ composeView: ComposeView, picker: ContactPicker) ->  [ContactPickerModelProtocol] {
        var selectedContacts: [ContactPickerModelProtocol] = []
        if (picker == composeView.toContactPicker) {
            selectedContacts = self.viewModel.toSelectedContacts
        } else if (picker == composeView.ccContactPicker) {
            selectedContacts = self.viewModel.ccSelectedContacts
        } else if (picker == composeView.bccContactPicker) {
            selectedContacts = self.viewModel.bccSelectedContacts
        }
        return selectedContacts
    }
}


// MARK: - AttachmentsViewControllerDelegate
extension ComposeEmailViewController: AttachmentsTableViewControllerDelegate {
    
    func attachments(_ attViewController: AttachmentsTableViewController, didFinishPickingAttachments attachments: [Any]) {
        self.attachments = attachments
    }
    
    func attachments(_ attViewController: AttachmentsTableViewController, didPickedAttachment attachment: Attachment) {
        self.collectDraft()
        self.viewModel.uploadAtt(attachment)
    }
    
    func attachments(_ attViewController: AttachmentsTableViewController, didDeletedAttachment attachment: Attachment) {
        self.collectDraft()
        
        if let content_id = attachment.contentID(), !content_id.isEmpty && attachment.inline() {
            self.removeEmbedImage(byCID: "cid:\(content_id)")
        }
        
        self.viewModel.deleteAtt(attachment)
    }
    
    func attachments(_ attViewController: AttachmentsTableViewController, didReachedSizeLimitation: Int) {
    }
    
    func attachments(_ attViewController: AttachmentsTableViewController, error: String) {
    }
}

// MARK: - UIPickerViewDataSource

extension ComposeEmailViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return kNumberOfColumnsInTimePicker
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if (component == 0) {
            return kNumberOfDaysInTimePicker
        } else {
            return kNumberOfHoursInTimePicker
        }
    }
}

// MARK: - UIPickerViewDelegate

extension ComposeEmailViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if (component == 0) {
            return "\(row) " + LocalString._composer_eo_days_title
        } else {
            return "\(row) " + LocalString._composer_eo_hours_title
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedDay = pickerView.selectedRow(inComponent: 0)
        let selectedHour = pickerView.selectedRow(inComponent: 1)
        
        let day = "\(selectedDay) " + LocalString._composer_eo_days_title
        let hour = "\(selectedHour) " + LocalString._composer_eo_hours_title
        self.composeView.updateExpirationValue(((Double(selectedDay) * 24) + Double(selectedHour)) * 3600, text: "\(day) \(hour)")
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return super.canPerformAction(action, withSender: sender)
    }
    
}

extension ComposeEmailViewController: ExpirationWarningVCDelegate{
    func send() {
        self.sendMessageStepTwo()
    }
    
    func learnMore() {
        UIApplication.shared.openURL(learnMoreUrl)
    }
    
    
}


