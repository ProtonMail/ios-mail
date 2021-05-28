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
#if !APP_EXTENSION
import SideMenuSwift
#endif
import ProtonCore_DataModel

class ComposeViewController : HorizontallyScrollableWebViewContainer, ViewModelProtocol, CoordinatedNew, AccessibleView, HtmlEditorBehaviourDelegate {
    typealias viewModelType = ComposeViewModel
    typealias coordinatorType = ComposeCoordinator
    
    ///
    var viewModel : ComposeViewModel! // view model
    private var coordinator: ComposeCoordinator?
    
    ///  UI
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
    private var dismissBySending = false
    
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
        self.dismiss(animated: true, completion: nil)
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(self.coordinator != nil)
        assert(self.viewModel != nil)
        
        self.prepareWebView()
        self.htmlEditor.delegate = self
        self.htmlEditor.setup(webView: self.webView)
        
        ///
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
        generateAccessibilityIdentifiers()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        #if !APP_EXTENSION
        let actionToFilter: [ComposeMessageAction] = [.reply, .replyAll]
        if !actionToFilter.contains(viewModel.messageAction) {
            _ = headerView.toContactPicker.becomeFirstResponder()
        }
        #endif
        
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
            let presentingVC = self.presentingViewController
            self.handleHintBanner(presentingVC: presentingVC)
        }
    }
    
    private func findPreviousVC(presentingVC: UIViewController?) -> UIViewController? {
        #if !APP_EXTENSION
        guard let messageID = self.viewModel.message?.messageID else {
            return nil
        }
        userCachedStatus.lastDraftMessageID = messageID
        
        guard let presentingVC = presentingVC as? SideMenuController else {
            return nil
        }
        let contentVC = presentingVC.contentViewController
        var navigationController: UINavigationController?
        
        if let contactTabbar = contentVC as? ContactTabBarViewController {
            navigationController = contactTabbar.selectedViewController as? UINavigationController
        } else {
            navigationController = contentVC as? UINavigationController
        }
        let topVC = navigationController?.topViewController as? ComposeSaveHintProtocol
        return topVC
        #else
        return nil
        #endif
    }
    
    private func removeHintBanner(presentingVC: UIViewController?) {
        #if !APP_EXTENSION
        guard let topVC = self.findPreviousVC(presentingVC: presentingVC) as? ComposeSaveHintProtocol else {
            return
        }
        topVC.removeDraftSaveHintBanner()
        #endif
    }
    
    private func handleHintBanner(presentingVC: UIViewController?) {
        #if !APP_EXTENSION
        guard let topVC = self.findPreviousVC(presentingVC: presentingVC) as? ComposeSaveHintProtocol,
              let viewModel = self.viewModel as? ComposeViewModelImpl else {
            return
        }
        let messageService = self.viewModel.getUser().messageService
        let coreDataService = viewModel.coreDataService
        if self.dismissBySending {
            if let listVC = topVC as? MailboxViewController {
                listVC.tableView.reloadData()
            }
            topVC.showMessageSendingHintBanner()
        } else {
            topVC.showDraftSaveHintBanner(cache: userCachedStatus,
                                          messageService: messageService,
                                          coreDataService: coreDataService)
        }
        #endif
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
            if origAddr.send == .inactive {
                self.viewModel.updateAddressID(addr.addressID).done {
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
        super.viewWillAppear(animated)
        self.removeHintBanner(presentingVC: self.presentingViewController)
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
        guard let viewCounts = self.navigationController?.viewControllers.count else {
            return
        }
        if viewCounts == 1 {
            // view dismiss
            self.handleDismissDraft()
        }
    }
    
    @objc internal func willResignActiveNotification (_ notify: Notification) {
        self.autoSaveTimer()
    }

    @IBAction func sendAction(_ sender: AnyObject) {
        self.dismissKeyboard()
        guard self.recipientsValidation() else { return }
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
    
    private func recipientsValidation() -> Bool {
        
        let showAlert: ((String) -> Void) = { message in
            let title = LocalString._warning
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addOKAction()
            self.present(alert, animated: true, completion: nil)
        }
        
        let contacts = self.headerView.toContactPicker.contactsSelected +
            self.headerView.ccContactPicker.contactsSelected +
            self.headerView.bccContactPicker.contactsSelected
        let recipients = contacts.compactMap { $0 as? ContactVO }
        
        let invalids = recipients.filter { $0.pgpType == .failed_server_validation }
        guard invalids.count == 0 else {
            let message = LocalString._address_invalid_warning_sending
            showAlert(message)
            return false
        }
        
        let nonExists = recipients.filter { $0.pgpType == .failed_non_exist }
        guard nonExists.count == 0 else {
            let message = LocalString._address_non_exist_warning
            showAlert(message)
            return false
        }
        
        let badGroups = contacts
            .compactMap { $0 as? ContactGroupVO }
            .filter { !$0.allMemberValidate }
        guard badGroups.count == 0 else {
            let message = LocalString._address_in_group_not_found_warning
            showAlert(message)
            return false
        }
        return true
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
        
        let allMails = self.viewModel.toSelectedContacts + self.viewModel.ccSelectedContacts + self.viewModel.bccSelectedContacts
        
        let invalidEmails = allMails
            .filter{ $0.modelType == .contact}
            .compactMap{ $0 as? ContactVO}
            .filter{ $0.pgpType == .failed_server_validation ||
                $0.pgpType == .failed_validation }
        guard invalidEmails.isEmpty else {
            let alert = UIAlertController(title: LocalString._address_invalid_error_title,
                                          message: LocalString._address_invalid_error_content,
                                          preferredStyle: .alert)
            alert.addAction((UIAlertAction.okAction()))
            present(alert, animated: true, completion: nil)
            return
        }
        
        stopAutoSave()
        self.collectDraftData().done {
            self.sendMessageStepThree()
        }
    }
    
    func sendMessageStepThree() {
        self.viewModel.sendMessage()

        self.dismissBySending = true
        #if APP_EXTENSION
        self.dismiss()
        #else
        self.dismiss(animated: true, completion: nil)
        #endif
    }
    
    func cancel() {
        // overriden in Share
    }
    
    func cancelAction(_ sender: UIBarButtonItem) {
        #if APP_EXTENSION
        self.handleDismissDraft()
        #else
        self.dismiss(animated: true, completion: nil)
        #endif
        
    }
    
    private func handleDismissDraft() {
        
        guard !self.dismissBySending else {
            self.dismiss()
            return
        }
        
        // Cancel handling
        let dismiss: (() -> Void) = {
            self.isShowingConfirm = false
            self.dismissKeyboard()
            self.cancel()
            self.dismiss()
        }
        
        guard self.viewModel.hasDraft ||
                self.headerView.hasContent ||
                (self.attachments?.count ?? 0) > 0 else {
            dismiss()
            return
        }
        
        self.stopAutoSave()
		//Remove the EO when we save the draft
        self.headerView.expirationTimeInterval = 0
        self.collectDraftData().done {
            self.viewModel.updateDraft()
        }.catch { _ in
            
        }.finally {
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
            self.htmlEditor.getHtml().done { bodyString in
                
                let head = "<html><head></head><body>"
                let foot = "</body></html>"
                
                let mutableString = NSMutableString(string: bodyString)
                CFStringTransform(mutableString, nil, "Any-Hex/Java" as NSString, true)
                let resultString = mutableString as String
                
                var body = resultString.isEmpty ? bodyString : resultString
                if !body.hasPrefix(head) {
                    body = head + body
                }
                
                if !body.hasSuffix(foot) {
                    body = body + foot
                }
                
                self.viewModel.collectDraft (
                    self.headerView.subject.text ?? "(No Subject)",
                    body: body,
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
                            self.viewModel.deleteAtt(att).cauterize()
                        }
                    }
                }
            }
        }
    }
    
    //MARK: - HtmlEditorBehaviourDelegate
    func addInlineAttachment(_ sid: String, data: Data) -> Promise<Void> {
        // Data.toAttachment will automatically increment number of attachments in the message
        let stripMetadata = userCachedStatus.metadataStripping == .stripMetadata
        
        return data.toAttachment(self.viewModel.message!, fileName: sid, type: "image/png", stripMetadata: stripMetadata).done { (attachment) in
            guard let att = attachment else {
                return
            }
            att.headerInfo = "{ \"content-disposition\": \"inline\", \"content-id\": \"\(sid)\" }"
            self.viewModel.uploadAtt(att)
        }
    }
    
    func removeInlineAttachment(_ sid: String) {
        // find attachment to remove
        guard let attachment = self.viewModel.getAttachments()?.first(where: { $0.fileName.hasPrefix(sid) }) else { return}
        
        // decrement number of attachments in message manually
        if let number = self.viewModel.message?.attachments.compactMap{ $0 as? Attachment }.filter({ !$0.isSoftDeleted }).count {
            let newNum = number > 0 ? number - 1 : 0
            self.viewModel.composerContext?.performAndWait {
                self.viewModel.message?.numAttachments = NSNumber(value: newNum)
                _ = self.viewModel.composerContext?.saveUpstreamIfNeeded()
            }
        }
        
        self.viewModel.deleteAtt(attachment).cauterize()
    }
    
    func htmlEditorDidFinishLoadingContent() {
        self.updateEmbedImages()
    }
    
    @objc func caretMovedTo(_ offset: CGPoint) {
        fatalError("should be overridden")
    }
}

