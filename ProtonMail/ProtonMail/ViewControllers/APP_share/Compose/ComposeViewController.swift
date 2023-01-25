//
//  ComposeViewController
//  Proton Mail - Created on 4/21/15.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonMailAnalytics
import UIKit
import PromiseKit
import MBProgressHUD
#if !APP_EXTENSION
import SideMenuSwift
#endif
import ProtonCore_DataModel
import ProtonCore_Foundations

class ComposeViewController: HorizontallyScrollableWebViewContainer, AccessibleView, HtmlEditorBehaviourDelegate {
    let viewModel: ComposeViewModel
    var openScheduleSendActionSheet: (() -> Void)?
    var navigateTo: ((ComposeCoordinator.Destination) -> Void)?

    weak var headerView: ComposeHeaderViewController!
    lazy var htmlEditor = HtmlEditorBehaviour()

    private var timer: Timer? // auto save timer

    private var contacts: [ContactPickerModelProtocol] = []
    private var phoneContacts: [ContactPickerModelProtocol] = []

    var encryptionPassword: String        = ""
    var encryptionConfirmPassword: String = ""
    var encryptionPasswordHint: String    = ""
    private var dismissBySending = false

    private let queue = DispatchQueue(label: "UpdateAddressIdQueue")

    var pickedGroup: ContactGroupVO?
    var pickedCallback: (([DraftEmailData]) -> Void)?
    var groupSubSelectionPresenter: ContactGroupSubSelectionActionSheetPresenter?

    init(viewModel: ComposeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


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

        self.prepareWebView()
        self.htmlEditor.delegate = self
        self.webView.isOpaque = false
        self.htmlEditor.setup(webView: self.webView)

        self.viewModel.showError = { [weak self] errorMsg in
            guard let self = self else { return }
            errorMsg.alertToast(view: self.view)
        }

        self.extendedLayoutIncludesOpaqueBars = true

        //  update header view data
        self.updateMessageView()

        // load all contacts and groups
        // TODO: move to view model
        firstly { () -> Promise<Void> in
            return retrievePMContacts()
        }.then({ [weak self] _ in
            return self?.retrievePhoneContacts() ?? Promise<Void>()
        }).done { [weak self] in
            guard let self = self else { return }

            let user = self.viewModel.getUser()

            var contactsWithoutLastTimeUsed: [ContactPickerModelProtocol] = self.phoneContacts

            if user.hasPaidMailPlan {
                let contactGroupsToAdd = user.contactGroupService.getAllContactGroupVOs().filter { $0.contactCount > 0 }
                contactsWithoutLastTimeUsed.append(contentsOf: contactGroupsToAdd)
            }
            // sort the contact group and phone address together
            contactsWithoutLastTimeUsed.sort(by: { $0.contactTitle.lowercased() < $1.contactTitle.lowercased() })

            self.contacts = self.contacts + contactsWithoutLastTimeUsed

            self.headerView?.toContactPicker?.reloadData()
            self.headerView?.ccContactPicker?.reloadData()
            self.headerView?.bccContactPicker?.reloadData()

            self.headerView?.toContactPicker?.contactCollectionView?.layoutIfNeeded()
            self.headerView?.bccContactPicker?.contactCollectionView?.layoutIfNeeded()
            self.headerView?.ccContactPicker?.contactCollectionView?.layoutIfNeeded()

            delay(0.5) {
                // There is a height observer in ComposeContainerViewController
                // If the tableview reload, the keyboard will be dismissed
                switch self.viewModel.messageAction {
                case .openDraft, .reply, .replyAll:
                    self.headerView?.notifyViewSize(true)
                case .forward:
                    _ = self.headerView?.toContactPicker.becomeFirstResponder()
                default:
                    _ = self.headerView?.toContactPicker.becomeFirstResponder()
                }
            }

        }.catch { _ in
        }

        /// change message as read
        self.viewModel.markAsRead()
        generateAccessibilityIdentifiers()
    }

    private func retrievePMContacts() -> Promise<Void> {
        return Promise { seal in
            let service = self.viewModel.getUser().contactService
            service.getContactVOs { (contacts, _) in
                self.contacts = contacts
                seal.fulfill(())
            }
        }
    }

    private func retrievePhoneContacts() -> Promise<Void> {
        return Promise { seal in
            let service = self.viewModel.getUser().contactService
            service.getContactVOsFromPhone { phoneContacts, _ in
                self.phoneContacts = phoneContacts
                seal.fulfill(())
            }
        }
    }

