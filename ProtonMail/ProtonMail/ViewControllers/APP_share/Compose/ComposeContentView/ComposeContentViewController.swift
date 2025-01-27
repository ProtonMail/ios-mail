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

import Combine
import MBProgressHUD
import PromiseKit
import ProtonCoreDataModel
import ProtonCoreFoundations
import ProtonCoreUIFoundations
#if !APP_EXTENSION
import LifetimeTracker
import SideMenuSwift
#endif

protocol ComposeContentViewControllerDelegate: AnyObject {
    func displayExpirationWarning()
    func displayContactGroupSubSelectionView()
    func willDismiss()
    func updateAttachmentView()
}

// swiftlint:disable:next line_length type_body_length
class ComposeContentViewController: HorizontallyScrollableWebViewContainer, AccessibleView, HtmlEditorBehaviourDelegate {
    typealias Dependencies = HasImageProxy
    & HasInternetConnectionStatusProviderProtocol
    & HasUserCachedStatus
    & HasUserDefaults

    let viewModel: ComposeViewModel
    var openScheduleSendActionSheet: (() -> Void)?

    weak var headerView: ComposeHeaderViewController!
    lazy var htmlEditor = HtmlEditorBehaviour()

    private var timer: Timer? // auto save timer

    var encryptionPassword: String        = ""
    var encryptionConfirmPassword: String = ""
    var encryptionPasswordHint: String = ""
    private var dismissBySending = false

    private let queue = DispatchQueue(label: "UpdateAddressIdQueue")

    var pickedGroup: ContactGroupVO?
    var pickedCallback: (([DraftEmailData]) -> Void)?
    var groupSubSelectionPresenter: ContactGroupSubSelectionActionSheetPresenter?
    private lazy var schemeHandler: ComposerSchemeHandler = .init(imageProxy: dependencies.imageProxy)
    private var cancellables = Set<AnyCancellable>()

    private let dependencies: Dependencies

    weak var delegate: ComposeContentViewControllerDelegate?

    init(viewModel: ComposeViewModel, dependencies: Dependencies) {
        self.viewModel = viewModel
        self.dependencies = dependencies
        super.init(nibName: nil, bundle: nil)

#if !APP_EXTENSION
        trackLifetime()
#endif
    }

    @available(*, unavailable)
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

        self.prepareWebView(
            urlHandler: schemeHandler,
            urlSchemesToBeHandled: viewModel.urlSchemesToBeHandle
        )
        self.htmlEditor.delegate = self
        self.webView.isOpaque = false
        self.htmlEditor.setup(webView: self.webView)

        self.viewModel.uiDelegate = self

        self.extendedLayoutIncludesOpaqueBars = true

        //  update header view data
        self.updateMessageView()

        // load all contacts and groups
        viewModel.fetchContacts()
        viewModel.fetchPhoneContacts()

