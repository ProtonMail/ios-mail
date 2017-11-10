//
//  ComposeEmailViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/21/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class ComposeEmailViewController: ZSSRichTextEditor, ViewModelProtocol {
    
    // view model
    fileprivate var viewModel : ComposeViewModel!
    
    func setViewModel(_ vm: Any) {
        self.viewModel = vm as! ComposeViewModel
    }
    
    func inactiveViewModel() {
        self.stopAutoSave()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object:nil)
        
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
    fileprivate var contacts: [ContactVO]! = [ContactVO]()
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
    
    deinit {
        if let wv = self.webView {
            wv.delegate = nil
            wv.stopLoading()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cancelButton = UIBarButtonItem(title:NSLocalizedString("Cancel", comment: "Action"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(ComposeEmailViewController.cancel_clicked(_:)))
        self.navigationItem.leftBarButtonItem = cancelButton
        
        configureNavigationBar()
        setNeedsStatusBarAppearanceUpdate()
        
        self.baseURL = URL( fileURLWithPath: "https://protonmail.ch")
        //self.formatHTML = false
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
        self.webView.scrollView.bringSubview(toFront: composeView.view)
        
        // update content values
        updateMessageView()
        self.contacts = sharedContactDataService.allContactVOs()
        retrieveAllContacts()
        
        self.expirationPicker.alpha = 0.0
        self.expirationPicker.dataSource = self
        self.expirationPicker.delegate = self
        
        self.attachments = viewModel.getAttachments()
        
        // update header layous
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
    
    
    internal func retrieveAllContacts() {
        sharedContactDataService.getContactVOs { (contacts, error) -> Void in
            if let error = error {
                PMLog.D(" error: \(error)")
            }
            self.contacts = contacts
            
            self.composeView.toContactPicker.reloadData()
            self.composeView.ccContactPicker.reloadData()
            self.composeView.bccContactPicker.reloadData()
            
            self.composeView.toContactPicker.contactCollectionView!.layoutIfNeeded()
            self.composeView.bccContactPicker.contactCollectionView!.layoutIfNeeded()
            self.composeView.ccContactPicker.contactCollectionView!.layoutIfNeeded()
            
            switch self.viewModel.messageAction!
            {
            case .openDraft, .reply, .replyAll:
                self.focus()
                self.composeView.notifyViewSize(true)
                break
            default:
                self.composeView.toContactPicker.becomeFirstResponder()
                break
            }
        }
    }
    
    internal func updateEmbedImages() {
        if let atts = viewModel.getAttachments() {
            for att in atts {
                if let content_id = att.getContentID(), !content_id.isEmpty && att.isInline() {
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
        self.composeView.updateFromValue(self.viewModel.getDefaultAddress()?.email ?? "", pickerEnabled: true)
        self.composeView.subject.text = self.viewModel.getSubject()
        self.shouldShowKeyboard = false
        self.setHTML(self.viewModel.getHtmlBody())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.updateAttachmentButton()
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(ComposeEmailViewController.statusBarHit(_:)), name: NSNotification.Name(rawValue: NotificationDefined.TouchStatusBar), object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ComposeEmailViewController.willResignActiveNotification(_:)), name: NSNotification.Name.UIApplicationWillResignActive, object:nil)
        setupAutoSave()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationDefined.TouchStatusBar), object:nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object:nil)
        
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
        
        let navigationBarTitleFont = UIFont.robotoLight(size: UIFont.Size.h2)
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedStringKey.foregroundColor: UIColor.white,
            NSAttributedStringKey.font: navigationBarTitleFont
        ]
        
        self.navigationItem.leftBarButtonItem?.title = NSLocalizedString("Cancel", comment: "Action")
        
        cancelButton.title = NSLocalizedString("Cancel", comment: "Action")
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
        
        let alertController = UIAlertController(title: NSLocalizedString("Compose", comment: "Action"),
                                                message: NSLocalizedString("Send message without subject?", comment: "Description"),
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Send", comment: "Action"), style: .destructive, handler: { (action) -> Void in
            self.sendMessage()
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Action"), style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func sendMessage () {
        if self.composeView.expirationTimeInterval > 0 {
            if self.composeView.hasOutSideEmails && self.encryptionPassword.characters.count <= 0 {
                let emails = self.composeView.allEmails
                //show loading
                ActivityIndicatorHelper.showActivityIndicatorAtView(view)
                let api = GetUserPublicKeysRequest<EmailsCheckResponse>(emails: emails)
                api.call({ (task, response: EmailsCheckResponse?, hasError : Bool) in
                    //hide loading
                    ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
                    if let res = response, res.hasOutsideEmails == false {
                        self.sendMessageStepTwo()
                    } else {
                        self.composeView.showPasswordAndConfirmDoesntMatch(self.composeView.kExpirationNeedsPWDError)
                    }
                })
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
            let alert = UIAlertController(title: NSLocalizedString("Alert", comment: "Title"),
                                          message: NSLocalizedString("You need at least one recipient to send", comment: "Description"),
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
            self.dismissKeyboard()
            if self.presentingViewController != nil {
                self.dismiss(animated: true, completion: nil)
            } else {
                let _ = self.navigationController?.popViewController(animated: true)
            }
        }
        
        if self.viewModel.hasDraft || composeView.hasContent || ((attachments?.count ?? 0) > 0) {
            let alertController = UIAlertController(title: NSLocalizedString("Confirmation", comment: "Title"),
                                                    message: nil, preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Save draft", comment: "Action"), style: .default, handler: { (action) -> Void in
                self.stopAutoSave()
                self.collectDraft()
                self.viewModel.updateDraft()
                dismiss()
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Action"), style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Discard draft", comment: "Action"), style: .destructive, handler: { (action) -> Void in
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
        self.viewModel.collectDraft(
            self.composeView.subject.text!,
            body: body!,
            expir: self.composeView.expirationTimeInterval,
            pwd:self.encryptionPassword,
            pwdHit:self.encryptionPasswordHint
        )
    }
    
    fileprivate func checkEmbedImageEdit(_ orignal: String, edited: String) {
        PMLog.D(edited)
        if let atts = viewModel.getAttachments() {
            for att in atts {
                if let content_id = att.getContentID(), !content_id.isEmpty && att.isInline() {
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
    }
    
    func Removed() {
        self.encryptionPassword = ""
        self.encryptionConfirmPassword = ""
        self.encryptionPasswordHint = ""
        
        self.composeView.showEncryptionRemoved()
    }
}

// MARK : - view extensions
extension ComposeEmailViewController : ComposeViewDelegate {
    func composeViewPickFrom(_ composeView: ComposeView) {
        if attachments?.count > 0 {
            let alertController = NSLocalizedString("Please remove all attachments before changing sender!", comment: "Error").alertController()
            alertController.addOKAction()
            self.present(alertController, animated: true, completion: nil)
        } else {
            var needsShow : Bool = false
            let alertController = UIAlertController(title: NSLocalizedString("Change sender address to ..", comment: "Title"), message: nil, preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Action"), style: .cancel, handler: nil))
            let multi_domains = self.viewModel.getAddresses()
            let defaultAddr = self.viewModel.getDefaultAddress()
            for addr in multi_domains {
                if addr.status == 1 && addr.receive == 1 && defaultAddr != addr {
                    needsShow = true
                    alertController.addAction(UIAlertAction(title: addr.email, style: .default, handler: { (action) -> Void in
                        if let signature = self.viewModel.getCurrrentSignature(addr.address_id) {
                            self.updateSignature("\(signature)")
                        }
                        self.viewModel.updateAddressID(addr.address_id)
                        self.composeView.updateFromValue(addr.email, pickerEnabled: true)
                    }))
                }
            }
            if needsShow {
                alertController.popoverPresentationController?.sourceView = self.composeView.fromView
                alertController.popoverPresentationController?.sourceRect = self.composeView.fromView.frame
                present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func ComposeViewDidSizeChanged(_ size: CGSize) {
        self.composeViewSize = size.height
        if #available(iOS 11.0, *) {
            self.updateComposeFrame()
        } else {
            let w = UIScreen.main.applicationFrame.width
            self.composeView.view.frame = CGRect(x: 0, y: 0, width: w, height: composeViewSize)
        }
        self.updateContentLayout(true)
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
                self.composeView.showPasswordAndConfirmDoesntMatch(self.composeView.kEmptyEOPWD)
            }
        case EncryptionStep.ConfirmPassword:
            self.encryptionConfirmPassword = (composeView.encryptedPasswordTextField.text ?? "").trim()
            
            if (self.encryptionPassword == self.encryptionConfirmPassword) {
                self.actualEncryptionStep = EncryptionStep.DefineHintPassword
                self.composeView.hidePasswordAndConfirmDoesntMatch()
                self.composeView.showPasswordHintView()
            } else {
                self.composeView.showPasswordAndConfirmDoesntMatch(self.composeView.kConfirmError)
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
    
    func composeViewDidTapExpirationButton(_ composeView: ComposeView)
    {
        self.expirationPicker.alpha = 1
        self.view.bringSubview(toFront: expirationPicker)
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
        if self.composeView.setExpirationValue(selectedDay, hour: selectedHour)
        {
            self.expirationPicker.alpha = 0
        }
    }
    
    func composeView(_ composeView: ComposeView, didAddContact contact: ContactVO, toPicker picker: MBContactPicker)
    {
        if (picker == composeView.toContactPicker) {
            self.viewModel.toSelectedContacts.append(contact)
        } else if (picker == composeView.ccContactPicker) {
            self.viewModel.ccSelectedContacts.append(contact)
        } else if (picker == composeView.bccContactPicker) {
            self.viewModel.bccSelectedContacts.append(contact)
        }
    }
    
    func composeView(_ composeView: ComposeView, didRemoveContact contact: ContactVO, fromPicker picker: MBContactPicker)
    {// here each logic most same, need refactor later
        if (picker == composeView.toContactPicker) {
            var contactIndex = -1
            let selectedContacts = self.viewModel.toSelectedContacts
            for (index, selectedContact) in (selectedContacts?.enumerated())! {
                if (contact.email == selectedContact.email) {
                    contactIndex = index
                }
            }
            if (contactIndex >= 0) {
                self.viewModel.toSelectedContacts.remove(at: contactIndex)
            }
        } else if (picker == composeView.ccContactPicker) {
            var contactIndex = -1
            let selectedContacts = self.viewModel.ccSelectedContacts
            for (index, selectedContact) in (selectedContacts?.enumerated())! {
                if (contact.email == selectedContact.email) {
                    contactIndex = index
                }
            }
            if (contactIndex >= 0) {
                self.viewModel.ccSelectedContacts.remove(at: contactIndex)
            }
        } else if (picker == composeView.bccContactPicker) {
            var contactIndex = -1
            let selectedContacts = self.viewModel.bccSelectedContacts
            for (index, selectedContact) in (selectedContacts?.enumerated())! {
                if (contact.email == selectedContact.email) {
                    contactIndex = index
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
    
    func composeViewContactsModelForPicker(_ composeView: ComposeView, picker: MBContactPicker) -> [Any]! {
        return contacts
    }
    
    func composeViewSelectedContactsForPicker(_ composeView: ComposeView, picker: MBContactPicker) ->  [Any]! {
        var selectedContacts: [ContactVO] = [ContactVO]()
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
        
        if let content_id = attachment.getContentID(), !content_id.isEmpty && attachment.isInline() {
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
            return "\(row) " + NSLocalizedString("days", comment: "")
        } else {
            return "\(row) " + NSLocalizedString("Hours", comment: "")
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedDay = pickerView.selectedRow(inComponent: 0)
        let selectedHour = pickerView.selectedRow(inComponent: 1)
        
        let day = "\(selectedDay) " + NSLocalizedString("days", comment: "")
        let hour = "\(selectedHour) " + NSLocalizedString("Hours", comment: "")
        self.composeView.updateExpirationValue(((Double(selectedDay) * 24) + Double(selectedHour)) * 3600, text: "\(day) \(hour)")
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return super.canPerformAction(action, withSender: sender)
    }
    
}


