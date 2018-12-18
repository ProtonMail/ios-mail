//
//  ComposeViewController
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
import WebKit
import JavaScriptCore
import PromiseKit
import AwaitKit


class ComposeViewController : UIViewController, ViewModelProtocol, CoordinatedNew {
    typealias viewModelType = ComposeViewModel
    typealias coordinatorType = ComposeCoordinator
    
    ///
    var viewModel : ComposeViewModel! // view model
    private var coordinator: ComposeCoordinator?

    ///  UI
    @IBOutlet var htmlEditor: HtmlEditor!
    @IBOutlet weak var expirationPicker: UIPickerView!
    var headerView : ComposeView!
    private var cancelButton: UIBarButtonItem! //cancel button.
    
    ///
    private var timer : Timer? //auto save timer
    
    /// private vars
    private var contacts: [ContactPickerModelProtocol] = []
    private var attachments: [Any]?
    
    private var actualEncryptionStep              = EncryptionStep.DefinePassword
    var encryptionPassword: String        = ""
    var encryptionConfirmPassword: String = ""
    var encryptionPasswordHint: String    = ""
    private var hasAccessToAddressBook: Bool      = false
    
    #if APP_EXTENSION
    private var isSending = false
    #endif
    
    private var cachedHeaderHeight : CGFloat      = 186 //offsets default

    /// const values
    private let kNumberOfColumnsInTimePicker: Int = 2
    private let kNumberOfDaysInTimePicker: Int    = 30
    private let kNumberOfHoursInTimePicker: Int   = 24
    
    var pickedGroup: ContactGroupVO?
    var pickedCallback: (([DraftEmailData]) -> Void)?

    // view model setter
    func set(viewModel: ComposeViewModel) {
        self.viewModel = viewModel
    }
    
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
    
    func set(coordinator: ComposeCoordinator) {
        self.coordinator = coordinator
    }

    ///
    func inactiveViewModel() {
        self.stopAutoSave()
        NotificationCenter.default.removeObserver(self)
        self.dismissKeyboard()
        self.dismiss()
    }
    private var isShowingConfirm : Bool = false

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(self.coordinator != nil)
        assert(self.viewModel != nil)
        
        self.cancelButton = UIBarButtonItem(title: LocalString._general_cancel_button,
                                            style: UIBarButtonItem.Style.plain,
                                            target: self,
                                            action: #selector(ComposeViewController.cancelAction(_:)))
        self.navigationItem.leftBarButtonItem = cancelButton
        
        self.configureNavigationBar()
        self.setNeedsStatusBarAppearanceUpdate()
        
        ///
        self.headerView = ComposeView(nibName: "ComposeView", bundle: nil)
        self.headerView.view.frame = CGRect(x: 0, y: 0,
                                            width: self.view.frame.width,
                                            height: self.cachedHeaderHeight + 60)
        self.headerView.delegate = self
        self.headerView.datasource = self
        self.htmlEditor.delegate = self
        self.htmlEditor.set(header: self.headerView.view)
        
        ///
        self.automaticallyAdjustsScrollViewInsets = false
        self.extendedLayoutIncludesOpaqueBars = true
        
        ///
        self.headerView.delegate = self
        self.headerView.datasource = self
        
        //  update header view data
        self.updateMessageView()
        
        // load all contacts and groups
        // TODO: move to view model
        firstly { () -> Promise<Void> in
            self.contacts = sharedContactDataService.allContactVOs() // contacts in core data
                return retrieveAllContacts() // contacts in phone book
        }.done { () -> Void in
            // get contact groups
            
            // TODO: figure where to put this thing
            if sharedUserDataService.isPaidUser() {
                self.contacts.append(contentsOf: sharedContactGroupsDataService.getAllContactGroupVOs())
            }
            
            // Sort contacts and contact groups
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
                    // contact groups go first
                    if let _ = first as? ContactGroupVO {
                        return true
                    } else {
                        return false
                    }
                }
            }
            
            self.headerView.toContactPicker.reloadData()
            self.headerView.ccContactPicker.reloadData()
            self.headerView.bccContactPicker.reloadData()
            
            self.headerView.toContactPicker.contactCollectionView!.layoutIfNeeded()
            self.headerView.bccContactPicker.contactCollectionView!.layoutIfNeeded()
            self.headerView.ccContactPicker.contactCollectionView!.layoutIfNeeded()
            