        viewModel
            .contactsDidChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.headerView?.toContactPicker?.reloadContactsList()
                self?.headerView?.ccContactPicker?.reloadContactsList()
                self?.headerView?.bccContactPicker?.reloadContactsList()
            }.store(in: &cancellables)

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

        self.viewModel.markAsRead()
        generateAccessibilityIdentifiers()
    }

    @objc
    func dismiss() {
        if self.presentingViewController != nil {
            let presentingVC = self.presentingViewController
            self.handleHintBanner(presentingVC: presentingVC)
        }
        delegate?.willDismiss()
        self.dismiss(animated: true)
    }

    private func findPreviousVC(presentingVC: UIViewController?) -> UIViewController? {
        #if !APP_EXTENSION
        guard let messageID = viewModel.composerMessageHelper.draft?.messageID else {
            return nil
        }
        dependencies.userCachedStatus.lastDraftMessageID = messageID.rawValue

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
        guard let topVC = self.findPreviousVC(presentingVC: presentingVC) as? ComposeSaveHintProtocol else {
            return
        }
        let messageService = self.viewModel.user.messageService
        let coreDataContextProvider = viewModel.dependencies.coreDataContextProvider
        if self.dismissBySending {
            if let listVC = topVC as? MailboxViewController {
                listVC.tableView.reloadData()
            }
            let messageID = viewModel.composerMessageHelper.draft?.messageID ?? MessageID(.empty)
            if viewModel.deliveryTime != nil {
                topVC.showMessageSchedulingHintBanner(messageID: messageID)
            } else {
                topVC.showMessageSendingHintBanner(messageID: messageID, messageDataService: messageService)
            }
        } else {
            if self.viewModel.isEmptyDraft() { return }
            topVC.showDraftSaveHintBanner(cache: dependencies.userCachedStatus,
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
        self.headerView.subject.text = self.viewModel.subject
        let body = self.viewModel.getHtmlBody()
        self.htmlEditor.setHtml(body: body)

        if viewModel.messageAction != .openDraft {
            self.viewModel.collectDraft(
                self.viewModel.subject,
                body: body.body,
                expir: self.headerView.expirationTimeInterval,
                pwd: self.encryptionPassword,
                pwdHit: self.encryptionPasswordHint
            )
        }

        if let currentSenderAddress = viewModel.currentSenderAddress() {
            headerView.updateFromValue(currentSenderAddress.email, pickerEnabled: true)
        }

        showErrorWhenOriginalAddressIsDifferentFromCurrentOne()
        // update draft if first time create
        if viewModel.messageAction != .openDraft {
            self.viewModel.updateDraft()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.removeHintBanner(presentingVC: self.presentingViewController)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ComposeContentViewController.willResignActiveNotification(_:)),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        setupAutoSave()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        stopAutoSave()
    }

    @objc
    func willResignActiveNotification(_ notify: Notification) {
        SystemLogger.log(message: "willResignActiveNotification", category: .draft)
        self.autoSaveTimer()
    }

    func sendAction(deliveryTime: Date?) {
        viewModel.deliveryTime = deliveryTime
        sendAction()
    }

   func sendAction() {
        self.dismissKeyboard()

        delay(0.3) {
            self.stopAutoSave()
            if self.viewModel.deliveryTime == nil {
                self.validateDraftBeforeSending()
            } else {
                self.startSendingMessage()
            }
        }
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

        let invalidRecipients = recipients.filter {
            $0.encryptionIconStatus?.isInvalid == true &&
            $0.encryptionIconStatus?.nonExisting == false
        }
        guard invalidRecipients.isEmpty else {
            let message = LocalString._address_invalid_warning_sending
            showAlert(message)
            return false
        }

        let nonExistingRecipients = recipients.filter { $0.encryptionIconStatus?.nonExisting == true }
        guard nonExistingRecipients.isEmpty else {
            let message = LocalString._address_non_exist_warning
            showAlert(message)
            return false
        }

        let badGroups = contacts
            .compactMap { $0 as? ContactGroupVO }
            .filter { !$0.allMemberValidate }
        guard badGroups.isEmpty else {
            let message = LocalString._address_in_group_not_found_warning
            showAlert(message)
            return false
        }
        return true
    }

    func validateDraftBeforeSending() {
        SystemLogger.log(message: "Validating draft before sending", category: .sendMessage)

        if self.headerView.expirationTimeInterval > 0 {
            if viewModel.shouldShowExpirationWarning(havingPGPPinned: headerView.hasPGPPinned,
                                                     isPasswordSet: !encryptionPassword.isEmpty,
                                                     havingNonPMEmail: headerView.hasNonePMEmails) {
                SystemLogger.log(message: "Expiration alert will \(delegate == nil ? "not " : "")be shown", category: .sendMessage)
                delegate?.displayExpirationWarning()
                return
            }
        }
        displayDraftNotValidAlertIfNeeded { [weak self] in
            self?.startSendingMessage()
        }
    }

    func startSendingMessage() {
        do {
            try viewModel.sendMessage(deliveryTime: viewModel.deliveryTime)
        } catch {
            SystemLogger.log(error: error, category: .sendMessage)
            show(error: "\(error)")
        }

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
        self.collectDraftDataAndSaveToDB().done { [weak self] _ in
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
            SystemLogger.log(message: "autosave timer triggered", category: .draft)
            self?.autoSaveTimer()
        }
    }

    private func stopAutoSave() {
        if let timer = self.timer {
            timer.invalidate()
            self.timer = nil
        }
    }

    @objc
    func autoSaveTimer() {
        _ = collectDraftDataAndSaveToDB()
            .done { [weak self] _ in
                self?.viewModel.updateDraft()
            }
    }

    func collectDraftBody() -> Promise<String?> {
        return Promise { [weak self] seal in
            guard let self = self else {
                seal.fulfill(nil)
                return
            }
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
                    body += foot
                }
                seal.fulfill(body)
            }.catch { _ in
                seal.fulfill(nil)
            }.finally {
                seal.fulfill(nil)
            }
        }
    }

    func collectDraftDataAndSaveToDB() -> Promise<(String, String)?> {
        return collectDraftBody().then { [weak self] body -> Promise<(String, String)?> in
            guard let self = self, let body = body else { return Promise.value(nil) }

            let subject = self.headerView.subject.text ?? "(No Subject)"
            self.saveDraftDataToDB(subject: subject, body: body)
            return Promise.value((subject, body))
        }
    }

    private func saveDraftDataToDB(subject: String, body: String) {
        viewModel.collectDraft(
            subject,
            body: body,
            expir: self.headerView.expirationTimeInterval,
            pwd: self.encryptionPassword,
            pwdHit: self.encryptionPasswordHint
        )
    }

    // MARK: - HtmlEditorBehaviourDelegate

    func addInlineAttachment(cid: String, name: String, data: Data) {
        do {
            // Data.toAttachment will automatically increment number of attachments in the message
            _ = try viewModel.composerMessageHelper.addAttachment(
                data: data,
                fileName: name,
                shouldStripMetaData: viewModel.shouldStripMetaData,
                type: "image/png",
                isInline: true,
                cid: cid
            )
        } catch {
            SystemLogger.log(error: error, category: .draft)
        }

        viewModel.updateDraft()
    }

    func removeInlineAttachment(_ cid: String) {
        viewModel.composerMessageHelper.removeAttachment(
            cid: cid,
            isRealAttachment: true
        ) { [weak self] in
            self?.viewModel.updateDraft()
        }
    }

    func htmlEditorDidFinishLoadingContent() {
        viewModel.embedInlineAttachments(in: htmlEditor)
        viewModel.insertImportedFiles(in: htmlEditor)
    }

    @objc
    func caretMovedTo(_ offset: CGPoint) {
        fatalError("should be overridden")
    }

    func selectedInlineAttachment(_ cid: String) {
        SystemLogger.log(message: "selected inline attachment, cid:\(cid)", category: .draft)
        guard let targetView = parent?.navigationController else {
            return
        }
        // do not show the action sheet while uploading
        guard let attachment = viewModel.getAttachments()
            .first(where: { $0.getContentID() == cid && $0.id.rawValue != "0" }) else {
            return
        }
        dismissKeyboard()

        let items: [PMActionSheetItem] = [
            PMActionSheetItem(
                title: LocalString._general_remove_button,
                icon: nil,
                textColor: ColorProvider.NotificationError
            ) { [weak self] _ in
                SystemLogger.log(message: "removing inline attachment through alert", category: .draft)
                self?.htmlEditor.remove(embedImage: "cid:\(cid)")
            },
            PMActionSheetItem(title: L10n.InlineAttachment.addAsAttachment, icon: nil) { [weak self] _ in
                MBProgressHUD.showAdded(to: targetView.view, animated: true)
                SystemLogger.log(message: "will convert inline image to attachment", category: .draft)
                self?.viewModel.attachInlineAttachment(
                    inlineAttachment: attachment
                ) { shouldRemoveInline in
                    if shouldRemoveInline {
                        self?.delegate?.updateAttachmentView()
                        self?.htmlEditor.remove(embedImage: "cid:\(cid)")
                    }
                    SystemLogger.log(
                        message: "did convert inline image to attachment, shouldRemoveInline:\(shouldRemoveInline)",
                        category: .draft
                    )
                    MBProgressHUD.hide(for: targetView.view, animated: true)
                }
            }
        ]

        let headerView = PMActionSheetHeaderView(title: attachment.name)
        let itemGroup = PMActionSheetItemGroup(items: items, style: .clickable)
        let actionSheet = PMActionSheet(headerView: headerView, itemGroups: [itemGroup])
        actionSheet.presentAt(targetView, animated: true)
    }
}