// MARK: - Expiration unavaibility alert
extension ComposeViewController {
    func showExpirationUnavailabilityAlert(nonPMEmails: [String], pgpEmails: [String]) {
        var message = String()
        if nonPMEmails.count > 0 {
            message.append(LocalString._we_recommend_setting_up_a_password)
            message.append("\n\n")
            message.append(nonPMEmails.joined(separator: ","))
            message.append("\n")
        }
        if pgpEmails.count > 0 {
            if nonPMEmails.count > 0 { message.append("\n") }
            message.append(LocalString._we_recommend_setting_up_a_password_or_disabling_pgp)
            message.append("\n\n")
            message.append(pgpEmails.joined(separator: ","))
            message.append("\n")
        }
        let alertController = UIAlertController(title: LocalString._expiration_not_supported, message: message, preferredStyle: .alert)
        let sendAnywayAction = UIAlertAction(title: LocalString._send_anyway, style: .destructive) { [weak self] _ in
            self?.sendMessageStepTwo()
        }
        let cancelAction = UIAlertAction(title: LocalString._general_cancel_action, style: .cancel, handler: nil)
        alertController.addAction(sendAnywayAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}

//MARK: - view extensions
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
    
    func checkMails(in contactGroup: ContactGroupVO, progress: () -> Void, complete: LockCheckComplete?) {
        self.viewModel.checkMails(in: contactGroup, progress: progress, complete: complete)
    }
    
    @available(iOS 14.0, *)
    func setupComposeFromMenu(for button: UIButton) {
        var multi_domains = self.viewModel.getAddresses()
        multi_domains.sort(by: { $0.order < $1.order })
        let defaultAddr = self.viewModel.getDefaultSendAddress()
        var actions: [UIAction] = []
        for addr in multi_domains {
            guard addr.status == .enabled && addr.receive == .active else {
                continue
            }

            let state: UIMenuElement.State = defaultAddr == addr ? .on: .off
            let item = UIAction(title: addr.email, state: state) { (action) in
                guard action.state == .off else { return }
                if addr.send == .inactive {
                    let alertController = String(format: LocalString._composer_change_paid_plan_sender_error, addr.email).alertController()
                    alertController.addOKAction()
                    self.present(alertController, animated: true, completion: nil)
                } else {
                    if let signature = self.viewModel.getCurrrentSignature(addr.addressID) {
                        self.htmlEditor.update(signature: signature)
                    }
                    MBProgressHUD.showAdded(to: self.parent!.navigationController!.view, animated: true)
                    self.updateSenderMail(addr: addr)
                    self.setupComposeFromMenu(for: button)
                }
            }
            item.accessibilityLabel = addr.email
            actions.append(item)
        }
        let menu = UIMenu(title: "", options: .displayInline, children: actions)
        button.menu = menu
        button.showsMenuAsPrimaryAction = true
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
        var multi_domains = self.viewModel.getAddresses()
        multi_domains.sort(by: { $0.order < $1.order })
        let defaultAddr = self.viewModel.getDefaultSendAddress()
        for addr in multi_domains {
            guard addr.status == .enabled && addr.receive == .active else {
                continue
            }
            needsShow = true
            let selectEmail = UIAlertAction(title: addr.email, style: .default) { action in
                guard action.title != defaultAddr?.email else { return }
                if addr.send == .inactive {
                    let alertController = String(format: LocalString._composer_change_paid_plan_sender_error, addr.email).alertController()
                    alertController.addOKAction()
                    self.present(alertController, animated: true, completion: nil)
                } else {
                    if let signature = self.viewModel.getCurrrentSignature(addr.addressID) {
                        self.htmlEditor.update(signature: signature)
                    }
                    MBProgressHUD.showAdded(to: self.parent!.navigationController!.view, animated: true)
                    self.updateSenderMail(addr: addr)
                }
            }
            selectEmail.accessibilityLabel = selectEmail.title
            if defaultAddr == addr {
                selectEmail.setValue(true, forKey: "checked")
            }
            alertController.addAction(selectEmail)
            
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
        
        self.queue.sync {
            self.viewModel.updateAddressID(addr.addressID).catch { (error ) in
                let alertController = error.localizedDescription.alertController()
                alertController.addOKAction()
                self.present(alertController, animated: true, completion: nil)
            }.finally {
                self.headerView.updateFromValue(addr.email, pickerEnabled: true)
                MBProgressHUD.hide(for: self.parent!.navigationController!.view, animated: true)
            }
        }
    }
    
    func ComposeViewDidSizeChanged(_ size: CGSize, showPicker: Bool) {
        // FIXME
    }
    
    func ComposeViewDidOffsetChanged(_ offset: CGPoint) {
        // FIXME
    }
    
    func composeViewDidTapContactGroupSubSelection(_ composeView: ComposeHeaderViewController,
                                                   contactGroup: ContactGroupVO,
                                                   callback: @escaping (([DraftEmailData]) -> Void)) {
        self.pickedGroup = contactGroup
        self.pickedCallback = callback
        self.coordinator?.go(to: .subSelection)
    }

    func updateEO() {
        _ = self.viewModel.updateEO(expirationTime: self.headerView.expirationTimeInterval,
                                    pwd: self.encryptionPassword,
                                    pwdHint: self.encryptionPasswordHint).done { (_) in
                                        self.headerView.reloadPicker()
        }
    }

    func composeView(_ composeView: ComposeHeaderViewController, didAddContact contact: ContactPickerModelProtocol, toPicker picker: ContactPicker) {
        if (picker == self.headerView.toContactPicker) {
            self.viewModel.toSelectedContacts.append(contact)
        } else if (picker == headerView.ccContactPicker) {
            self.viewModel.ccSelectedContacts.append(contact)
        } else if (picker == headerView.bccContactPicker) {
            self.viewModel.bccSelectedContacts.append(contact)
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

// MARK: Attachment
extension ComposeViewController: ComposerAttachmentHandlerProtocol {
    func attachments(pickup attachment: Attachment) -> Promise<Void> {
        return Promise { seal in
            self.collectDraftData().done {
                attachment.managedObjectContext?.performAndWait {
                    attachment.message = self.viewModel.message!
                    _ = attachment.managedObjectContext?.saveUpstreamIfNeeded()
                }
                self.viewModel.uploadAtt(attachment)
                seal.fulfill_()
            }
        }
    }

    func attachments(deleted attachment: Attachment) -> Promise<Void> {
        return Promise { seal in
            self.collectDraftData().done {
                if let content_id = attachment.contentID(),
                   !content_id.isEmpty &&
                    attachment.inline() {
                    self.htmlEditor.remove(embedImage: "cid:\(content_id)")
                }
            }.then { (_) -> Promise<Void> in
                return self.viewModel.deleteAtt(attachment)
            }.ensure {
                // decrement number of attachments in message manually
                if let number = self.viewModel.message?.attachments.compactMap{ $0 as? Attachment }.filter({ !$0.isSoftDeleted }).count {
                    self.viewModel.composerContext?.performAndWait {
                        self.viewModel.message?.numAttachments = NSNumber(value: number)
                        _ = self.viewModel.composerContext?.saveUpstreamIfNeeded()
                    }
                }
                seal.fulfill_()
            }.cauterize()
        }
        
    }
}
