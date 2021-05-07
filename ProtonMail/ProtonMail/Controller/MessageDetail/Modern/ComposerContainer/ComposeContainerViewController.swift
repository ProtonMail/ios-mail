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
    
import PMUIFoundations
import UIKit

protocol ComposeContainerUIProtocol: AnyObject {
    func updateSendButton()
    func setLockStatus(isLock: Bool)
    func setExpirationStatus(isSetting: Bool)
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
    
    deinit {
        self.childrenHeightObservations = []
        NotificationCenter.default.removeKeyboardObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // fix ios 10 have a seperator at bottom
        self.tableView.separatorColor = .clear
        self.tableView.dropDelegate = self
        
        NotificationCenter.default.addKeyboardObserver(self)
        
        self.setupButtomPadding()
        self.configureNavigationBar()
        self.setupChildViewModel()
        self.setupToolbar()
        self.emptyBackButtonTitleForNextView()

        // accessibility
        generateAccessibilityIdentifiers()
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
        guard self.viewModel.childViewModel.showExpirationPicker && indexPath.row == 1 else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ExpirationPickerCell.self), for: indexPath) as? ExpirationPickerCell else {
            assert(false, "Broken expiration cell")
            return UITableViewCell()
        }
        
        self.coordinator.inject(cell.getPicker())
        cell.generateAccessibilityIdentifiers()
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
}

// MARK: UI related
extension ComposeContainerViewController {
    private func setupButtomPadding() {
        self.bottomPadding = self.view.bottomAnchor.constraint(equalTo: self.tableView.bottomAnchor)
        self.bottomPadding.constant = 0.0
        self.bottomPadding.isActive = true
    }
    
    private func setupChildViewModel() {
        let childViewModel = self.viewModel.childViewModel
        let header = self.coordinator.createHeader(childViewModel)
        self.coordinator.createEditor(childViewModel)

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
            childViewModel.observe(\.showExpirationPicker) { [weak self] viewModel, _ in
                // TODO: this index is hardcoded position of expiration view, not flexible approach. Fix when decoupling Header and ExpirationPicker from old ComposeViewController
                self?.tableView.reloadRows(at: [IndexPath.init(row: 1, section: 0)], with: .fade)
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
    
    private func error(_ description: String) {
        let alert = description.alertController()
        alert.addOKAction()
        self.present(alert, animated: true, completion: nil)
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
}

extension ComposeContainerViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        self.bottomPadding.constant = 0.0
        self.toolbarBottom.constant = -1 * UIDevice.safeGuide.bottom
    }
    
    func keyboardWillShowNotification(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            self.bottomPadding.constant = keyboardFrame.cgRectValue.height
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
            LocalString._importing_drop.alertToastBottom()
        }
        
        let itemProviders = coordinator.items.map { $0.dragItem.itemProvider }
        self.viewModel.importFiles(from: itemProviders, errorHandler: self.error) {
            DispatchQueue.main.async {
                LocalString._drop_finished.alertToastBottom()
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
        self.view.endEditing(true)
    }
}

class ExpirationPickerCell: UITableViewCell, AccessibleView {
    @IBOutlet private var picker: UIPickerView!
    
    func getPicker() -> UIPickerView {
        return self.picker
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
