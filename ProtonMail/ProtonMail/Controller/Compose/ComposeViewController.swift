//
//  ComposeEmailViewController.swift
//  ProtonMail - Created on 4/21/15.
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
import JavaScriptCore
import WebKit


class ComposeViewController : UIViewController, ViewModelProtocolNew {
    typealias argType = ComposeViewModel
    
    // view model
    fileprivate var viewModel : ComposeViewModel!

    //
    @IBOutlet var htmlEditor: HtmlEditor!
    private var headerView : ComposeView!
    
    
    // offsets default
    fileprivate var headerHeight : CGFloat = 186
    
    func set(viewModel: ComposeViewModel) {
        self.viewModel = viewModel
    }
    
    ///
    func inactiveViewModel() {
        self.stopAutoSave()
        NotificationCenter.default.removeObserver(self)
        self.dismissKeyboard()
        if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
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
    
    // MARK : const values
    fileprivate let kNumberOfColumnsInTimePicker: Int = 2
    fileprivate let kNumberOfDaysInTimePicker: Int = 30
    fileprivate let kNumberOfHoursInTimePicker: Int = 24

    // move it to coordinator
    fileprivate let kPasswordSegue : String          = "to_eo_password_segue"
    fileprivate let kExpirationWarningSegue : String = "expiration_warning_segue"

    fileprivate var isShowingConfirm : Bool = false

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cancelButton = UIBarButtonItem(title: LocalString._general_cancel_button,
                                            style: UIBarButtonItem.Style.plain,
                                            target: self,
                                            action: #selector(ComposeViewController.cancel_clicked(_:)))
        self.navigationItem.leftBarButtonItem = cancelButton
        
        self.configureNavigationBar()
        self.setNeedsStatusBarAppearanceUpdate()
        
        ///
        self.headerView = ComposeView(nibName: "ComposeView", bundle: nil)
        self.headerView.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: headerHeight + 60)
        self.headerView.delegate = self
        self.headerView.datasource = self
        self.htmlEditor.delegate = self
        self.htmlEditor.set(header: self.headerView.view)
        
        ///
        self.automaticallyAdjustsScrollViewInsets = false
        
        ///
        self.headerView.delegate = self
        self.headerView.datasource = self

        /// load all contacts
        self.contacts = sharedContactDataService.allContactVOs()
        self.retrieveAllContacts()

       // self.expirationPicker.alpha = 0.0
//        self.expirationPicker.dataSource = self
//        self.expirationPicker.delegate = self

        self.attachments = viewModel.getAttachments()

        /// change message as read
        self.viewModel.markAsRead();
        
        //  update header view data
        self.updateMessageView()
    }

    internal func retrieveAllContacts() {
        sharedContactDataService.getContactVOs { (contacts, error) in
            if let error = error {
                PMLog.D(" error: \(error)")
            }
            self.contacts = contacts
//            self.headerView.reloadData()
        }
    }

    internal func updateEmbedImages() {
        if let atts = viewModel.getAttachments() {
            for att in atts {
                if let content_id = att.contentID(), !content_id.isEmpty && att.inline() {
                    att.base64AttachmentData({ (based64String) in
                        if !based64String.isEmpty {
                            self.htmlEditor.update(embedImage: "cid:\(content_id)", encoded: "data:\(att.mimeType);base64,\(based64String)")
                        }
                    })
                }
            }
        }
    }

    fileprivate func dismissKeyboard() {
        //self.headerView.dismissKeyboard()
    }

