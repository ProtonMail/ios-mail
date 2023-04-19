//
//  ComposingViewController.swift
//  Proton Mail - Created on 12/04/2019.
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

#if !APP_EXTENSION
import LifetimeTracker
import ProtonCore_PaymentsUI
#endif
import MBProgressHUD
import PromiseKit
import ProtonCore_DataModel
import ProtonCore_Foundations
import ProtonCore_UIFoundations
import UIKit

class ComposeContainerViewController: TableContainerViewController<ComposeContainerViewModel> {
    #if !APP_EXTENSION
    class var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }
    private var paymentsUI: PaymentsUI?
    #endif

    enum Constant {
        static let timerInterval: TimeInterval = 30
        static let toolBarHeight: CGFloat = 48
        static let attachmentProcessCount = 1
    }

    private var childrenHeightObservations: [NSKeyValueObservation] = []
    private var cancelButton: UIBarButtonItem?
    private var sendButton: UIBarButtonItem?
    private var scheduledSendButton: UIBarButtonItem?
    private var bottomPadding: NSLayoutConstraint?
    private var dropLandingZone: UIView? // drag and drop session items dropped on this view will be added as attachments
    private var syncTimer: Timer?
    private var toolbarBottom: NSLayoutConstraint?
    private var toolbar: ComposeToolbar?
    private var isAddingAttachment: Bool = false
    private var attachmentsReloaded = false
    private var scheduledSendHelper: ScheduledSendHelper?

    private(set) lazy var attachmentProcessQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = Constant.attachmentProcessCount
        return queue
    }()

    private(set) lazy var attachmentProviders: [AttachmentProvider] = { [unowned self] in
        // There is no access to camera in AppExtensions, so should not include it into menu
        #if APP_EXTENSION
        return [PhotoAttachmentProvider(for: self),
                DocumentAttachmentProvider(for: self)]
        #else
        return [PhotoAttachmentProvider(for: self),
                CameraAttachmentProvider(for: self),
                DocumentAttachmentProvider(for: self)]
        #endif
    }()

    private lazy var separatorView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = ColorProvider.Shade20
        return view
    }()

    var isUploadingAttachments: Bool = false {
        didSet {
            setupTopRightBarButton()
            setUpTitleView()
        }
    }

    private let contextProvider: CoreDataContextProviderProtocol

    // MARK: - Child ViewControllers

    let header: ComposeHeaderViewController = ComposerChildViewFactory.makeHeaderView()

    lazy var editor: ContainableComposeViewController = ComposerChildViewFactory.createEditor(
        parentView: self,
        headerView: header,
        viewModel: viewModel.childViewModel,
        openScheduleSendActionSheet: { [weak self] in
            self?.showScheduleSendActionSheet()
        },
        delegate: self
    )

    lazy var attachmentView: ComposerAttachmentVC = ComposerChildViewFactory.makeAttachmentView(
        viewModel: viewModel.childViewModel,
        contextProvider: contextProvider,
        delegate: self,
        isUploading: { [weak self] in
            self?.isUploadingAttachments = $0
        }
    )

    init(
        viewModel: ComposeContainerViewModel,
        contextProvider: CoreDataContextProviderProtocol
    ) {
        self.contextProvider = contextProvider
        super.init(viewModel: viewModel)
        viewModel.uiDelegate = self
        #if !APP_EXTENSION
        trackLifetime()
        #endif
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.childrenHeightObservations.forEach { $0.invalidate() }
        NotificationCenter.default.removeKeyboardObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    private lazy var scheduleSendIntroView = ScheduledSendSpotlightView()

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            self.isModalInPresentation = true
        }
        self.tableView.backgroundColor = .clear
        self.tableView.separatorStyle = .none
        self.tableView.dropDelegate = self

        view.backgroundColor = ColorProvider.BackgroundNorm

        NotificationCenter.default.addKeyboardObserver(self)

        self.scheduledSendHelper = ScheduledSendHelper(viewController: self,
                                                       delegate: self,
                                                       originalScheduledTime: viewModel.childViewModel.originalScheduledTime)
        self.setupBottomPadding()
        self.configureNavigationBar()
        self.setupChildViewModel()
        self.setupToolbar()
        self.setupTopSeparatorView()
        self.emptyBackButtonTitleForNextView()
        let childVM = self.viewModel.childViewModel
        if childVM.shareOverLimitationAttachment {
            self.sizeError()
        }

        // accessibility
        generateAccessibilityIdentifiers()

        updateAttachmentView { [weak self] in
            #if APP_EXTENSION
            self?.getSharedFiles()
            #endif
        }

        viewModel.childViewModel.composerMessageHelper.updateAttachmentView = { [weak self] in
            self?.updateAttachmentView(completion: {})
        }

        // init the editor first here to fix the UI issue
        _ = editor
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        attachmentView.addNotificationObserver()
        updateCurrentAttachmentSize(completion: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.startAutoSync()
        #if !APP_EXTENSION
        if #available(iOS 13.0, *) {
            self.view.window?.windowScene?.title = LocalString._general_draft_action
        }
        #endif

        generateAccessibilityIdentifiers()
        showScheduleSendIntroViewIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopAutoSync()

        guard let vcCounts = self.navigationController?.viewControllers.count else {
            return
        }
        if vcCounts == 1 {
            // Composer dismiss
            attachmentView.removeNotificationObserver()
        }
    }

    override func configureNavigationBar() {
        super.configureNavigationBar()

        self.navigationController?.navigationBar.barTintColor = ColorProvider.BackgroundNorm
        self.navigationController?.navigationBar.isTranslucent = false

        self.setupTopRightBarButton()
        self.setupCancelButton()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        cell.backgroundColor = .white
        return cell
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)

        if let headerCell = tableView.cellForRow(at: .init(row: 0, section: 0)) {
            separatorView.isHidden = tableView.visibleCells.contains(headerCell)
        } else {
            separatorView.isHidden = false
        }
        guard let cell = tableView.cellForRow(at: .init(row: 2, section: 0)) else { return }

        let areAttachmentsVisibleOnScreen = cell.frame.minY < (scrollView.contentOffset.y + scrollView.frame.height)

        if !attachmentsReloaded, areAttachmentsVisibleOnScreen {
            attachmentsReloaded = true
            children.compactMap { $0 as? ComposerAttachmentVC }.first?.refreshAttachmentsLoadingState()
        }

        if attachmentsReloaded == true, areAttachmentsVisibleOnScreen == false {
            attachmentsReloaded = false
        }
    }

    override func embedChild(indexPath: IndexPath, onto cell: UITableViewCell) {
        switch indexPath.row {
        case 0:
            embed(header, onto: cell.contentView, ownedBy: self)
        case 1:
            cell.contentView.backgroundColor = ColorProvider.BackgroundNorm
            embed(editor, onto: cell.contentView, layoutGuide: cell.contentView.layoutMarginsGuide, ownedBy: self)
        case 2:
            embed(attachmentView, onto: cell.contentView, ownedBy: self)
        default:
            assertionFailure("Child view setup is wrong")
        }
    }

    // MARK: IBAction

    @objc
    func cancelAction(_ sender: UIBarButtonItem) {
        editor.cancelAction()
    }

    @objc
    func sendAction(_ sender: UIBarButtonItem) {
        viewModel.isSendButtonTapped = true

        // TODO: move send action in editor into viewModel
        editor.sendAction(sender)
    }

    #if APP_EXTENSION
    func getSharedFiles() {
        self.isAddingAttachment = true
    }
    #endif
}

