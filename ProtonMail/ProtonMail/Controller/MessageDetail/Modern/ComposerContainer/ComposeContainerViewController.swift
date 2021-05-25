//
//  ComposingViewController.swift
//  ProtonMail - Created on 12/04/2019.
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

import AwaitKit
import PromiseKit
import ProtonCore_UIFoundations
import UIKit

protocol ComposeContainerUIProtocol: AnyObject {
    func updateSendButton()
    func setLockStatus(isLock: Bool)
    func setExpirationStatus(isSetting: Bool)
    func updateAttachmentCount(number: Int)
    func updateCurrentAttachmentSize()
}

class ComposeContainerViewController: TableContainerViewController<ComposeContainerViewModel, ComposeContainerViewCoordinator>
{
    private var childrenHeightObservations: [NSKeyValueObservation]!
    private var cancelButton: UIBarButtonItem!
    private var sendButton: UIBarButtonItem!
    private var bottomPadding: NSLayoutConstraint!
    private var dropLandingZone: UIView? // drag and drop session items dropped on this view will be added as attachments
    private let timerInterval : TimeInterval = 30
    private var syncTimer: Timer?
    private var toolbarBottom: NSLayoutConstraint!
    private var toolbar: ComposeToolbar!
    private var isAddingAttachment: Bool = false
    /// MARK: Attachment variables
    let kDefaultAttachmentFileSize: Int = 25 * 1_000 * 1_000 // 25 mb
    private(set) var currentAttachmentSize: Int = 0
    lazy private(set) var attachmentProcessQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    lazy private(set) var attachmentProviders: [AttachmentProvider] = { [unowned self] in
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
    
    deinit {
        self.childrenHeightObservations = []
        NotificationCenter.default.removeKeyboardObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = .white
        // fix ios 10 have a seperator at bottom
        self.tableView.separatorColor = .clear
        self.tableView.dropDelegate = self
        
        NotificationCenter.default.addKeyboardObserver(self)
        
        self.setupButtomPadding()
        self.configureNavigationBar()
        self.setupChildViewModel()
        self.setupToolbar()
        self.emptyBackButtonTitleForNextView()
        let childVM = self.viewModel.childViewModel
        if childVM.shareOverLimitationAttachment {
            self.sizeError(0)
        }

        // accessibility
        generateAccessibilityIdentifiers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let attachmentView = self.coordinator.attachmentView {
            attachmentView.addNotificationObserver()
        }
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopAutoSync()
        
        guard let vcCounts = self.navigationController?.viewControllers.count else {
            return
        }
        if vcCounts == 1 {
            // Composer dismiss
            self.coordinator.attachmentView?.removeNotificationObserver()
        }
    }
    
    override func configureNavigationBar() {
        super.configureNavigationBar()
        
        self.navigationController?.navigationBar.barTintColor = UIColorManager.BackgroundNorm
        self.navigationController?.navigationBar.isTranslucent = false
        
        self.setupSendButton()
        self.setupCancelButton()
    }
    
    // tableView
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        cell.backgroundColor = .white
        return cell
    }
    
    /// MARK: IBAction
    @objc
    func cancelAction(_ sender: UIBarButtonItem) {
        // FIXME: that logic should be in VM of EditorViewController
        self.coordinator.cancelAction(sender)
    }

    @objc
    func sendAction(_ sender: UIBarButtonItem) {
        // FIXME: that logic should be in VM of EditorViewController
        self.coordinator.sendAction(sender)
    }
    
    #if APP_EXTENSION
    func getSharedFiles() {
        self.isAddingAttachment = true
    }
    #endif
}

// MARK: UI related
extension ComposeContainerViewController {
    private func setupButtomPadding() {
        self.bottomPadding = self.view.bottomAnchor.constraint(equalTo: self.tableView.bottomAnchor)
        self.bottomPadding.constant = 50.0
        self.bottomPadding.isActive = true
    }
    
    private func setupChildViewModel() {
        let childViewModel = self.viewModel.childViewModel
        let header = self.coordinator.createHeader(childViewModel)
        self.coordinator.createEditor(childViewModel)
        let attachmentView = self.coordinator.createAttachmentView(childViewModel: childViewModel)

        self.childrenHeightObservations = [
            childViewModel.observe(\.contentHeight) { [weak self] _, _ in
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
                self?.tableView.beginUpdates()
                self?.tableView.endUpdates()
                guard self?.isAddingAttachment ?? false else { return }
                self?.isAddingAttachment = false
                // A bit of delay can get real contentSize
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    var yOffset: CGFloat = 0
                    let contentHieht = self?.tableView.contentSize.height ?? 0
                    let sizeHeight = self?.tableView.bounds.size.height ?? 0
                    if contentHieht > sizeHeight {
                        yOffset = contentHieht - sizeHeight
                    }

                    self?.tableView.setContentOffset(CGPoint(x: 0, y: yOffset), animated: false)
                }
            }
        ]
    }
    
    private func setupSendButton() {
        guard let icon = UIImage(named: "menu_sent") else {
            return
        }
        
        if self.viewModel.hasRecipients() {
            self.sendButton = icon.toUIBarButtonItem(target: self,
                                   action: #selector(sendAction),
                                   style: .plain,
                                   tintColor: UIColorManager.IconInverted,
                                   squareSize: 21.74,
                                   backgroundColor: UIColorManager.InteractionStrong,
                                   backgroundSquareSize: 40,
                                   isRound: true)
        } else {
            self.sendButton = icon.toUIBarButtonItem(target: self,
                                   action: nil,
                                   style: .plain,
                                   tintColor: UIColorManager.IconDisabled,
                                   squareSize: 21.74,
                                   backgroundColor: UIColorManager.InteractionWeakDisabled,
                                   backgroundSquareSize: 40,
                                   isRound: true)
        }
        self.navigationItem.rightBarButtonItem = self.sendButton
        self.sendButton.accessibilityLabel = LocalString._general_send_action
    }
    
    private func setupCancelButton() {
        let icon = UIImage(named: "action_sheet_close")
        self.cancelButton = UIBarButtonItem(image: icon, style: .plain, target: self, action: #selector(cancelAction))
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
        self.toolbarBottom = bar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -1*UIDevice.safeGuide.bottom)
        self.toolbarBottom.isActive = true
        self.toolbar = bar
    }
    
    private func startAutoSync() {
        self.stopAutoSync()
        self.syncTimer = Timer.scheduledTimer(withTimeInterval: self.timerInterval, repeats: true, block: { [weak self](_) in
            self?.viewModel.syncMailSetting()
        })
    }
    
    private func stopAutoSync() {
        self.syncTimer?.invalidate()
        self.syncTimer = nil
    }
}