    @objc func dismiss() {
        if self.presentingViewController != nil {
            let presentingVC = self.presentingViewController
            self.handleHintBanner(presentingVC: presentingVC)
        }
        self.dismiss(animated: true, completion: nil)
    }

    private func findPreviousVC(presentingVC: UIViewController?) -> UIViewController? {
        #if !APP_EXTENSION
        guard let messageID = self.viewModel.composerMessageHelper.messageID else {
            return nil
        }
        userCachedStatus.lastDraftMessageID = messageID.rawValue

        var contentVC: UIViewController?
        var navigationController: UINavigationController?

        if let presentingVC = presentingVC as? SideMenuController {
            contentVC = presentingVC.contentViewController
        } else if let presentingVC = presentingVC as? UINavigationController {
            navigationController = presentingVC
        }

        if let contactTabbar = contentVC as? ContactTabBarViewController {
            navigationController = contactTabbar.selectedViewController as? UINavigationController
        } else if let navController = contentVC as? UINavigationController {
            navigationController = navController
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
        let coreDataContextProvider = viewModel.coreDataContextProvider
        if self.dismissBySending {
            if let listVC = topVC as? MailboxViewController {
                listVC.tableView.reloadData()
            }
            let messageID = self.viewModel.composerMessageHelper.message?.messageID ?? .empty
            if viewModel.deliveryTime != nil {
                topVC.showMessageSchedulingHintBanner(messageID: messageID)
            } else {
                topVC.showMessageSendingHintBanner(messageID: messageID, messageDataService: messageService)
            }
        } else {
            if self.viewModel.isEmptyDraft() { return }
            topVC.showDraftSaveHintBanner(cache: userCachedStatus,
                                          messageService: messageService,
                                          coreDataContextProvider: coreDataContextProvider)
        }
        #endif
    }

    private func dismissKeyboard() {
        self.headerView?.subject.becomeFirstResponder()
        self.headerView?.subject.resignFirstResponder()
    }

    private func updateMessageView() {
        self.headerView.subject.text = self.viewModel.getSubject()
        let body = self.viewModel.getHtmlBody()
        self.htmlEditor.setHtml(body: body)

        if viewModel.getActionType() != .openDraft {
            self.viewModel.collectDraft(
                self.viewModel.getSubject(),
                body: body.body,
                expir: self.headerView.expirationTimeInterval,
                pwd: self.encryptionPassword,
                pwdHit: self.encryptionPasswordHint
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
                                               object: nil)
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

    func sendAction(deliveryTime: Date?) {
        viewModel.deliveryTime = deliveryTime
        sendAction(self)
    }

    @IBAction func sendAction(_ sender: AnyObject) {
        self.dismissKeyboard()
        self.sendMessage()
    }

    private func composerRecipientsValidation() -> Bool {

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

        let invalidRecipients = recipients.filter { $0.encryptionIconStatus?.isInvalid == true &&
            $0.encryptionIconStatus?.nonExisting == false }
        guard invalidRecipients.count == 0 else {
            let message = LocalString._address_invalid_warning_sending
            showAlert(message)
            return false
        }

        let nonExistingRecipients = recipients.filter { $0.encryptionIconStatus?.nonExisting == true }
        guard nonExistingRecipients.count == 0 else {
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

    private func sendMessage() {
        delay(0.3) { [weak self] in
            self?.stopAutoSave()
            if self?.viewModel.deliveryTime == nil {
                self?.validateDraftBeforeSending()
            } else {
                self?.startSendingMessage()
            }
        }
    }

    func validateDraftBeforeSending() {
        if self.headerView.expirationTimeInterval > 0 {
            if viewModel.shouldShowExpirationWarning(havingPGPPinned: headerView.hasPGPPinned,
                                                     isPasswordSet: !encryptionPassword.isEmpty,
                                                     havingNonPMEmail: headerView.hasNonePMEmails) {
                navigateTo?(.expirationWarning)
                return
            }
        }
        displayDraftNotValidAlertIfNeeded() { [weak self] in
            self?.startSendingMessage()
        }
    }

    func startSendingMessage() {
        self.viewModel.sendMessage(deliveryTime: viewModel.deliveryTime)

        self.dismissBySending = true
        self.dismiss()
    }

    func cancel() {
        // overriden in Share
    }

    func cancelAction() {
        self.handleDismissDraft()
    }

    private func handleDismissDraft() {

        guard !self.dismissBySending else {
            self.dismiss()
            return
        }

        // Cancel handling
        let dismiss: (() -> Void) = {
            self.dismissKeyboard()
            self.cancel()
            self.dismiss()
        }

        self.stopAutoSave()
		// Remove the EO when we save the draft
        self.headerView.expirationTimeInterval = 0
        self.collectDraftData().done { [weak self] _ in
            guard let self = self else { return }
            if self.viewModel.isEmptyDraft() {
                return self.viewModel.deleteDraft()
            } else {
                return self.viewModel.updateDraft()
            }
        }.catch { _ in
        }.finally {
            dismiss()
        }
    }

    // MARK: - Private methods
    private func setupAutoSave() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
            self?.autoSaveTimer()
        }
    }

    private func stopAutoSave() {
        if let t = self.timer {
            t.invalidate()
            self.timer = nil
        }
    }

    @objc func autoSaveTimer() {
        _ = self.updateCIDs().then { [weak self] () -> Promise<(String, String)?> in
            guard let self = self else {
                return Promise.value(nil)
            }
            return self.collectDraftData()
        }.done { [weak self] _ in
            self?.viewModel.updateDraft()
        }
    }

    private func updateCIDs() -> Promise<Void> {
        return Promise { seal in
            let orignalPromise = self.htmlEditor.getOrignalCIDs()
            let editedPromise  = self.htmlEditor.getEditedCIDs()
            when(fulfilled: orignalPromise, editedPromise).done { (orignal, edited) in
                self.checkEmbedImageEdit(orignal, edited: edited)
            }.catch { (_) in
                //
            }.finally {
                seal.fulfill_()
            }
        }
    }

    func collectDraftData() -> Promise<(String, String)?> {
        return Promise { [weak self] seal in
            guard let self = self else {
                seal.fulfill(nil)
                return
            }
            self.htmlEditor.getHtml().done { [weak self] bodyString in
                guard let self = self else {
                    return
                }

                guard let headerView = self.headerView else {
                    assertionFailure("headerView not ready")
                    seal.fulfill(nil)
                    return
                }

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
                let subject = headerView.subject.text ?? "(No Subject)"
                self.viewModel.collectDraft(
                    subject,
                    body: body,
                    expir: headerView.expirationTimeInterval,
                    pwd: self.encryptionPassword,
                    pwdHit: self.encryptionPasswordHint
                )
                seal.fulfill((subject, body))
            }.catch { _ in
                // handle the errors
            }.finally {
                seal.fulfill(nil)
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

    // MARK: - HtmlEditorBehaviourDelegate
    func addInlineAttachment(_ sid: String, data: Data, completion: (() -> Void)?) {
        // Data.toAttachment will automatically increment number of attachments in the message
        let stripMetadata = userCachedStatus.metadataStripping == .stripMetadata
        viewModel.composerMessageHelper.addAttachment(data: data, fileName: sid, shouldStripMetaData: stripMetadata, isInline: true) { attachment in
            guard let att = attachment else {
                completion?()
                return
            }
            self.viewModel.uploadAtt(att)
            completion?()
        }
    }

    func removeInlineAttachment(_ sid: String, completion: (() -> Void)?) {
        // find attachment to remove
        guard let attachment = self.viewModel.getAttachments()?.first(where: { $0.fileName.hasPrefix(sid) }) else {
            completion?()
            return
        }

        let realAttachments = userCachedStatus.realAttachments
        viewModel.composerMessageHelper.removeInlineAttachment(fileName: sid,
                                                               isRealAttachment: realAttachments) { [weak self] in
            self?.viewModel.updateDraft()
        }

        self.viewModel.deleteAtt(attachment).done {
            completion?()
        }.cauterize()
    }

    func htmlEditorDidFinishLoadingContent() {
        viewModel.embedInlineAttachments(in: htmlEditor)
    }

    @objc func caretMovedTo(_ offset: CGPoint) {
        fatalError("should be overridden")
    }
}

// MARK: - Methods about draft validation
extension ComposeViewController {
    func displayDraftNotValidAlertIfNeeded(
        isTriggeredFromScheduleButton: Bool = false,
        continueAction: @escaping () -> Void
    ) {
        isUserInputValidInTheHeaderViewOfComposer { [weak self] in
            _ = self?.collectDraftData().done { result in
                guard let result = result else { return }

                self?.showRecipientEmptyAlertIfNeeded {
                    self?.showInvalidAddressAlertIfNeeded {
                        self?.showAttachmentRemindAlertIfNeeded(
                            subject: result.0,
                            body: result.1
                        ) {
                            self?.showScheduleSendConfirmationAlertIfNeeded(
                                isTriggeredFromScheduleButton: isTriggeredFromScheduleButton
                            ) {
                                continueAction()
                            }
                        }
                    }
                }
            }
        }
    }

    private func isUserInputValidInTheHeaderViewOfComposer(continueAction: @escaping () -> Void) {
        guard composerRecipientsValidation() else { return }
        showSubjectAlertIfNeeded(continueAction: continueAction)
    }

    private func showInvalidAddressAlertIfNeeded(continueAction: @escaping () -> Void) {
        guard viewModel.doesInvalidAddressExist() else {
            continueAction()
            return
        }
        let alert = UIAlertController(
            title: LocalString._address_invalid_error_title,
            message: LocalString._address_invalid_error_content,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction.okAction())
        present(alert, animated: true, completion: nil)
    }

    private func showRecipientEmptyAlertIfNeeded(continueAction: @escaping () -> Void) {
        if viewModel.isDraftHavingEmptyRecipient() {
            let alert = UIAlertController(title: LocalString._general_alert_title,
                                          message: LocalString._composer_no_recipient_error,
                                          preferredStyle: .alert)
            alert.addAction((UIAlertAction.okAction()))
            present(alert, animated: true, completion: nil)
            return
        } else {
            continueAction()
        }
    }

    private func showAttachRemindAlert(continueAction: @escaping () -> Void) {
        let title = LocalString._no_attachment_found
        let message = LocalString._do_you_want_to_send_message_anyway
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancel = UIAlertAction(
            title: LocalString._general_cancel_action,
            style: .cancel,
            handler: nil)
        let send = UIAlertAction(title: LocalString._send_anyway, style: .destructive) { _ in
            continueAction()
        }
        [cancel, send].forEach(alert.addAction)
        self.present(alert, animated: true, completion: nil)
    }

    private func showScheduleSendConfirmationAlert(continueAction: @escaping () -> Void) {
        let alertController = UIAlertController(title: LocalString._composer_send_msg_which_was_schedule_send_title,
                                                message: LocalString._composer_send_msg_which_was_schedule_send_message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: LocalString._composer_send_msg_which_was_schedule_send_action_title,
                                                style: .destructive, handler: { _ -> Void in
            continueAction()
        }))
        alertController.addAction(UIAlertAction(title: LocalString._general_schedule_send_action,
                                                style: .default,
                                                handler: { [weak self] _ in
            self?.openScheduleSendActionSheet?()
        }))
        self.present(alertController, animated: true, completion: nil)
    }

    private func showScheduleSendConfirmationAlertIfNeeded(isTriggeredFromScheduleButton: Bool, continueAction: @escaping () -> Void) {
        if viewModel.shouldShowScheduleSendConfirmationAlert() && !isTriggeredFromScheduleButton {
            showScheduleSendConfirmationAlert {
                continueAction()
            }
        } else {
            continueAction()
        }
    }

    private func showAttachmentRemindAlertIfNeeded(
        subject: String,
        body: String,
        continueAction: @escaping () -> Void
    ) {
        if self.viewModel.needAttachRemindAlert(
            subject: subject,
            body: body
        ) {
            self.showAttachRemindAlert(continueAction: continueAction)
        } else {
            continueAction()
        }
    }

    private func showSubjectAlertIfNeeded(continueAction: @escaping () -> Void) {
        guard let subject = headerView.subject.text, subject.isEmpty else {
            continueAction()
            return
        }
        let alertController = UIAlertController(title: LocalString._composer_compose_action,
                                                message: LocalString._composer_send_no_subject_desc,
                                                preferredStyle: .alert)
        alertController.addAction(
            UIAlertAction(title: LocalString._general_send_action,
                          style: .destructive,
                          handler: { _ in
                              continueAction()
                          })
        )
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Expiration unavailability alert
extension ComposeViewController {
    func showExpirationUnavailabilityAlert(nonPMEmails: [String], pgpEmails: [String]) {
        var message = String()
        if nonPMEmails.count > 0 {
            message.append(LocalString._we_recommend_setting_up_a_password)
            message.append("\n\n")
            if nonPMEmails.count > 5 {
                message.append(nonPMEmails[...3].joined(separator: "\n"))
                let extraStr = String.init(format: LocalString._extra_addresses,
                                           nonPMEmails.count - 4)
                message.append("\n\(extraStr)")
            } else {
                message.append(nonPMEmails.joined(separator: "\n"))
            }
            message.append("\n")
        }
        if pgpEmails.count > 0 {
            if nonPMEmails.count > 0 { message.append("\n") }
            message.append(LocalString._we_recommend_setting_up_a_password_or_disabling_pgp)
            message.append("\n\n")
            if pgpEmails.count > 5 {
                message.append(pgpEmails[...3].joined(separator: "\n"))
                let extraStr = String.init(format: LocalString._extra_addresses,
                                           pgpEmails.count - 4)
                message.append("\n\(extraStr)")
            } else {
                message.append(pgpEmails.joined(separator: "\n"))
            }
            message.append("\n")
        }
        let alertController = UIAlertController(title: LocalString._expiration_not_supported, message: message, preferredStyle: .alert)
        let sendAnywayAction = UIAlertAction(title: LocalString._send_anyway, style: .destructive) { [weak self] _ in
            self?.startSendingMessage()
        }
        let cancelAction = UIAlertAction(title: LocalString._general_cancel_action, style: .default, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(sendAnywayAction)
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - view extensions
extension ComposeViewController: ComposeViewDelegate {

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
        let defaultAddr = self.viewModel.fromAddress() ?? self.viewModel.getDefaultSendAddress()
        var actions: [UIAction] = []
        for addr in multi_domains {
            guard addr.status == .enabled && addr.receive == .active else {
                continue
            }

            let state: UIMenuElement.State = defaultAddr == addr ? .on: .off
            let item = UIAction(title: addr.email, state: state) { [weak self] action in
                guard action.state == .off, let self = self else { return }
                if addr.send == .inactive {
                    let alertController = String(format: LocalString._composer_change_paid_plan_sender_error, addr.email).alertController()
                    alertController.addOKAction()
                    self.present(alertController, animated: true, completion: nil)
                } else {
                    if let signature = self.viewModel.getCurrrentSignature(addr.addressID) {
                        self.htmlEditor.update(signature: signature)
                    }
                    MBProgressHUD.showAdded(to: self.parent!.navigationController!.view, animated: true)
                    self.updateSenderMail(addr: addr) { [weak self] in
                        self?.setupComposeFromMenu(for: button)
                    }
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
        var needsShow: Bool = false
        let alertController = UIAlertController(title: LocalString._composer_change_sender_address_to,
                                                message: nil,
                                                preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: LocalString._general_cancel_button,
                                   style: .cancel,
                                   handler: nil)
        cancel.accessibilityLabel = "ComposeContainerViewController.cancelButton"
        alertController.addAction(cancel)
        var multi_domains = self.viewModel.getAddresses()
        multi_domains.sort(by: { $0.order < $1.order })
        let defaultAddr = self.viewModel.fromAddress() ?? self.viewModel.getDefaultSendAddress()
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
                    self.updateSenderMail(addr: addr, complete: nil)
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

    private func updateSenderMail(addr: Address, complete: (() -> Void)?) {
        self.queue.sync {
            self.viewModel.updateAddressID(addr.addressID).catch { (error ) in
                let alertController = error.localizedDescription.alertController()
                alertController.addOKAction()
                self.present(alertController, animated: true, completion: nil)
                complete?()
            }.finally {
                self.headerView.updateFromValue(addr.email, pickerEnabled: true)
                MBProgressHUD.hide(for: self.parent!.navigationController!.view, animated: true)
                complete?()
            }
        }
    }

    func ComposeViewDidSizeChanged(_ size: CGSize, showPicker: Bool) {
        // FIXME
    }

    func composeViewDidTapContactGroupSubSelection(_ composeView: ComposeHeaderViewController,
                                                   contactGroup: ContactGroupVO,
                                                   callback: @escaping (([DraftEmailData]) -> Void)) {
        self.dismissKeyboard()
        self.pickedGroup = contactGroup
        self.pickedCallback = callback
        navigateTo?(.subSelection)
    }

    func updateEO() {
        self.viewModel.updateEO(expirationTime: self.headerView.expirationTimeInterval,
                                pwd: self.encryptionPassword,
                                pwdHint: self.encryptionPasswordHint) { [weak self] in
            DispatchQueue.main.async {
                self?.headerView.reloadPicker()
            }
        }
    }

    func composeView(_ composeView: ComposeHeaderViewController, didAddContact contact: ContactPickerModelProtocol, toPicker picker: ContactPicker) {
        if picker == self.headerView.toContactPicker {
            self.viewModel.toSelectedContacts.append(contact)
        } else if picker == headerView.ccContactPicker {
            self.viewModel.ccSelectedContacts.append(contact)
        } else if picker == headerView.bccContactPicker {
            self.viewModel.bccSelectedContacts.append(contact)
        }
    }

    func composeView(_ composeView: ComposeHeaderViewController, didRemoveContact contact: ContactPickerModelProtocol, fromPicker picker: ContactPicker) {
        // here each logic most same, need refactor later
        if picker == self.headerView.toContactPicker {
            var contactIndex = -1
            let selectedContacts = self.viewModel.toSelectedContacts
            for (index, selectedContact) in selectedContacts.enumerated() {
                if let contact = contact as? ContactVO {
                    if contact.displayEmail == selectedContact.displayEmail {
                        contactIndex = index
                    }
                } else if let _ = contact as? ContactGroupVO {
                    if contact.contactTitle == selectedContact.contactTitle {
                        contactIndex = index
                    }
                }
            }
            if contactIndex >= 0 {
                self.viewModel.toSelectedContacts.remove(at: contactIndex)
            }
        } else if picker == headerView.ccContactPicker {
            var contactIndex = -1
            let selectedContacts = self.viewModel.ccSelectedContacts
            for (index, selectedContact) in selectedContacts.enumerated() {
                if contact.displayEmail == selectedContact.displayEmail {
                    contactIndex = index
                }
            }
            if contactIndex >= 0 {
                self.viewModel.ccSelectedContacts.remove(at: contactIndex)
            }
        } else if picker == headerView.bccContactPicker {
            var contactIndex = -1
            let selectedContacts = self.viewModel.bccSelectedContacts
            for (index, selectedContact) in selectedContacts.enumerated() {
                if contact.displayEmail == selectedContact.displayEmail {
                    contactIndex = index
                }
            }
            if contactIndex >= 0 {
                self.viewModel.bccSelectedContacts.remove(at: contactIndex)
            }
        }
    }
}

// MARK: compose data source
extension ComposeViewController: ComposeViewDataSource {

    func composeViewContactsModelForPicker(_ composeView: ComposeHeaderViewController, picker: ContactPicker) -> [ContactPickerModelProtocol] {
        return contacts
    }

    func ccBccIsShownInitially() -> Bool {
        return !self.viewModel.ccSelectedContacts.isEmpty || !self.viewModel.bccSelectedContacts.isEmpty
    }

    func composeViewSelectedContactsForPicker(_ composeView: ComposeHeaderViewController, picker: ContactPicker) -> [ContactPickerModelProtocol] {
        var selectedContacts: [ContactPickerModelProtocol] = []
        if picker == composeView.toContactPicker {
            selectedContacts = self.viewModel.toSelectedContacts
        } else if picker == composeView.ccContactPicker {
            selectedContacts = self.viewModel.ccSelectedContacts
        } else if picker == composeView.bccContactPicker {
            selectedContacts = self.viewModel.bccSelectedContacts
        }
        return selectedContacts
    }
}

// MARK: Attachment
extension ComposeViewController {
    func attachments(pickup attachment: Attachment) -> Promise<Void> {
        return self.collectDraftData().done { [weak self] _ in
            self?.viewModel.composerMessageHelper.addAttachment(attachment)
            self?.viewModel.uploadAtt(attachment)
        }
    }

    func attachments(deleted attachment: Attachment) -> Promise<Void> {
        return Promise { [weak self] seal in
            guard let self = self else {
                seal.fulfill_()
                return
            }
            self.collectDraftData().done { _ in
                if let content_id = attachment.contentID(),
                   !content_id.isEmpty &&
                    attachment.inline() {
                    self.htmlEditor.remove(embedImage: "cid:\(content_id)")
                }
            }.then { [weak self] (_) -> Promise<Void> in
                guard let self = self else { return Promise() }
                return self.viewModel.deleteAtt(attachment)
            }.ensure {
                let realAttachments = userCachedStatus.realAttachments
                self.viewModel.composerMessageHelper.updateAttachmentCount(isRealAttachment: realAttachments)
                seal.fulfill_()
            }.cauterize()
        }

    }
}