// MARK: UI related

extension ComposeContainerViewController {
    private func setupBottomPadding() {
        self.bottomPadding = self.view.bottomAnchor.constraint(equalTo: self.tableView.bottomAnchor)
        self.bottomPadding?.constant = UIDevice.safeGuide.bottom + Constant.toolBarHeight
        self.bottomPadding?.isActive = true
    }

    private func setupChildViewModel() {
        self.childrenHeightObservations = [
            viewModel.childViewModel.observe(\.contentHeight) { [weak self] _, _ in
                UIView.animate(withDuration: 0.001, animations: {
                    self?.saveOffset()
                    self?.tableView.beginUpdates()
                    self?.tableView.endUpdates()
                    self?.restoreOffset()
                })
            },
            header.observe(\.size) { [weak self] _, _ in
                self?.tableView.beginUpdates()
                self?.tableView.endUpdates()
            },
            attachmentView.observe(\.tableHeight) { [weak self] _, _ in
                DispatchQueue.main.async {
                    let path = IndexPath(row: 0, section: 0)
                    self?.tableView.beginUpdates()
                    if self?.tableView.cellForRow(at: path) == nil {
                        self?.tableView.reloadRows(at: [path], with: .none)
                    }
                    self?.tableView.endUpdates()
                    guard self?.isAddingAttachment ?? false else { return }
                    self?.isAddingAttachment = false
                    // A bit of delay can get real contentSize
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        var yOffset: CGFloat = 0
                        let contentHeight = self?.tableView.contentSize.height ?? 0
                        let sizeHeight = self?.tableView.bounds.size.height ?? 0
                        if contentHeight > sizeHeight {
                            yOffset = contentHeight - sizeHeight
                        }
                        self?.tableView.setContentOffset(CGPoint(x: 0, y: yOffset), animated: false)
                    }
                }
            }
        ]
    }

    private func setupTopRightBarButton() {
        self.setupSendButton()
        self.setupScheduledSendButton()
        var items: [UIBarButtonItem] = []
        if let sendButton = self.sendButton {
            items.append(sendButton)
        }
        if viewModel.isScheduleSendEnable,
           let scheduleButton = self.scheduledSendButton {
            items.append(scheduleButton)
        }
        self.navigationItem.rightBarButtonItems = items
    }

    private func setupSendButton() {
        let isEnabled = viewModel.hasRecipients() && !isUploadingAttachments
        self.sendButton = Self.makeBarButtonItem(
            isEnabled: isEnabled,
            icon: IconProvider.paperPlaneHorizontal,
            target: self,
            action: #selector(sendAction)
        )

        self.sendButton?.accessibilityLabel = LocalString._general_send_action
        self.sendButton?.accessibilityIdentifier = "ComposeContainerViewController.sendButton"
    }

    private func setupScheduledSendButton() {
        guard viewModel.isScheduleSendEnable else { return }
        let isEnabled = viewModel.hasRecipients() && !isUploadingAttachments
        self.scheduledSendButton = Self.makeBarButtonItem(
            isEnabled: isEnabled,
            icon: IconProvider.clockPaperPlane,
            target: self,
            action: #selector(self.presentScheduleSendActionSheetIfDraftIsReady)
        )
        self.scheduledSendButton?.accessibilityLabel = LocalString._general_schedule_send_action
        self.scheduledSendButton?.accessibilityIdentifier = "ComposeContainerViewController.scheduledSend"
    }

    private static func makeBarButtonItem(
        isEnabled: Bool,
        icon: UIImage,
        target: Any?,
        action: Selector
    ) -> UIBarButtonItem {
        let tintColor: UIColor = isEnabled ? ColorProvider.IconNorm : ColorProvider.IconDisabled
        let item = icon.toUIBarButtonItem(
            target: target,
            action: isEnabled ? action : nil,
            style: .plain,
            tintColor: tintColor,
            squareSize: 22,
            backgroundColor: .clear,
            backgroundSquareSize: 35,
            isRound: true,
            imageInsets: .zero
        )
        return item
    }

    private func setUpTitleView() {
        guard !viewModel.isSendButtonTapped else {
            navigationItem.titleView = nil
            return
        }
        navigationItem.titleView = isUploadingAttachments ? ComposeAttachmentsAreUploadingTitleView() : nil
    }

    private func setupCancelButton() {
        self.cancelButton = UIBarButtonItem(image: IconProvider.cross, style: .plain, target: self, action: #selector(cancelAction))
        self.cancelButton?.accessibilityIdentifier = "ComposeContainerViewController.cancelButton"
        self.navigationItem.leftBarButtonItem = self.cancelButton
    }

    private func setupToolbar() {
        let bar = ComposeToolbar(delegate: self)
        bar.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(bar)
        [
            bar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            bar.heightAnchor.constraint(equalToConstant: 48)
        ].activate()
        self.toolbarBottom = bar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -1 * UIDevice.safeGuide.bottom)
        self.toolbarBottom?.isActive = true
        self.toolbar = bar
    }

    private func setupTopSeparatorView() {
        view.addSubview(separatorView)
        [
            separatorView.topAnchor.constraint(equalTo: view.topAnchor),
            separatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 2)
        ].activate()
        separatorView.isHidden = true
    }

    private func startAutoSync() {
        self.stopAutoSync()
        self.syncTimer = Timer.scheduledTimer(withTimeInterval: Constant.timerInterval, repeats: true, block: { [weak self] _ in
            self?.viewModel.syncMailSetting()
        })
    }

    private func stopAutoSync() {
        self.syncTimer?.invalidate()
        self.syncTimer = nil
    }

    private func showScheduleSendIntroViewIfNeeded() {
        guard viewModel.isScheduleSendEnable,
              !viewModel.isScheduleSendIntroViewShown else {
            return
        }
        viewModel.userHasSeenScheduledSendSpotlight()

        guard let navView = self.navigationController?.view,
              let scheduleItemView = self.scheduledSendButton?.value(forKey: "view") as? UIView,
              let targetView = scheduleItemView.subviews.first else {
            return
        }
        let barFrame = targetView.frame
        let rect = scheduleItemView.convert(barFrame, to: navView)
        scheduleSendIntroView.presentOn(view: navView,
                                        targetFrame: rect)
    }

    @objc
    private func presentScheduleSendActionSheetIfDraftIsReady() {
        editor.displayDraftNotValidAlertIfNeeded(isTriggeredFromScheduleButton: true) { [weak self] in
            self?.showScheduleSendActionSheet()
        }
    }

    private func updateAttachmentCount(number: Int) {
        DispatchQueue.main.async {
            self.toolbar?.setAttachment(number: number)
        }
    }

    private func updateCurrentAttachmentSize(completion: (() -> Void)?) {
        attachmentView.getSize { [weak self] size in
            self?.viewModel.currentAttachmentSize = size
            completion?()
        }
    }

    private func showScheduleSendActionSheet() {
        scheduledSendHelper?.presentActionSheet()
    }
}