extension ComposeContainerViewController: ComposeContainerUIProtocol {
    func updateSendButton() {
        self.setupSendButton()
    }

    func setLockStatus(isLock: Bool) {
        self.toolbar.setLockStatus(isLock: isLock)
    }

    func setExpirationStatus(isSetting: Bool) {
        self.toolbar.setExpirationStatus(isSetting: isSetting)
    }
    
    func updateAttachmentCount(number: Int) {
        DispatchQueue.main.async {
            self.toolbar.setAttachment(number: number)
        }
    }
    
    func updateCurrentAttachmentSize() {
        self.currentAttachmentSize = self.coordinator.getAttachmentSize()
    }
}

extension ComposeContainerViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        self.bottomPadding.constant = 50.0
        self.toolbarBottom.constant = -1 * UIDevice.safeGuide.bottom
    }
    
    func keyboardWillShowNotification(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            self.bottomPadding.constant = keyboardFrame.cgRectValue.height + 10
            self.toolbarBottom.constant = -1 * keyboardFrame.cgRectValue.height
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
            
        }
    }
}

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
            dropFrame.size.height = self.coordinator.headerFrame().size.height
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

extension ComposeContainerViewController: ComposeToolbarDelegate {
    func showEncryptOutsideView() {
        self.view.endEditing(true)
        self.coordinator.navigateToPassword()
    }
    
    func showExpireView() {
        self.view.endEditing(true)
        self.coordinator.navigateToExpiration()
    }
    
    func showAttachmentView() {
        self.coordinator.header.view.endEditing(true)
        self.coordinator.editor.view.endEditing(true)
        self.view.endEditing(true)
        
        var sheet: PMActionSheet!
        // FIXME: use asset
        let left = PMActionSheetPlainItem(title: nil, icon: UIImage(named: "action_sheet_close")) { (_) -> (Void) in
            sheet.dismiss(animated: true)
        }

        let header = PMActionSheetHeaderView(title: LocalString._menu_add_attachment, subtitle: nil, leftItem: left, rightItem: nil, hasSeparator: false)
        let itemGroup = self.getActionSheetItemGroup()
        sheet = PMActionSheet(headerView: header, itemGroups: [itemGroup], showDragBar: false)
        let viewController = self.navigationController ?? self
        sheet.presentAt(viewController, animated: true)
    }
    
    private func getActionSheetItemGroup() -> PMActionSheetItemGroup {
        let items: [PMActionSheetItem] = self.attachmentProviders.map(\.actionSheetItem)
        let itemGroup = PMActionSheetItemGroup(items: items, style: .clickable)
        return itemGroup
    }
}

extension ComposeContainerViewController: AttachmentController {
    func fileSuccessfullyImported(as fileData: FileData) -> Promise<Void> {
        return Promise { seal in
            self.attachmentProcessQueue.addOperation {
                let size = fileData.contents.dataSize
                
                guard size < (self.kDefaultAttachmentFileSize - self.currentAttachmentSize) else {
                    self.sizeError(0)
                    PMLog.D(" Size too big Orig: \(size) -- Limit: \(self.kDefaultAttachmentFileSize)")
                    seal.fulfill_()
                    return
                }
                
                guard let message = self.coordinator.editor.viewModel.message,
                      message.managedObjectContext != nil else {
                    PMLog.D(" Error during copying size incorrect")
                    self.error(LocalString._system_cant_copy_the_file)
                    seal.fulfill_()
                    return
                }
                
                let stripMetadata = userCachedStatus.metadataStripping == .stripMetadata
                
                let attachment = try? `await`(fileData.contents.toAttachment(message, fileName: fileData.name, type: fileData.ext, stripMetadata: stripMetadata))
                guard let att = attachment else {
                    PMLog.D(" Error during copying size incorrect")
                    self.error(LocalString._cant_copy_the_file)
                    return
                }
                self.isAddingAttachment = true
                self.coordinator.addAttachment(att)
                self.updateCurrentAttachmentSize()
                seal.fulfill_()
            }
        }
    }
    
    var barItem: UIBarButtonItem? {
        nil
    }
    
    func error(_ description: String) {
        let alert = description.alertController()
        alert.addOKAction()
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func sizeError(_ size: Int) {
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
extension ComposeContainerViewController: Deeplinkable {
    var deeplinkNode: DeepLink.Node {
        return DeepLink.Node(name: String(describing: ComposeContainerViewController.self),
                             value: self.viewModel.childViewModel.message?.messageID)
    }
}
#endif