    fileprivate func updateMessageView() {
        self.headerView.subject.text = self.viewModel.getSubject()
        //self.shouldShowKeyboard = false
        let body = self.viewModel.getHtmlBody()
        self.htmlEditor.setHtml(body: body)

        guard let addr = self.viewModel.getDefaultSendAddress() else {
            return
        }
        self.headerView.updateFromValue(addr.email, pickerEnabled: true)
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
                    alertController.addAction(UIAlertAction(title: LocalString._general_dont_remind_action,
                                                            style: .destructive, handler: { action in
                        userCachedStatus.isPMMEWarningDisabled = true
                    }))
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.headerView.notifyViewSize(false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.updateAttachmentButton()
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ComposeViewController.willResignActiveNotification(_:)),
                                               name: UIApplication.willResignActiveNotification,
                                               object:nil)
        setupAutoSave()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
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
//        if segue.identifier == kPasswordSegue {
//            let popup = segue.destination as! ComposePasswordViewController
//            popup.pwdDelegate = self
//            popup.setupPasswords(self.encryptionPassword, confirmPassword: self.encryptionConfirmPassword, hint: self.encryptionPasswordHint)
//            self.setPresentationStyleForSelfController(self, presentingController: popup)
//        } else if segue.identifier == kExpirationWarningSegue {
//            let popup = segue.destination as! ExpirationWarningViewController
//            popup.delegate = self
//            let nonePMEmail = self.encryptionPassword.count <= 0 ? self.composeView.nonePMEmails : [String]()
//            popup.config(needPwd: nonePMEmail,
//                         pgp: self.composeView.pgpEmails)
//        }
    }
    
    internal func setPresentationStyleForSelfController(_ selfController : UIViewController,  presentingController: UIViewController) {
        presentingController.providesPresentationContextTransitionStyle = true
        presentingController.definesPresentationContext = true
        presentingController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
    }
    
    @IBAction func send_clicked(_ sender: AnyObject) {
        self.dismissKeyboard()

//        if let suject = self.composeView.subject.text {
//            if !suject.isEmpty {
//                self.sendMessage()
//                return
//            }
//        }
//
//        let alertController = UIAlertController(title: LocalString._composer_compose_action,
//                                                message: LocalString._composer_send_no_subject_desc,
//                                                preferredStyle: .alert)
//        alertController.addAction(UIAlertAction(title: LocalString._general_send_action,
//                                                style: .destructive, handler: { (action) -> Void in
//            self.sendMessage()
//        }))
//        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
//        present(alertController, animated: true, completion: nil)
    }

    internal func sendMessage () {
//        if self.composeView.expirationTimeInterval > 0 {
//            if self.composeView.hasPGPPinned ||
//                (self.composeView.hasNonePMEmails && self.encryptionPassword.count <= 0 ) {
//
//                self.performSegue(withIdentifier: self.kExpirationWarningSegue, sender: self)
//                return
//            }
//
//        }
//        delay(0.3) {
//            self.sendMessageStepTwo()
//        }
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
        
//        if self.viewModel.hasDraft || composeView.hasContent || ((attachments?.count ?? 0) > 0) {
//            self.isShowingConfirm = true
//            let alertController = UIAlertController(title: LocalString._general_confirmation_title,
//                                                    message: nil, preferredStyle: .actionSheet)
//            alertController.addAction(UIAlertAction(title: LocalString._composer_save_draft_action,
//                                                    style: .default, handler: { (action) -> Void in
//                self.stopAutoSave()
//                self.collectDraft()
//                self.viewModel.updateDraft()
//                dismiss()
//            }))
//
//            alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button,
//                                                    style: .cancel, handler: { (action) -> Void in
//                self.isShowingConfirm = false
//            }))
//
//            alertController.addAction(UIAlertAction(title: LocalString._composer_discard_draft_action,
//                                                    style: .destructive, handler: { (action) -> Void in
//                self.stopAutoSave()
//                self.viewModel.deleteDraft()
//                dismiss()
//            }))
//
//            alertController.popoverPresentationController?.barButtonItem = sender
//            alertController.popoverPresentationController?.sourceRect = self.view.frame
//            present(alertController, animated: true, completion: nil)
//        } else {
            dismiss()
//        }
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
        //self.collectDraft()
        self.viewModel.updateDraft()
    }
    
    fileprivate func collectDraft() {
//        let orignal = self.getOrignalEmbedImages()
//        let edited = self.getEditedEmbedImages()
//        self.checkEmbedImageEdit(orignal!, edited: edited!)
//        var body = self.getHTML()
//        if (body?.isEmpty)! {
//            body = "<div><br></div>"
//        }

//        self.viewModel.collectDraft (
//            self.composeView.subject.text!,
//            body: body!,
//            expir: self.composeView.expirationTimeInterval,
//            pwd:self.encryptionPassword,
//            pwdHit:self.encryptionPasswordHint
//        )
    }

//    func getHTML() -> String! {
//        // this method is copy of super's with one difference: it escapes backslash before calling private removeQuotesFromHTML: and tidyHTML:, since they are messing up backslash with some other special symbols and replace it with other unexpected things. This problem is implementation detail of ZSSRichTextEditor.
//        guard var html = self.webView.stringByEvaluatingJavaScript(from: "zss_editor.getHTML();") else {
//            return ""
//        }
//        html = html.replacingOccurrences(of: "\\", with: "&#92;", options: .caseInsensitive, range: nil)
//        html = self.perform(Selector(("removeQuotesFromHTML:")), with: html).takeUnretainedValue() as! String
//        html = self.perform(Selector(("tidyHTML:")), with: html).takeUnretainedValue() as! String
//        return html
//    }
    
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
            self.headerView.updateAttachmentButton(true)
        } else {
            self.headerView.updateAttachmentButton(false)
        }
    }
}
extension ComposeViewController : HtmlEditorDelegate {
    func ContentLoaded() {
        updateEmbedImages()
    }
}