// MARK: - UITableViewDropDelegate

extension ComposeContainerViewController: UITableViewDropDelegate {
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView,
                   canHandle session: UIDropSession) -> Bool {
        // return true only if all the files are supported
        let itemProviders = session.items.map { $0.itemProvider }
        return self.viewModel.filesAreSupported(from: itemProviders)
    }

    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView,
                   dropSessionDidUpdate session: UIDropSession,
                   withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        return UITableViewDropProposal(operation: .copy, intent: .insertIntoDestinationIndexPath)
    }

    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, dropSessionDidEnter session: UIDropSession) {
        if self.dropLandingZone == nil {
            var dropFrame = self.tableView.frame
            dropFrame.size.height = header.view.frame.size.height
            let dropZone = DropLandingZone(frame: dropFrame)
            dropZone.alpha = 0.0
            self.tableView.addSubview(dropZone)
            self.dropLandingZone = dropZone
        }

        UIView.animate(withDuration: 0.3) {
            self.dropLandingZone?.alpha = 1.0
        }
    }

    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, dropSessionDidExit session: UIDropSession) {
        UIView.animate(withDuration: 0.3, animations: {
            self.dropLandingZone?.alpha = 0.0
        })
    }

    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, dropSessionDidEnd session: UIDropSession) {
        UIView.animate(withDuration: 0.3, animations: {
            self.dropLandingZone?.alpha = 0.0
        }) { _ in
            self.dropLandingZone?.removeFromSuperview()
            self.dropLandingZone = nil
        }
    }

    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView,
                   performDropWith coordinator: UITableViewDropCoordinator) {
        DispatchQueue.main.async {
            LocalString._importing_drop.alertToastBottom(view: self.view)
        }

        let itemProviders = coordinator.items.map { $0.dragItem.itemProvider }
        self.viewModel.importFiles(from: itemProviders, errorHandler: self.error) {
            DispatchQueue.main.async {
                LocalString._drop_finished.alertToastBottom(view: self.view)
            }
        }
    }
}

