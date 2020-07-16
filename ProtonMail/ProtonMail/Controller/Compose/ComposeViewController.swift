//
//  ComposeViewController
//  ProtonMail - Created on 4/21/15.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import UIKit
import PromiseKit
import AwaitKit
import MBProgressHUD

class ComposeViewController : HorizontallyScrollableWebViewContainer, ViewModelProtocol, CoordinatedNew {
    typealias viewModelType = ComposeViewModel
    typealias coordinatorType = ComposeCoordinator
    
    ///
    var viewModel : ComposeViewModel! // view model
    private var coordinator: ComposeCoordinator?
    
    ///  UI
    private weak var expirationPicker: UIPickerView?
    weak var headerView: ComposeHeaderViewController!
    lazy var htmlEditor = HtmlEditorBehaviour()
    
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

    /// const values
    private let kNumberOfColumnsInTimePicker: Int = 2
    private let kNumberOfDaysInTimePicker: Int    = 30
    private let kNumberOfHoursInTimePicker: Int   = 24
    
    private let queue = DispatchQueue(label: "UpdateAddressIdQueue")
    
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
        self.htmlEditor.eject()
    }
    
    internal func injectHeader(_ header: ComposeHeaderViewController) {
        self.headerView = header
        self.headerView.delegate = self
        self.headerView.datasource = self
    }
    
    internal func injectExpirationPicker(_ picker: UIPickerView) {
        self.expirationPicker = picker
        picker.dataSource = self
        picker.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(self.coordinator != nil)
        assert(self.viewModel != nil)
        
        self.prepareWebView()
        self.htmlEditor.delegate = self
        self.htmlEditor.setup(webView: self.webView)
        
        ///
        self.automaticallyAdjustsScrollViewInsets = false
        self.extendedLayoutIncludesOpaqueBars = true
        
        //  update header view data
        self.updateMessageView()
        
        // load all contacts and groups
        // TODO: move to view model
        firstly { () -> Promise<Void> in
//            self.contacts = contactService.allContactVOs() // contacts in core data
            return retrieveAllContacts() // contacts in phone book
        }.done { [weak self] in
            guard let self = self else { return }
            // get contact groups

            // TODO: figure where to put this thing
            let user = self.viewModel.getUser()
            if user.isPaid {
                self.contacts.append(contentsOf: user.contactGroupService.getAllContactGroupVOs())
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
            
            self.headerView?.toContactPicker?.reloadData()
            self.headerView?.ccContactPicker?.reloadData()
            self.headerView?.bccContactPicker?.reloadData()
            
            self.headerView?.toContactPicker?.contactCollectionView?.layoutIfNeeded()
            self.headerView?.bccContactPicker?.contactCollectionView?.layoutIfNeeded()
            self.headerView?.ccContactPicker?.contactCollectionView?.layoutIfNeeded()
            
            switch self.viewModel.messageAction
            {
            case .openDraft, .reply, .replyAll:
                if !self.isShowingConfirm {
                    //TODO:: remove the focus for now revert later
                    //self.focus()
                }
                self.headerView?.notifyViewSize(true)
            case .forward:
                if !self.isShowingConfirm {
                    let _ = self.headerView?.toContactPicker.becomeFirstResponder()
                }
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

        self.attachments = viewModel.getAttachments()

        /// change message as read
        self.viewModel.markAsRead()
    }

    private func retrieveAllContacts() -> Promise<Void> {
        return Promise { seal in
            let service = self.viewModel.getUser().contactService
            service.getContactVOs { (contacts, error) in
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
                    viewModel.getUser().messageService.base64AttachmentData(att: att) { (based64String) in
                        if !based64String.isEmpty {
                            self.htmlEditor.update(embedImage: "cid:\(content_id)", encoded: "data:\(att.mimeType);base64,\(based64String)")
                        }
                    }
                }
            }
        }
    }

    @objc internal func dismiss() {
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
        
        if viewModel.getActionType() != .openDraft {
            self.viewModel.collectDraft (
                self.viewModel.getSubject(),
                body: body.body,
                expir: self.headerView.expirationTimeInterval,
                pwd:self.encryptionPassword,
                pwdHit:self.encryptionPasswordHint
            )
            
            self.viewModel.uploadMimeAttachments()
        }

        guard let addr = self.viewModel.getDefaultSendAddress() else {
            return
        }
        
        var isFromValid = true
        self.headerView.updateFromValue(addr.email, pickerEnabled: true)
        if let origAddr = self.viewModel.fromAddress() {
            if origAddr.send == 0 {
                self.viewModel.updateAddressID(addr.address_id).done {
                    //
                }.catch({ (_) in
                    if self.viewModel.getActionType() != .openDraft {
                        self.viewModel.updateDraft()
                    }
                })
                isFromValid = false
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
        // update draft if first time create
        if viewModel.getActionType() != .openDraft && isFromValid {
            self.viewModel.updateDraft()
        }
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        stopAutoSave()
    }
    
    @objc internal func willResignActiveNotification (_ notify: Notification) {
        self.autoSaveTimer()
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
            if #available(iOS 11.0, *) {
                self.sendMessageStepThree()
            } else {
                delay(0.5) {
                    self.sendMessageStepThree()
                }
            }
        }
    }
    
    func sendMessageStepThree() {
        self.viewModel.sendMessage()

        delay(0.5) {
            NSError.alertMessageSendingToast()
        }
        
        self.dismiss()
    }
    
    func cancel() {
        // overriden in Share
    }
    
    func cancelAction(_ sender: UIBarButtonItem) {
        let dismiss: (() -> Void) = {
            self.isShowingConfirm = false
            self.dismissKeyboard()
            self.cancel()
            self.dismiss()
        }
        
        if self.viewModel.hasDraft || self.headerView.hasContent || ((attachments?.count ?? 0) > 0) {
            self.isShowingConfirm = true
            let alertController = UIAlertController(title: LocalString._general_confirmation_title,
                                                    message: nil,
                                                    preferredStyle: .actionSheet)
            let save = UIAlertAction(title: LocalString._composer_save_draft_action,
                                     style: .default) { _ in
                self.stopAutoSave()
                self.collectDraftData().done {
                    self.viewModel.updateDraft()
                }.catch { _ in
                    
                }.finally {
                    dismiss()
                }
            }
            let cancel = UIAlertAction(title: LocalString._general_cancel_button,
                                       style: .cancel) { _ in
                self.isShowingConfirm = false
            }
            let delete = UIAlertAction(title: LocalString._composer_discard_draft_action,
                                       style: .destructive) { _ in
                self.stopAutoSave()
                self.viewModel.deleteDraft()
                dismiss()
            }
            
            // for UITests
            save.accessibilityLabel = "saveDraftButton"
            cancel.accessibilityLabel = "cancelDraftButton"
            delete.accessibilityLabel = "deleteDraftButton"
            
            [save, delete, cancel].forEach(alertController.addAction)
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
        let count = attachments?.count ?? 0
        if count > 0 {
            self.headerView.updateAttachmentButton(true)
        } else {
            self.headerView.updateAttachmentButton(false)
        }
    }
}
extension ComposeViewController: HtmlEditorBehaviourDelegate {
    @objc func addInlineAttachment(_ sid: String, data: Data) {
        // Data.toAttachment will automatically increment number of attachments in the message
        let stripMetadata = userCachedStatus.metadataStripping == .stripMetadata
        guard let attachment = data.toAttachment(self.viewModel.message!, fileName: sid, type: "image/png", stripMetadata: stripMetadata) else { return }
        attachment.headerInfo = "{ \"content-disposition\": \"inline\", \"content-id\": \"\(sid)\" }"
        self.viewModel.uploadAtt(attachment)
    }
    
    func removeInlineAttachment(_ sid: String) {
        // find attachment to remove
        guard let attachment = self.viewModel.getAttachments()?.first(where: { $0.fileName.hasPrefix(sid) }) else { return}
        
        // decrement number of attachments in message manually
        if let number = self.viewModel.message?.attachments.count {
            let newNum = number > 0 ? number - 1 : 0
            self.viewModel.message?.numAttachments = NSNumber(value: newNum)
        }
        
        self.viewModel.deleteAtt(attachment)
    }
    
    func htmlEditorDidFinishLoadingContent() {
        self.updateEmbedImages()
    }
    
    @objc func caretMovedTo(_ offset: CGPoint) {
        fatalError("should be overridden")
    }
}


// MARK : - view extensions
extension ComposeViewController : ComposeViewDelegate {
    
    func composeViewWillPresentSubview() {
        // FIXME
    }
    func composeViewWillDismissSubview() {
        // FIXME
    }
    
    func lockerCheck(model: ContactPickerModelProtocol, progress: () -> Void, complete: LockCheckComplete?) {
        self.viewModel.lockerCheck(model: model, progress: progress, complete: complete)
    }
    
    func composeViewPickFrom(_ composeView: ComposeHeaderViewController) {
        var needsShow : Bool = false
        let alertController = UIAlertController(title: LocalString._composer_change_sender_address_to,
                                                message: nil,
                                                preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: LocalString._general_cancel_button,
                                   style: .cancel,
                                   handler: nil)
        cancel.accessibilityLabel = "cancelButton"
        alertController.addAction(cancel)
        let multi_domains = self.viewModel.getAddresses()
        let defaultAddr = self.viewModel.getDefaultSendAddress()
        for addr in multi_domains {
            if addr.status == 1 && addr.receive == 1 && defaultAddr != addr {
                needsShow = true
                let selectEmail = UIAlertAction(title: addr.email, style: .default) { _ in
                    if addr.send == 0 {
                        let alertController = String(format: LocalString._composer_change_paid_plan_sender_error, addr.email).alertController()
                        alertController.addOKAction()
                        self.present(alertController, animated: true, completion: nil)
                    } else {
                        if let signature = self.viewModel.getCurrrentSignature(addr.address_id) {
                            self.htmlEditor.update(signature: signature)
                        }
                        MBProgressHUD.showAdded(to: self.view, animated: true)
                        self.updateSenderMail(addr: addr)
                    }
                }
                selectEmail.accessibilityLabel = selectEmail.title
                alertController.addAction(selectEmail)
            }
        }
        if needsShow {
            alertController.popoverPresentationController?.sourceView = self.headerView.fromView
            alertController.popoverPresentationController?.sourceRect = self.headerView.fromView.frame
            present(alertController, animated: true, completion: nil)
        }
    }
    
    private func updateSenderMail(addr: Address) {
        let atts = self.viewModel.getAttachments() ?? []
        for att in atts {
            if att.keyPacket == nil || att.keyPacket == "" {
                Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self](_) in
                    guard let _self = self else {return}
                    _self.updateSenderMail(addr: addr)
                }
                return
            }
        }
        
        _ = self.queue.sync {
            self.viewModel.updateAddressID(addr.address_id).catch { (error ) in
                {
                    let alertController = error.localizedDescription.alertController()
                    alertController.addOKAction()
                    self.present(alertController, animated: true, completion: nil)
                } ~> .main
            }
        }
        
        self.headerView.updateFromValue(addr.email, pickerEnabled: true)
        MBProgressHUD.hide(for: self.view, animated: true)
    }
    
    func ComposeViewDidSizeChanged(_ size: CGSize, showPicker: Bool) {
        // FIXME
    }
    
    func ComposeViewDidOffsetChanged(_ offset: CGPoint) {
        // FIXME
    }
    
    func composeViewDidTapNextButton(_ composeView: ComposeHeaderViewController) {
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

    func composeViewDidTapEncryptedButton(_ composeView: ComposeHeaderViewController) {
        self.coordinator?.go(to: .password)
    }
    
    func composeViewDidTapContactGroupSubSelection(_ composeView: ComposeHeaderViewController,
                                                   contactGroup: ContactGroupVO,
                                                   callback: @escaping (([DraftEmailData]) -> Void)) {
        self.pickedGroup = contactGroup
        self.pickedCallback = callback
        self.coordinator?.go(to: .subSelection)
    }

    func composeViewDidTapAttachmentButton(_ composeView: ComposeHeaderViewController) {
        //TODO:: change this to segue
        self.autoSaveTimer()
        self.coordinator?.go(to: .attachment)
    }

    @objc func composeViewDidTapExpirationButton(_ composeView: ComposeHeaderViewController) {
        (self.viewModel as? ContainableComposeViewModel)?.showExpirationPicker = true
    }

    @objc func composeViewHideExpirationView(_ composeView: ComposeHeaderViewController) {
        (self.viewModel as? ContainableComposeViewModel)?.showExpirationPicker = false
    }

    func composeViewCancelExpirationData(_ composeView: ComposeHeaderViewController) {
        self.expirationPicker?.selectRow(0, inComponent: 0, animated: true)
        self.expirationPicker?.selectRow(0, inComponent: 1, animated: true)
    }

    func composeViewCollectExpirationData(_ composeView: ComposeHeaderViewController) {
        guard let selectedDay = expirationPicker?.selectedRow(inComponent: 0),
            let selectedHour = expirationPicker?.selectedRow(inComponent: 1) else
        {
            assert(false, "Expiration picker does not exist")
            return
        }
        if self.headerView.setExpirationValue(selectedDay, hour: selectedHour) {
            (self.viewModel as? ContainableComposeViewModel)?.showExpirationPicker = false
        }
        self.updateEO()
    }

    func updateEO() {
        self.viewModel.updateEO(expir: self.headerView.expirationTimeInterval,
                                pwd: self.encryptionPassword,
                                pwdHit: self.encryptionPasswordHint)
        self.headerView.reloadPicker()
    }

    func composeView(_ composeView: ComposeHeaderViewController, didAddContact contact: ContactPickerModelProtocol, toPicker picker: ContactPicker) {
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

    func composeView(_ composeView: ComposeHeaderViewController, didRemoveContact contact: ContactPickerModelProtocol, fromPicker picker: ContactPicker) {
        // here each logic most same, need refactor later
        if (picker == self.headerView.toContactPicker) {
            var contactIndex = -1
            let selectedContacts = self.viewModel.toSelectedContacts
            for (index, selectedContact) in selectedContacts.enumerated() {
                if let contact = contact as? ContactVO {
                    if (contact.displayEmail == selectedContact.displayEmail) {
                        contactIndex = index
                    }
                } else if let _ = contact as? ContactGroupVO {
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

    func composeViewContactsModelForPicker(_ composeView: ComposeHeaderViewController, picker: ContactPicker) -> [ContactPickerModelProtocol] {
        return contacts
    }
    
    func ccBccIsShownInitially() -> Bool {
        return !self.viewModel.ccSelectedContacts.isEmpty || !self.viewModel.bccSelectedContacts.isEmpty
    }

    func composeViewSelectedContactsForPicker(_ composeView: ComposeHeaderViewController, picker: ContactPicker) ->  [ContactPickerModelProtocol] {
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
        
        if #available(iOS 11.0, *) {
            self.collectDraftData().done { // this will trigger WebCore to use more memrory iphone 5 devices could case a crashing
                self.viewModel.uploadAtt(attachment)
            }
        } else {
            self.viewModel.uploadAtt(attachment)
        }
    }

    func attachments(_ attViewController: AttachmentsTableViewController, didDeletedAttachment attachment: Attachment) {
        self.collectDraftData().done {
            if let content_id = attachment.contentID(), !content_id.isEmpty && attachment.inline() {
                self.htmlEditor.remove(embedImage: "cid:\(content_id)")
            }
            
            // decrement number of attachments in message manually
            if let number = self.viewModel.message?.attachments.count {
                let newNum = number > 0 ? number - 1 : 0
                self.viewModel.message?.numAttachments = NSNumber(value: newNum)
            }
            
            self.viewModel.deleteAtt(attachment)
            attViewController.updateAttachments()
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