//
//extension ComposeEmailViewController : ComposePasswordViewControllerDelegate {
//
//    func Cancelled() {
//
//    }
//
//    func Apply(_ password: String, confirmPassword: String, hint: String) {
//        self.encryptionPassword = password
//        self.encryptionConfirmPassword = confirmPassword
//        self.encryptionPasswordHint = hint
//        self.composeView.showEncryptionDone()
//        self.updateEO()
//    }
//
//    func Removed() {
//        self.encryptionPassword = ""
//        self.encryptionConfirmPassword = ""
//        self.encryptionPasswordHint = ""
//
//        self.composeView.showEncryptionRemoved()
//        self.updateEO()
//    }
//}
//
// MARK : - view extensions
extension ComposeViewController : ComposeViewDelegate {
    func composeViewDidTapContactGroupSubSelection(_ composeView: ComposeView,
                                                   contactGroup: ContactGroupVO,
                                                   callback: @escaping (([String]) -> Void)) {
        
    }
    
    func ComposeViewDidSizeChanged(_ size: CGSize, showPicker: Bool) {
        self.headerHeight = size.height
        // resize header view
        self.headerView.view.frame.size.height = self.headerHeight
//        self.updateContentLayout(true)
//        self.webView.scrollView.isScrollEnabled = !showPicker
        self.htmlEditor.updateHeaderHeight()

    }
    
    func ComposeViewDidOffsetChanged(_ offset: CGPoint) {
    }
    