// MARK: - ComposeToolbarDelegate

extension ComposeContainerViewController: ComposeToolbarDelegate {
    func showEncryptOutsideView() {
        self.view.endEditing(true)
        editor.autoSaveTimer()
        viewModel.navigateToPassword(
            password: editor.encryptionPassword,
            confirmPassword: editor.encryptionConfirmPassword,
            passwordHint: editor.encryptionPasswordHint,
            delegate: self
        )
    }

    func showExpireView() {
        self.view.endEditing(true)
        editor.autoSaveTimer()
        let time = header.expirationTimeInterval
        viewModel.navigateToExpiration(expiration: time,
                                       delegate: self)
    }

    func showAttachmentView() {
        if self.viewModel.user.isStorageExceeded {
            LocalString._storage_exceeded.alertToast(withTitle: false, view: self.view)
            return
        }
        header.view.endEditing(true)
        editor.view.endEditing(true)
        attachmentView.view.endEditing(true)
        self.view.endEditing(true)

        var sheet: PMActionSheet!

        let header = PMActionSheetHeaderView(
            title: LocalString._menu_add_attachment,
            leftItem: .right(IconProvider.cross),
            showDragBar: false,
            leftItemHandler: { sheet.dismiss(animated: true) }
        )
        let itemGroup = self.getActionSheetItemGroup()
        sheet = PMActionSheet(headerView: header, itemGroups: [itemGroup])
        let viewController = self.navigationController ?? self
        sheet.presentAt(viewController, animated: true)
    }