            switch self.viewModel.messageAction!
            {
            case .openDraft, .reply, .replyAll:
                if !self.isShowingConfirm {
                    //TODO:: remove the focus for now revert later
                    //self.focus()
                }
                self.headerView.notifyViewSize(true)
                break
            default:
                if !self.isShowingConfirm {
                    //TODO:: remove the focus for now revert later
                    //let _ = self.composeView.toContactPicker.becomeFirstResponder()
                }
                break
            }
        }.catch { error in
            // TODO: handle error
            PMLog.D("Load all contacts and groups error \(error)")
        }
        
        self.expirationPicker.alpha = 0.0
        self.expirationPicker.dataSource = self
        self.expirationPicker.delegate = self

        self.attachments = viewModel.getAttachments()

        /// change message as read
        self.viewModel.markAsRead();
    }

    private func retrieveAllContacts() -> Promise<Void> {
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
                            self.htmlEditor.update(embedImage: "cid:\(content_id)", encoded: "data:\(att.mimeType);base64,\(based64String)")
                        }
                    })
                }
            }
        }
    }

    private func dismiss() {
        if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }

    private func dismissKeyboard() {
        self.headerView.subject.becomeFirstResponder()
        self.headerView.subject.resignFirstResponder()
    }

    private func updateMessageView() {
        self.headerView.subject.text = self.viewModel.getSubject()
        let body = self.viewModel.getHtmlBody()
        self.htmlEditor.setHtml(body: body)
        
        // update draft if first time create
        if viewModel.getActionType() != .openDraft {
            self.viewModel.collectDraft (
                self.viewModel.getSubject(),
                body: body,
                expir: self.headerView.expirationTimeInterval,
                pwd:self.encryptionPassword,
                pwdHit:self.encryptionPasswordHint
            )
            self.viewModel.updateDraft()
        }
        
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
        NotificationCenter.default.addKeyboardObserver(self)
        setupAutoSave()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.removeKeyboardObserver(self)
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

    @IBAction func sendAction(_ sender: AnyObject) {
        self.dismissKeyboard()
        if let suject = self.headerView.subject.text {
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
        if self.headerView.expirationTimeInterval > 0 {
            if self.headerView.hasPGPPinned ||
                (self.headerView.hasNonePMEmails && self.encryptionPassword.count <= 0 ) {
                self.coordinator?.go(to: .expirationWarning)
                return
            }
            
        }
        delay(0.3) {
            self.sendMessageStepTwo()
        }
    }
    
    func sendMessageStepTwo() {
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
        self.collectDraftData().done {
            self.viewModel.sendMessage()
            
            #if APP_EXTENSION
            self.isSending = true
            self.hideExtensionWithCompletionHandler(completion: { (Bool) -> Void in
                self.isSending = false
                self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            })
            #else
            // show messagex
            delay(0.5) {
                NSError.alertMessageSendingToast()
            }
            self.dismiss()
            #endif
        }
    }
    
    #if APP_EXTENSION
    private var observation: NSKeyValueObservation?
    func hideExtensionWithCompletionHandler(completion:@escaping (Bool) -> Void) {
        let alert = UIAlertController(title: self.isSending ? LocalString._sending_message : LocalString._closing_draft,
                                      message: LocalString._please_wait_in_foreground,
                                      preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
        
        self.observation = sharedMessageQueue.observe(\.queue) { [weak self] _, change in
            if sharedMessageQueue.queue.isEmpty {
                let animationBlock: ()->Void = {
                    if let view = self?.navigationController?.view {
                        view.transform = CGAffineTransform(translationX: 0, y: view.frame.size.height)
                    }
                }
                alert.dismiss(animated: true, completion: nil)
                self?.observation?.invalidate()
                self?.observation = nil
                keymaker.lockTheApp()
                UIView.animate(withDuration: 0.25, animations: animationBlock, completion: completion)
            }
        }
    }
    #endif
    
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        let dismiss: (() -> Void) = {
            self.isShowingConfirm = false
            self.dismissKeyboard()
            
            #if APP_EXTENSION
            self.hideExtensionWithCompletionHandler(completion: { (Bool) -> Void in
                let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
                self.extensionContext?.cancelRequest(withError: cancelError)
            })
            #else
            self.dismiss()
            #endif
        }
        
        if self.viewModel.hasDraft || self.headerView.hasContent || ((attachments?.count ?? 0) > 0) {
            self.isShowingConfirm = true
            let alertController = UIAlertController(title: LocalString._general_confirmation_title,
                                                    message: nil, preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: LocalString._composer_save_draft_action,
                                                    style: .default, handler: { (action) -> Void in
                self.stopAutoSave()
                self.collectDraftData().done {
                    self.viewModel.updateDraft()
                }.catch { _ in
                    
                }.finally {
                    dismiss()
                }
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
    private func setupAutoSave(firstTime : Bool = false) {
        self.timer = Timer.scheduledTimer(timeInterval: 120,
                                          target: self,
                                          selector: #selector(ComposeViewController.autoSaveTimer),
                                          userInfo: nil,
                                          repeats: true)
    }
    
    private func stopAutoSave() {
        if let t = self.timer {
            t.invalidate()
            self.timer = nil
        }
    }
    
    @objc func autoSaveTimer() {
        self.updateCIDs().then {
            self.collectDraftData()
        }.done {
            self.viewModel.updateDraft()
        }
    }
    
    private func updateCIDs() -> Guarantee<Void> {
        return Guarantee { ret in
            let orignalPromise = self.htmlEditor.getOrignalCIDs()
            let editedPromise  = self.htmlEditor.getEditedCIDs()
            when(fulfilled: orignalPromise, editedPromise).done { (orignal, edited) in
                self.checkEmbedImageEdit(orignal, edited: edited)
            }.catch { (_) in
                //
            }.finally {
                ret(())
            }
        }
    }
    
    private func collectDraftData()  -> Guarantee<Void>  {
        return Guarantee { ret in
            self.htmlEditor.getHtml().done { body in
                
                var html = body.replacingOccurrences(of: "\\", with: "&#92;", options: .caseInsensitive, range: nil)
                html = body.replacingOccurrences(of: "\"", with: "\\\"", options: .caseInsensitive, range: nil)
                html = body.replacingOccurrences(of: "“", with: "&quot;", options: .caseInsensitive, range: nil)
                html = body.replacingOccurrences(of: "”", with: "&quot;", options: .caseInsensitive, range: nil)
                html = body.replacingOccurrences(of: "\r", with: "\\r", options: .caseInsensitive, range: nil)
                html = body.replacingOccurrences(of: "\n", with: "\\n", options: .caseInsensitive, range: nil)
                html = body.replacingOccurrences(of: "<br>", with: "<br />", options: .caseInsensitive, range: nil)
                html = body.replacingOccurrences(of: "<hr>", with: "<hr />", options: .caseInsensitive, range: nil)
                
                self.viewModel.collectDraft (
                    self.headerView.subject.text!,
                    body: html.isEmpty ? body : html,
                    expir: self.headerView.expirationTimeInterval,
                    pwd:self.encryptionPassword,
                    pwdHit:self.encryptionPasswordHint
                )
            }.catch { _ in
                //handle the errors
            }.finally {
                ret(())
            }
        }
    }
    
    private func checkEmbedImageEdit(_ orignal: String, edited: String) {
        if let atts = viewModel.getAttachments() {
            for att in atts {
                if let content_id = att.contentID(), !content_id.isEmpty && att.inline() {
                    if orignal.contains(content_id) {
                        if !edited.contains(content_id) {
                            self.viewModel.deleteAtt(att)
                        }
                    }
                }
            }
        }
    }
    
    private func updateAttachmentButton () {
        if attachments?.count > 0 {
            self.headerView.updateAttachmentButton(true)
        } else {
            self.headerView.updateAttachmentButton(false)
        }
    }
}
extension ComposeViewController : HtmlEditorDelegate {
    func ContentLoaded() {
        self.updateEmbedImages()
    }
}


// MARK : - view extensions
extension ComposeViewController : ComposeViewDelegate {
    
    func composeViewWillPresentSubview() {
        self.htmlEditor.isScrollEnabled = false
    }
    func composeViewWillDismissSubview() {
        self.htmlEditor.isScrollEnabled = true
    }
    
    func lockerCheck(model: ContactPickerModelProtocol, progress: () -> Void, complete: LockCheckComplete?) {
        self.viewModel.lockerCheck(model: model, progress: progress, complete: complete)
    }
    
    func composeViewPickFrom(_ composeView: ComposeView) {
        var needsShow : Bool = false
        let alertController = UIAlertController(title: LocalString._composer_change_sender_address_to,
                                                message: nil,
                                                preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button,
                                                style: .cancel,
                                                handler: nil))
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
    
    func ComposeViewDidSizeChanged(_ size: CGSize, showPicker: Bool) {
        self.cachedHeaderHeight = size.height
        // resize header view
        self.headerView.view.frame.size.height = self.cachedHeaderHeight
        self.headerView.view.frame.size.width = self.view.frame.width
        self.htmlEditor.isScrollEnabled = !showPicker
        self.htmlEditor.updateHeaderHeight()
    }
    
    func ComposeViewDidOffsetChanged(_ offset: CGPoint) {
        
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
        self.coordinator?.go(to: .password)
    }
    
    func composeViewDidTapContactGroupSubSelection(_ composeView: ComposeView,
                                                   contactGroup: ContactGroupVO,
                                                   callback: @escaping (([DraftEmailData]) -> Void)) {
        self.pickedGroup = contactGroup
        self.pickedCallback = callback
        self.coordinator?.go(to: .subSelection)
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
        if self.headerView.setExpirationValue(selectedDay, hour: selectedHour) {
            self.expirationPicker.alpha = 0
        }
        self.updateEO()
    }

    func updateEO() {
        self.viewModel.updateEO(expir: self.headerView.expirationTimeInterval,
                                pwd: self.encryptionPassword,
                                pwdHit: self.encryptionPasswordHint)
        self.headerView.reloadPicker()
    }

    func composeView(_ composeView: ComposeView, didAddContact contact: ContactPickerModelProtocol, toPicker picker: ContactPicker) {
        if (picker == self.headerView.toContactPicker) {
            self.viewModel.toSelectedContacts.append(contact)
        } else if (picker == headerView.ccContactPicker) {
            self.viewModel.ccSelectedContacts.append(contact)
        } else if (picker == headerView.bccContactPicker) {
            self.viewModel.bccSelectedContacts.append(contact)
        }
        
        if self.viewModel.isValidNumberOfRecipients() == false {
            // rollback
            if (picker == self.headerView.toContactPicker) {
                self.viewModel.toSelectedContacts.removeLast()
            } else if (picker == headerView.ccContactPicker) {
                self.viewModel.ccSelectedContacts.removeLast()
            } else if (picker == headerView.bccContactPicker) {
                self.viewModel.bccSelectedContacts.removeLast()
            }
            
            // present error
            let alert = UIAlertController(title: LocalString._too_many_recipients_title,
                                          message: String.init(format: LocalString._max_number_of_recipients_is_number,
                                                               Constants.App.MaxNumberOfRecipients),
                                          preferredStyle: .alert)
            alert.addAction(.init(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            picker.reloadData()
            return
        }
    }

    func composeView(_ composeView: ComposeView, didRemoveContact contact: ContactPickerModelProtocol, fromPicker picker: ContactPicker) {
        // here each logic most same, need refactor later
        if (picker == self.headerView.toContactPicker) {
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
        } else if (picker == headerView.ccContactPicker) {
            var contactIndex = -1
            let selectedContacts = self.viewModel.ccSelectedContacts
            for (index, selectedContact) in selectedContacts.enumerated() {
                if (contact.displayEmail == selectedContact.displayEmail) {
                    contactIndex = index
                }
            }
            if (contactIndex >= 0) {
                self.viewModel.ccSelectedContacts.remove(at: contactIndex)
            }
        } else if (picker == headerView.bccContactPicker) {
            var contactIndex = -1
            let selectedContacts = self.viewModel.bccSelectedContacts
            for (index, selectedContact) in selectedContacts.enumerated() {
                if (contact.displayEmail == selectedContact.displayEmail) {
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
        self.collectDraftData().done {
            self.viewModel.uploadAtt(attachment)
        }
    }

    func attachments(_ attViewController: AttachmentsTableViewController, didDeletedAttachment attachment: Attachment) {
        self.collectDraftData().done {
            if let content_id = attachment.contentID(), !content_id.isEmpty && attachment.inline() {
                self.htmlEditor.remove(embedImage: "cid:\(content_id)")
            }
            self.viewModel.deleteAtt(attachment)
        }
    }

    func attachments(_ attViewController: AttachmentsTableViewController, didReachedSizeLimitation: Int) {
    }

    func attachments(_ attViewController: AttachmentsTableViewController, error: String) {
    }
}

// MARK: - UIPickerViewDataSource
extension ComposeViewController: UIPickerViewDataSource {
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
extension ComposeViewController: UIPickerViewDelegate {
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
        self.headerView.updateExpirationValue(((Double(selectedDay) * 24) + Double(selectedHour)) * 3600, text: "\(day) \(hour)")
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return super.canPerformAction(action, withSender: sender)
    }

}


extension ComposeViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        self.htmlEditor.update(footer: 0.0)
    }
    
    func keyboardWillShowNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        let showed = abs(keyboardInfo.beginFrame.origin.y - keyboardInfo.endFrame.origin.y) < 50
        if !self.htmlEditor.responderCheck() && !showed {
            self.htmlEditor.update(footer: keyboardInfo.beginFrame.height)
        }
    }
}