    func composeViewWillPresentSubview() {
        //self.webView?.scrollView.isScrollEnabled = false
    }
    func composeViewWillDismissSubview() {
       // self.webView?.scrollView.isScrollEnabled = true
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
                            self.htmlEditor.update(signature: signature)
                        }
                        ActivityIndicatorHelper.showActivityIndicator(at: self.view)
                        self.viewModel.updateAddressID(addr.address_id).done { _ in
                            self.headerView.updateFromValue(addr.email, pickerEnabled: true)
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
            alertController.popoverPresentationController?.sourceView = self.headerView.fromView
            alertController.popoverPresentationController?.sourceRect = self.headerView.fromView.frame
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func composeViewDidTapNextButton(_ composeView: ComposeView) {
        switch(actualEncryptionStep) {
        case EncryptionStep.DefinePassword:
            self.encryptionPassword = (composeView.encryptedPasswordTextField.text ?? "").trim()
            if !self.encryptionPassword.isEmpty {
                self.actualEncryptionStep = EncryptionStep.ConfirmPassword
                self.headerView.showConfirmPasswordView()
            } else {
                self.headerView.showPasswordAndConfirmDoesntMatch(LocalString._composer_eo_empty_pwd_desc)
            }
        case EncryptionStep.ConfirmPassword:
            self.encryptionConfirmPassword = (composeView.encryptedPasswordTextField.text ?? "").trim()
            
            if (self.encryptionPassword == self.encryptionConfirmPassword) {
                self.actualEncryptionStep = EncryptionStep.DefineHintPassword
                self.headerView.hidePasswordAndConfirmDoesntMatch()
                self.headerView.showPasswordHintView()
            } else {
                self.headerView.showPasswordAndConfirmDoesntMatch(LocalString._composer_eo_dismatch_pwd_desc)
            }
            
        case EncryptionStep.DefineHintPassword:
            self.encryptionPasswordHint = (composeView.encryptedPasswordTextField.text ?? "").trim()
            self.actualEncryptionStep = EncryptionStep.DefinePassword
            self.headerView.showEncryptionDone()
        default:
            PMLog.D("No step defined.")
        }
    }

    func composeViewDidTapEncryptedButton(_ composeView: ComposeView) {
        self.performSegue(withIdentifier: kPasswordSegue, sender: self)
    }

    func composeViewDidTapAttachmentButton(_ composeView: ComposeView) {
        //TODO:: change this to segue
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
//        self.expirationPicker.alpha = 1
//        self.view.bringSubview(toFront: expirationPicker)
    }

    func composeViewHideExpirationView(_ composeView: ComposeView) {
        //self.expirationPicker.alpha = 0
    }

    func composeViewCancelExpirationData(_ composeView: ComposeView) {
      //  self.expirationPicker.selectRow(0, inComponent: 0, animated: true)
      //  self.expirationPicker.selectRow(0, inComponent: 1, animated: true)
    }

    func composeViewCollectExpirationData(_ composeView: ComposeView) {
//        let selectedDay = expirationPicker.selectedRow(inComponent: 0)
//        let selectedHour = expirationPicker.selectedRow(inComponent: 1)
//        if self.composeView.setExpirationValue(selectedDay, hour: selectedHour) {
//            self.expirationPicker.alpha = 0
//        }
//        self.updateEO()
    }

    func updateEO() {
//        self.viewModel.updateEO(expir: self.composeView.expirationTimeInterval,
//                                pwd: self.encryptionPassword,
//                                pwdHit: self.encryptionPasswordHint)
//        self.composeView.reloadPicker()
    }

    func composeView(_ composeView: ComposeView, didAddContact contact: ContactPickerModelProtocol, toPicker picker: ContactPicker) {
    //    if (picker == self.headerView.toPicker) {
    //        self.viewModel.toSelectedContacts.append(contact)
    //    }
        
//        else if (picker == composeView.ccContactPicker) {
//            self.viewModel.ccSelectedContacts.append(contact)
//        } else if (picker == composeView.bccContactPicker) {
//            self.viewModel.bccSelectedContacts.append(contact)
//        }
        
        if self.viewModel.isValidNumberOfRecipients() == false {
            // rollback
    //        if (picker == self.headerView.toPicker) {
    //            self.viewModel.toSelectedContacts.removeLast()
    //        }
//            else if (picker == composeView.ccContactPicker) {
//                self.viewModel.ccSelectedContacts.removeLast()
//            } else if (picker == composeView.bccContactPicker) {
//                self.viewModel.bccSelectedContacts.removeLast()
//            }
            
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
   //     if (picker == self.headerView.toPicker) {
//            var contactIndex = -1
//            let selectedContacts = self.viewModel.toSelectedContacts
//            for (index, selectedContact) in selectedContacts.enumerated() {
//                if let contact = contact as? ContactVO {
//                    if (contact.displayEmail == selectedContact.displayEmail) {
//                        contactIndex = index
//                    }
//                } else if let contactGroup = contact as? ContactGroupVO {
//                    if (contact.contactTitle == selectedContact.contactTitle) {
//                        contactIndex = index
//                    }
//                }
//            }
//            if (contactIndex >= 0) {
//                self.viewModel.toSelectedContacts.remove(at: contactIndex)
//            }
//        }
//        else if (picker == composeView.ccContactPicker) {
//            var contactIndex = -1
//            let selectedContacts = self.viewModel.ccSelectedContacts
//            for (index, selectedContact) in selectedContacts.enumerated() {
//                if (contact.email == selectedContact.email) {
//                    contactIndex = index
//                }
//            }
//            if (contactIndex >= 0) {
//                self.viewModel.ccSelectedContacts.remove(at: contactIndex)
//            }
//        } else if (picker == composeView.bccContactPicker) {
//            var contactIndex = -1
//            let selectedContacts = self.viewModel.bccSelectedContacts
//            for (index, selectedContact) in selectedContacts.enumerated() {
//                if (contact.email == selectedContact.email) {
//                    contactIndex = index
//                }
//            }
//            if (contactIndex >= 0) {
//                self.viewModel.bccSelectedContacts.remove(at: contactIndex)
//            }
//        }
    }
}


// MARK : compose data source
extension ComposeViewController : ComposeViewDataSource {

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
extension ComposeViewController: AttachmentsTableViewControllerDelegate {

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
            self.htmlEditor.remove(embedImage: "cid:\(content_id)")
        }
        self.viewModel.deleteAtt(attachment)
    }

    func attachments(_ attViewController: AttachmentsTableViewController, didReachedSizeLimitation: Int) {
    }

    func attachments(_ attViewController: AttachmentsTableViewController, error: String) {
    }
}
//
//// MARK: - UIPickerViewDataSource
//
//extension ComposeEmailViewController: UIPickerViewDataSource {
//    func numberOfComponents(in pickerView: UIPickerView) -> Int {
//        return kNumberOfColumnsInTimePicker
//    }
//    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//        if (component == 0) {
//            return kNumberOfDaysInTimePicker
//        } else {
//            return kNumberOfHoursInTimePicker
//        }
//    }
//}
//
//// MARK: - UIPickerViewDelegate
//
//extension ComposeEmailViewController: UIPickerViewDelegate {
//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        if (component == 0) {
//            return "\(row) " + LocalString._composer_eo_days_title
//        } else {
//            return "\(row) " + LocalString._composer_eo_hours_title
//        }
//    }
//
//    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        let selectedDay = pickerView.selectedRow(inComponent: 0)
//        let selectedHour = pickerView.selectedRow(inComponent: 1)
//
//        let day = "\(selectedDay) " + LocalString._composer_eo_days_title
//        let hour = "\(selectedHour) " + LocalString._composer_eo_hours_title
//        self.composeView.updateExpirationValue(((Double(selectedDay) * 24) + Double(selectedHour)) * 3600, text: "\(day) \(hour)")
//    }
//
//    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
//        return super.canPerformAction(action, withSender: sender)
//    }
//
//}
//
extension ComposeViewController: ExpirationWarningVCDelegate{
    func send() {
        self.sendMessageStepTwo()
    }

    func learnMore() {
        UIApplication.shared.openURL(.kEOLearnMore)
    }
}