    private func getActionSheetItemGroup() -> PMActionSheetItemGroup {
        let items: [PMActionSheetItem] = self.attachmentProviders.map(\.actionSheetItem)
        let itemGroup = PMActionSheetItemGroup(items: items, style: .clickable)
        return itemGroup
    }
}

// MARK: - AttachmentController protocol

extension ComposeContainerViewController: AttachmentController {
    func error(title: String, description: String) {
        let alert = description.alertController(title)
        alert.addOKAction()
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }

    func fileSuccessfullyImported(as fileData: FileData) -> Promise<Void> {
        return Promise { [weak self] seal in
            guard let self = self else {
                seal.fulfill_()
                return
            }
            self.attachmentProcessQueue.addOperation { [weak self] in
                guard let self = self else {
                    seal.fulfill_()
                    return
                }
                if self.viewModel.user.isStorageExceeded {
                    DispatchQueue.main.async {
                        LocalString._storage_exceeded.alertToast()
                    }
                    seal.fulfill_()
                    return
                }
                let size = fileData.contents.dataSize

                let remainingSize = (Constants.kDefaultAttachmentFileSize - self.viewModel.currentAttachmentSize)
                guard size < remainingSize else {
                    self.sizeError()
                    seal.fulfill_()
                    return
                }

                let stripMetadata = userCachedStatus.metadataStripping == .stripMetadata

                var newAttachment: AttachmentEntity?
                let attachmentGroup = DispatchGroup()
                attachmentGroup.enter()
                self.viewModel.coreDataContextProvider.performOnRootSavingContext { context in
                    fileData.contents.toAttachment(
                        context, fileName: fileData.name,
                        type: fileData.ext,
                        stripMetadata: stripMetadata,
                        isInline: false
                    ).done { attachment in
                        newAttachment = attachment
                        attachmentGroup.leave()
                    }
                }
                attachmentGroup.wait()

                guard let att = newAttachment else {
                    self.error(LocalString._cant_copy_the_file)
                    return
                }
                self.isAddingAttachment = true

                let group = DispatchGroup()
                group.enter()
                self.addAttachment(att) {
                    self.updateCurrentAttachmentSize(completion: {
                        group.leave()
                    })
                }
                group.wait()
                seal.fulfill_()
            }
        }
    }

    func error(_ description: String) {
        let alert = description.alertController()
        alert.addOKAction()
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }

    private func addAttachment(_ attachment: AttachmentEntity, completion: @escaping () -> Void) {
        viewModel.addAttachment(attachment.objectID)
        viewModel.user.usedSpace(plus: attachment.fileSize.int64Value)
        updateAttachmentView(completion: completion)
    }