// MARK: - Methods about draft validation

extension ComposeContentViewController {
    func displayDraftNotValidAlertIfNeeded(
        isTriggeredFromScheduleButton: Bool = false,
        continueAction: @escaping () -> Void
    ) {
        isUserInputValidInTheHeaderViewOfComposer { [weak self] in
            _ = self?.collectDraftBody().done { body in
                guard let self, let body else {
                    SystemLogger.log(message: "Draft validation taking longer than usual", category: .draft)
                    return
                }

                let bodyWithoutBase64 = self.viewModel.extractAndUploadBase64ImagesFromSendingBody(body: body)

                let subject = self.headerView.subject.text ?? "(No Subject)"
                self.saveDraftDataToDB(subject: subject, body: bodyWithoutBase64)

                self.showRecipientEmptyAlertIfNeeded {
                    self.showInvalidAddressAlertIfNeeded {
                        self.showAttachmentRemindAlertIfNeeded(
                            subject: subject,
                            body: bodyWithoutBase64
                        ) {
                            self.showScheduleSendConfirmationAlertIfNeeded(
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
        guard composerRecipientsValidation() else {
            SystemLogger.log(message: "Validating recipients", category: .sendMessage)
            return
        }

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
            alert.addAction(UIAlertAction.okAction())
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
            handler: nil
        )
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
        alertController.addAction(
            UIAlertAction(title: LocalString._composer_send_msg_which_was_schedule_send_action_title,
                          style: .destructive,
                          handler: { _ in
                              continueAction()
                          })
        )
        alertController.addAction(
            UIAlertAction(title: LocalString._general_schedule_send_action,
                          style: .default,
                          handler: { [weak self] _ in
                              self?.openScheduleSendActionSheet?()
                          })
        )
        self.present(alertController, animated: true, completion: nil)
    }

    private func showScheduleSendConfirmationAlertIfNeeded(
        isTriggeredFromScheduleButton: Bool,
        continueAction: @escaping () -> Void
    ) {
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
        alertController.addCancelAction()
        present(alertController, animated: true, completion: nil)
    }

    private func showErrorWhenOriginalAddressIsDifferentFromCurrentOne() {
        guard let currentSenderAddress = viewModel.currentSenderAddress(),
              let originalAddress = viewModel.originalSenderAddress() else {
            return
        }

        if viewModel.shouldShowSenderChangedAlertDueToDisabledAddress() {
            showSenderChangedAlert(newAddress: currentSenderAddress)
        } else if viewModel.shouldShowErrorWhenOriginalAddressIsAnUnpaidPMAddress() {
            showErrorWhenOriginalAddressIsAnUnpaidPMAddress(
                currentSenderAddress: currentSenderAddress,
                originalAddress: originalAddress
            )
        }
    }

    private func showErrorWhenOriginalAddressIsAnUnpaidPMAddress(
        currentSenderAddress: Address,
        originalAddress: Address
    ) {
        guard
            originalAddress.send == .inactive,
            originalAddress.isPMAlias,
            !dependencies.userDefaults[.isPMMEWarningDisabled]
        else { return }

        showPaidFeatureAddressAlert(
            originalAddress: originalAddress,
            currentSenderAddress: currentSenderAddress
        )
    }

    private func showPaidFeatureAddressAlert(originalAddress: Address, currentSenderAddress: Address) {
        let errorMessage = String(
            format: LocalString._composer_sending_messages_from_a_paid_feature,
            originalAddress.email,
            currentSenderAddress.email
        )
        let alertController = errorMessage.alertController(LocalString._general_notice_alert_title)
        alertController.addOKAction()
        alertController.addAction(
            UIAlertAction(
                title: LocalString._general_dont_remind_action,
                style: .destructive,
                handler: { [weak self] _ in
                    self?.dependencies.userDefaults[.isPMMEWarningDisabled] = true
                }
            )
        )
        self.present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Expiration unavailability alert

extension ComposeContentViewController {
    func showExpirationUnavailabilityAlert(nonPMEmails: [String], pgpEmails: [String]) {
        var message = String()
        if !nonPMEmails.isEmpty {
            message.append(LocalString._we_recommend_setting_up_a_password)
            message.append("\n\n")
            if nonPMEmails.count > 5 {
                message.append(nonPMEmails[...3].joined(separator: "\n"))
                let extraStr = String(format: LocalString._extra_addresses,
                                      nonPMEmails.count - 4)
                message.append("\n\(extraStr)")
            } else {
                message.append(nonPMEmails.joined(separator: "\n"))
            }
            message.append("\n")
        }
        if !pgpEmails.isEmpty {
            if !nonPMEmails.isEmpty { message.append("\n") }
            message.append(LocalString._we_recommend_setting_up_a_password_or_disabling_pgp)
            message.append("\n\n")
            if pgpEmails.count > 5 {
                message.append(pgpEmails[...3].joined(separator: "\n"))
                let extraStr = String(format: LocalString._extra_addresses,
                                      pgpEmails.count - 4)
                message.append("\n\(extraStr)")
            } else {
                message.append(pgpEmails.joined(separator: "\n"))
            }
            message.append("\n")
        }
        let alertController = UIAlertController(
            title: LocalString._expiration_not_supported,
            message: message,
            preferredStyle: .alert
        )
        let sendAnywayAction = UIAlertAction(title: LocalString._send_anyway, style: .destructive) { [weak self] _ in
            self?.displayDraftNotValidAlertIfNeeded {
                self?.startSendingMessage()
            }
        }
        let cancelAction = UIAlertAction(title: LocalString._general_cancel_action, style: .default, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(sendAnywayAction)
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - view extensions

extension ComposeContentViewController: ComposeViewDelegate {

    func lockerCheck(model: ContactPickerModelProtocol, progress: () -> Void, complete: LockCheckComplete?) {
        self.viewModel.lockerCheck(model: model, progress: progress, complete: complete)
    }

    func checkMails(in contactGroup: ContactGroupVO, progress: () -> Void, complete: LockCheckComplete?) {
        self.viewModel.checkMails(in: contactGroup, progress: progress, complete: complete)
    }

    func setupComposeFromMenu(for button: UIButton) {
        let addresses = viewModel.getAddresses()
        let currentSenderAddress = viewModel.currentSenderAddress()
        var actions: [UIAction] = []
        for address in addresses {
            guard address.status == .enabled && address.send == .active else { continue }

            let state: UIMenuElement.State = currentSenderAddress == address ? .on : .off
            let item = UIAction(title: address.email, state: state) { [weak self] action in
                guard action.state == .off, let self = self else { return }
                guard address.send == .active else {
                    let error = String(format: LocalString._composer_change_paid_plan_sender_error, address.email)
                    let alertController = error.alertController()
                    alertController.addOKAction()
                    self.present(alertController, animated: true, completion: nil)
                    return
                }
                if let signature = self.viewModel.getCurrentSignature(address.addressID) {
                    self.htmlEditor.update(signature: signature)
                }
                if let viewToAdd = self.parent?.navigationController?.view {
                    MBProgressHUD.showAdded(to: viewToAdd, animated: true)
                    self.updateSenderMail(addr: address) { [weak self] in
                        self?.setupComposeFromMenu(for: button)
                    }
                }
            }
            item.accessibilityLabel = address.email
            actions.append(item)
        }
        let menu = UIMenu(title: "", options: .displayInline, children: actions)
        button.menu = menu
        button.showsMenuAsPrimaryAction = true
    }

    private func updateSenderMail(addr: Address, complete: (() -> Void)?) {
        self.queue.sync { [weak self] in
            self?.viewModel.updateAddress(to: addr, completion: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.headerView.updateFromValue(addr.email, pickerEnabled: true)
                    case .failure(let error):
                        let alertController = error.localizedDescription.alertController()
                        alertController.addOKAction()
                        self?.present(alertController, animated: true, completion: nil)
                    }
                    if let viewToAddTo = self?.parent?.navigationController?.view {
                        MBProgressHUD.hide(for: viewToAddTo, animated: true)
                    }
                    complete?()
                }
            })
        }
    }

    func composeViewDidTapContactGroupSubSelection(_ composeView: ComposeHeaderViewController,
                                                   contactGroup: ContactGroupVO,
                                                   callback: @escaping (([DraftEmailData]) -> Void)) {
        self.dismissKeyboard()
        self.pickedGroup = contactGroup
        self.pickedCallback = callback
        delegate?.displayContactGroupSubSelectionView()
    }

    func updateEO() {
        self.viewModel.updateEO(expirationTime: self.headerView.expirationTimeInterval,
                                password: self.encryptionPassword,
                                passwordHint: self.encryptionPasswordHint) { [weak self] in
            DispatchQueue.main.async {
                self?.headerView.reloadPicker()
            }
        }
    }

    func composeView(
        _ composeView: ComposeHeaderViewController,
        didAddContact contact: ContactPickerModelProtocol,
        toPicker picker: ContactPicker
    ) {
        if picker == self.headerView.toContactPicker {
            self.viewModel.toSelectedContacts.append(contact)
        } else if picker == headerView.ccContactPicker {
            self.viewModel.ccSelectedContacts.append(contact)
        } else if picker == headerView.bccContactPicker {
            self.viewModel.bccSelectedContacts.append(contact)
        }
    }

    func composeView(
        _ composeView: ComposeHeaderViewController,
        didRemoveContact contact: ContactPickerModelProtocol,
        fromPicker picker: ContactPicker
    ) {
        // here each logic most same, need refactor later
        if picker == self.headerView.toContactPicker {
            var contactIndex = -1
            let selectedContacts = self.viewModel.toSelectedContacts
            for (index, selectedContact) in selectedContacts.enumerated() {
                if let contact = contact as? ContactVO {
                    if contact.displayEmail == selectedContact.displayEmail {
                        contactIndex = index
                    }
                } else if contact as? ContactGroupVO != nil {
                    if contact.contactTitle == selectedContact.contactTitle {
                        contactIndex = index
                    }
                }
            }
            if contactIndex >= 0 {
                self.viewModel.toSelectedContacts.remove(at: contactIndex)
            }
        } else if picker == headerView.ccContactPicker {
            viewModel.ccSelectedContacts.removeAll { selectedContact in
                contact.displayEmail == selectedContact.displayEmail
            }
        } else if picker == headerView.bccContactPicker {
            viewModel.bccSelectedContacts.removeAll { selectedContact in
                contact.displayEmail == selectedContact.displayEmail
            }
        }
    }
}

// MARK: compose data source

extension ComposeContentViewController: ComposeViewDataSource {
    func composeViewContactsModelForPicker(
        _ composeView: ComposeHeaderViewController,
        picker: ContactPicker
    ) -> [ContactPickerModelProtocol] {
        return viewModel.contacts
    }

    func ccBccIsShownInitially() -> Bool {
        return !self.viewModel.ccSelectedContacts.isEmpty || !self.viewModel.bccSelectedContacts.isEmpty
    }

    func composeViewSelectedContactsForPicker(
        _ composeView: ComposeHeaderViewController,
        picker: ContactPicker
    ) -> [ContactPickerModelProtocol] {
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

extension ComposeContentViewController {
    func attachments(deleted attachment: AttachmentEntity) -> Promise<Void> {
        return Promise { [weak self] seal in
            guard let self = self else {
                seal.fulfill_()
                return
            }
            self.collectDraftDataAndSaveToDB().done { _ in
                if let contentID = attachment.getContentID(),
                   !contentID.isEmpty &&
                   attachment.isInline {
                    self.htmlEditor.remove(embedImage: "cid:\(contentID)")
                }
            }.then { [weak self] _ -> Promise<Void> in
                guard let self = self else { return Promise() }
                return self.viewModel.deleteAttachment(attachment)
            }.ensure {
                self.viewModel.composerMessageHelper.updateAttachmentCount(isRealAttachment: true)
                seal.fulfill_()
            }.cauterize()
        }
    }
}

extension ComposeContentViewController: ComposeUIProtocol {
    func changeInvalidSenderAddress(to newAddress: Address) {
        updateSenderMail(addr: newAddress) { [weak self] in
            DispatchQueue.main.async {
                self?.showSenderChangedAlert(newAddress: newAddress)
            }
        }
    }

    func updateSenderAddressesList() {
        DispatchQueue.main.async {
            guard let button = self.headerView.fromPickerButton else { return }
            self.setupComposeFromMenu(for: button)
        }
    }

    func show(error: String) {
        error.alertToast(view: view)
    }

    private func showSenderChangedAlert(newAddress: Address) {
        let alert = UIAlertController(
            title: L10n.Compose.senderChanged,
            message: String(format: L10n.Compose.senderChangedMessage, newAddress.email),
            preferredStyle: .alert
        )
        alert.addOKAction()
        present(alert, animated: true)
    }
}

#if !APP_EXTENSION
extension ComposeContentViewController: LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }
}
#endif