    private func updateAttachmentView(completion: @escaping () -> Void) {
        viewModel.updateAttachmentOrders { [weak self] attachments in
            self?.updateAttachmentView(attachments, shouldUpload: true, completion: {
                completion()
            })
        }
    }

    private func updateAttachmentView(
        _ attachments: [AttachmentEntity],
        shouldUpload: Bool,
        completion: @escaping () -> Void
    ) {
        attachmentView.set(attachments: attachments) { [weak self] in
            let attachmentNumber = self?.attachmentView.attachmentCount ?? 0
            self?.updateAttachmentCount(number: attachmentNumber)

            guard shouldUpload else {
                completion()
                return
            }
            let number = self?.attachmentView.attachmentCount ?? 0
            self?.updateAttachmentCount(number: number)
            completion()
        }
    }

    private func sizeError() {
        DispatchQueue.main.async {
            let title = LocalString._attachment_limit
            let message = LocalString._the_total_attachment_size_cant_be_bigger_than_25mb
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addOKAction()
            self.present(alert, animated: true, completion: nil)
        }
    }
}

#if !APP_EXTENSION
extension ComposeContainerViewController: LifetimeTrackable {
}
#endif

// MARK: - Scheduled send related

extension ComposeContainerViewController: ScheduledSendHelperDelegate {
    func showScheduleSendPromotionView() {
        editor.collectDraftData().ensure { [weak self] in
            self?.viewModel.childViewModel.updateDraft()
            guard let nav = self?.navigationController?.view else {
                return
            }
            let promotion = ScheduleSendPromotionView()
            promotion.presentPaymentUpgradeView = { [weak self] in
                #if !APP_EXTENSION
                self?.presentPaymentView()
                #else
                // Close the share extension and open the draft in main app.
                if let msgID = self?.viewModel.childViewModel.composerMessageHelper.draft?.messageID,
                   let url = URL(string: "protonmail://\(msgID)") {
                    self?.editor.cancelAction()
                    _ = self?.editor.openURL(url)
                }
                #endif
            }
            promotion.viewWasDismissed = { [weak self] in
                self?.showScheduleSendActionSheet()
            }
            promotion.present(on: nav)
        }.cauterize()
    }

    func isItAPaidUser() -> Bool {
        return viewModel.user.isPaid
    }

#if !APP_EXTENSION
    private func presentPaymentView() {
        paymentsUI = PaymentsUI(
            payments: viewModel.user.payments,
            clientApp: .mail,
            shownPlanNames: Constants.shownPlanNames
        )
        paymentsUI?.showUpgradePlan(
            presentationType: .modal,
            backendFetch: true
        ) { _ in }
    }
#endif

    func showSendInTheFutureAlert() {
        let alert = LocalString._schedule_send_future_warning.alertController()
        alert.addOKAction()
        present(alert, animated: true)
    }

    func scheduledTimeIsSet(date: Date?) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        self.viewModel.allowScheduledSend { [weak self] isAllowed in
            guard let self = self else { return }
            MBProgressHUD.hide(for: self.view, animated: true)
            guard isAllowed else {
                NotificationCenter.default.post(name: .showScheduleSendUnavailable, object: nil)
                return
            }
            if let date = date {
                self.showScheduledSendConfirmAlert(date: date)
            } else {
                // Immediately send
                self.viewModel.sendAction(deliveryTime: nil)
                // TODO: move send action in editor into viewModel
                self.editor.sendAction(deliveryTime: nil)
            }
        }
    }

    private func showScheduledSendConfirmAlert(date: Date) {
        let timeTuple = PMDateFormatter.shared.titleForScheduledBanner(from: date)
        let message = String(format: LocalString._edit_scheduled_button_message,
                             timeTuple.0,
                             timeTuple.1)

        let title = LocalString._general_schedule_send_action
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: LocalString._general_confirm_action, style: .default) { [weak self] _ in
            self?.viewModel.sendAction(deliveryTime: date)
            // TODO: move send action in editor into viewModel
            self?.editor.sendAction(deliveryTime: date)
        }
        let cancelAction = UIAlertAction(title: LocalString._general_cancel_action, style: .cancel, handler: nil)
        [okAction, cancelAction].forEach(alert.addAction)
        self.present(alert, animated: true, completion: nil)
    }
}

extension ComposeContainerViewController {
    // TODO: Move logic into viewModel
    private func presentExpirationUnavailabilityAlert() {
        let nonPMEmails = editor.encryptionPassword.count <= 0 ? editor.headerView.nonePMEmails : [String]()
        let pgpEmails = editor.headerView.pgpEmails
        guard nonPMEmails.count > 0 || pgpEmails.count > 0 else {
            editor.validateDraftBeforeSending()
            return
        }
        editor.showExpirationUnavailabilityAlert(nonPMEmails: nonPMEmails, pgpEmails: pgpEmails)
    }

    // TODO: Move logic into viewModel
    private func presentGroupSubSelectionActionSheet() {
        guard let navVC = editor.navigationController,
              let group = editor.pickedGroup else {
            return
        }
        editor.groupSubSelectionPresenter = ContactGroupSubSelectionActionSheetPresenter(
            sourceViewController: navVC,
            user: viewModel.childViewModel.user,
            group: group,
            callback: editor.pickedCallback
        )
        editor.groupSubSelectionPresenter?.present()
    }
}

// MARK: - ComposerAttachmentVCDelegate

extension ComposeContainerViewController: ComposerAttachmentVCDelegate {
    func composerAttachmentViewController(
        _ composerVC: ComposerAttachmentVC,
        didDelete attachment: AttachmentEntity
    ) {
        editor.view.endEditing(true)
        header.view.endEditing(true)
        view.endEditing(true)
        _ = editor.attachments(deleted: attachment).done { [weak self] in
            let number = composerVC.attachmentCount
            self?.updateAttachmentCount(number: number)
            self?.updateCurrentAttachmentSize(completion: nil)
        }
    }
}

// MARK: - ComposePasswordDelegate

extension ComposeContainerViewController: ComposePasswordDelegate {
    func apply(password: String, confirmPassword: String, hint: String) {
        editor.encryptionPassword = password
        editor.encryptionConfirmPassword = confirmPassword
        editor.encryptionPasswordHint = hint
        editor.updateEO()
        setLockStatus(isLock: true)
    }

    func removedPassword() {
        editor.encryptionPassword = .empty
        editor.encryptionConfirmPassword = .empty
        editor.encryptionPasswordHint = .empty
        editor.updateEO()
        setLockStatus(isLock: false)
    }

    private func setLockStatus(isLock: Bool) {
        toolbar?.setLockStatus(isLock: isLock)
    }
}

// MARK: - ComposeExpirationDelegate

extension ComposeContainerViewController: ComposeExpirationDelegate {
    func update(expiration: TimeInterval) {
        header.expirationTimeInterval = expiration
        setExpirationStatus(isSetting: expiration > 0)
    }

    private func setExpirationStatus(isSetting: Bool) {
        toolbar?.setExpirationStatus(isSetting: isSetting)
    }
}

// MARK: - ComposeViewControllerDelegate

extension ComposeContainerViewController: ComposeContentViewControllerDelegate {
    func displayExpirationWarning() {
        presentExpirationUnavailabilityAlert()
    }

    func displayContactGroupSubSelectionView() {
        presentGroupSubSelectionActionSheet()
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol

extension ComposeContainerViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        self.bottomPadding?.constant = UIDevice.safeGuide.bottom + Constant.toolBarHeight
        self.toolbarBottom?.constant = -1 * UIDevice.safeGuide.bottom
    }

    func keyboardWillShowNotification(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            self.bottomPadding?.constant = keyboardFrame.cgRectValue.height + Constant.toolBarHeight
            self.toolbarBottom?.constant = -1 * keyboardFrame.cgRectValue.height
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
    }
}

// MARK: - ComposeContainerUIProtocol

extension ComposeContainerViewController: ComposeContainerUIProtocol {
    func updateSendButton() {
        self.setupTopRightBarButton()
    }
}
