//
//  MenuViewController.swift
//  ProtonMail
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
import CoreData
import PromiseKit

class MenuViewController: UIViewController, ViewModelProtocol, CoordinatedNew, AccessibleView {
    /// those two are optional
    typealias viewModelType = MenuViewModel
    typealias coordinatorType = MenuCoordinatorNew
    
    private(set) var viewModel : MenuViewModel!
    private var coordinator : MenuCoordinatorNew?
    
    func set(viewModel: MenuViewModel) {
        self.viewModel = viewModel
    }
    func set(coordinator: MenuCoordinatorNew) {
        self.coordinator = coordinator
    }
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
    
    // MARK - Views Outlets
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var snoozeButton: UIButton!
    
    @available(iOS 10.0, *)
    private lazy var notificationsSnoozer = NotificationsSnoozer()
    
    //
    private var signingOut: Bool                 = false
    
    // MARK: - Constants
    private let kMenuOptionsWidth: CGFloat       = 300.0 //227.0
    private let kMenuOptionsWidthOffset: CGFloat = 80.0
    private let kMenuTableCellId: String         = "menu_table_cell"
    private let kLabelTableCellId: String        = "menu_label_cell"
    private let kUserTableCellID: String         = "menu_user_cell"
    private let kButtonTableCellID: String       = "menu_button_cell"
    
    // temp vars
    private var sectionClicked : Bool  = false
    
    // 
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(viewModel != nil, "viewModel can't be empty")
        assert(coordinator != nil, "coordinator can't be empty")
        
        //table view delegates
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        //update rear view reveal width based on screen size
        self.updateRevealWidth()
        
        //setup labels fetch controller
        setupLabelsIfViewIsLoaded()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didPrimaryAccountLoggedOut(_:)),
                                               name: NSNotification.Name.didPrimaryAccountLogout,
                                               object: nil)
        
        generateAccessibilityIdentifiers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //update rear view reveal width based on screen size
        self.updateRevealWidth()
        
        ///TODO::fixme forgot the reason
        self.revealViewController().frontViewController.view.accessibilityElementsHidden = true
        self.view.accessibilityElementsHidden = false
        self.view.becomeFirstResponder()
        self.revealViewController().frontViewController.view.isUserInteractionEnabled = false
        self.revealViewController().view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        
        self.hideUsers()
        self.sectionClicked = false
        
        self.viewModel.updateMenuItems()
        
        updateEmailLabel()
        updateDisplayNameLabel()
        setupLabelsIfViewIsLoaded(shouldFetchLabels: false)
        self.tableView.reloadData()
        
        if #available(iOS 10.0, *), Constants.Feature.snoozeOn {
            self.setupSnoozeButton()
            self.snoozeButton.accessibilityHint = LocalString._double_tap_to_setup
        } else {
            self.snoozeButton.isHidden = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.revealViewController().frontViewController.view.isUserInteractionEnabled = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // TODO: refactor ReportBugsViewController to have Coordinator and properly inject this hunk
        if let reporter = (segue.destination as? UINavigationController)?.topViewController as? ReportBugsViewController {
            reporter.user = self.viewModel.currentUser
        }
        super.prepare(for: segue, sender: sender)
    }

    
    ///
    @IBAction func usersClicked(_ sender: Any) {
        let show = self.viewModel.showUsers()
        UIView.transition(with: tableView,
                          duration: 0.20,
                          options: .transitionCrossDissolve,
                          animations: {
                            self.tableView.backgroundColor = show ? .white : UIColor.ProtonMail.Menu_UnSelectBackground_Label
                            self.tableView.reloadData() })
    }
    
    func hideUsers(){
        self.viewModel.hideUsers()
        UIView.transition(with: tableView,
                          duration: 0.20,
                          options: .transitionCrossDissolve,
                          animations: {
                            self.tableView.backgroundColor = UIColor.ProtonMail.Menu_UnSelectBackground_Label
                            self.updateEmailLabel()
                            self.updateDisplayNameLabel()
                            self.tableView.reloadData() })
    }
    // MARK: - Methods
    
    func updateEmailLabel() {
        guard let user = self.viewModel.currentUser else {
            return
        }
        emailLabel.text = user.defaultEmail
    }
    
    func updateDisplayNameLabel() {
        guard let user = self.viewModel.currentUser else {
            return
        }
        let displayName = user.defaultDisplayName
        if !displayName.isEmpty {
            displayNameLabel.text = displayName
        } else {
            displayNameLabel.text = emailLabel.text
        }
    }
    func updateRevealWidth() {
        let w = UIScreen.main.bounds.width
        let offset =  (w - kMenuOptionsWidthOffset)
        self.revealViewController().rearViewRevealWidth = kMenuOptionsWidth > offset ? offset : kMenuOptionsWidth
    }
    
    func handleSignOut(_ sender : UIView?) {
        let shouldDeleteMessageInQueue = self.viewModel.isCurrentUserHasQueuedMessage()
        var message = LocalString._logout_confirmation
        
        if shouldDeleteMessageInQueue {
            message = LocalString._logout_confirmation_having_pending_message
        } else {
            if let user = self.viewModel.currentUser {
                if let nextUser = self.viewModel.secondUser {
                    message = String(format: LocalString._logout_confirmation, nextUser.defaultEmail)
                } else {
                    message = String(format: LocalString._logout_confirmation_one_account, user.defaultEmail)
                }
            }
        }
        
        let alertController = UIAlertController(title: LocalString._logout_title, message: message, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: LocalString._sign_out, style: .destructive, handler: { (action) -> Void in
            if shouldDeleteMessageInQueue {
                self.viewModel.removeAllQueuedMessageOfCurrentUser()
            }
            self.signingOut = true
            _ = self.viewModel.signOut()
            self.signingOut = false
        }))
        alertController.popoverPresentationController?.sourceView = sender ?? self.view
        alertController.popoverPresentationController?.sourceRect = (sender == nil ? self.view.frame : sender!.bounds)
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
        self.sectionClicked = false
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc fileprivate func didPrimaryAccountLoggedOut(_ notification: Notification) {
        guard self.viewModel.users.users.count > 0 else {
            return
        }
        self.viewModel.updateCurrent()
        setupLabelsIfViewIsLoaded()
        self.hideUsers()
        self.sectionClicked = false
        self.coordinator?.go(to: .mailbox)
    }
}

@available(iOS 10.0, *)
extension MenuViewController : OptionsDialogPresenter {
    func toSettings() {
        let deepLink = DeepLink(MenuCoordinatorNew.Destination.settings.rawValue)
        deepLink.append(.init(name: SettingsCoordinator.Destination.snooze.rawValue))
        self.coordinator?.follow(deepLink)
    }
    
    private func setupSnoozeButton(switchedOn: Bool? = nil) {
        self.snoozeButton.isSelected = switchedOn ?? self.notificationsSnoozer.isSnoozeActive(at: Date())
        self.snoozeButton.accessibilityLabel = self.snoozeButton.isSelected ? LocalString._notifications_are_snoozed : LocalString._notifications_snooze_off
    }
    
    @IBAction func presentQuickSnoozeOptions(sender: UIButton?) {
        let dialog = self.notificationsSnoozer.quickOptionsDialog(for: Date(), toPresentOn: self) { switchedOn in
            self.setupSnoozeButton(switchedOn: switchedOn)
        }
        self.present(dialog, animated: true, completion: nil)
    }
}

extension MenuViewController: UITableViewDelegate {
    
    func closeMenu() {
        self.revealViewController().revealToggle(animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.sectionCount()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.viewModel.cellHeight(at: indexPath.section)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.sectionClicked {
            return
        }
        self.sectionClicked = true
        let s = indexPath.section
        let row = indexPath.row
        let section = self.viewModel.section(at: s)
        switch section {
        case .inboxes:
            let obj = self.viewModel.item(inboxes: row).menuToLabel
            self.coordinator?.go(to: .mailbox, sender: obj)
        case .others:
            let item = self.viewModel.item(others: row)
            if item == .signout {
                tableView.deselectRow(at: indexPath, animated: true)
                let cell = tableView.cellForRow(at: indexPath)
                self.handleSignOut(cell)
            } else if item == .settings {
                self.coordinator?.go(to: .settings)
            } else if item == .bugs {
                self.coordinator?.go(to: .bugs)
            } else if item == .contacts {
                self.coordinator?.go(to: .contacts)
            } else if item == .feedback {
                //self.performSegue(withIdentifier: kSegueToFeedback, sender: indexPath)
            } else if item == .lockapp {
                keymaker.lockTheApp() // remove mainKey from memory
                let _ = sharedServices.get(by: UnlockManager.self).isUnlocked() // provoke mainKey obtaining
                self.sectionClicked = false
                self.closeMenu()
            } else if item == .servicePlan {
                self.coordinator?.go(to: .plan)
            }
        case .labels:
            let obj = self.viewModel.label(at: row)
            self.coordinator?.go(to: .label, sender: obj)
        case .users:
            // pick it as current user
            self.viewModel.updateCurrent(row: row)
            setupLabelsIfViewIsLoaded()
            self.hideUsers()
            self.sectionClicked = false
            self.coordinator?.go(to: .mailbox)
        case .disconnectedUsers:
            if let disConnectedUser = self.viewModel.disconnectedUser(at: row) {
                self.coordinator?.go(to: .addAccount, sender: disConnectedUser)
            }
            break
        case .accountManager:
            self.coordinator?.go(to: .accountManager)
        default:
            break
        }
    }
    
    func toInbox() {
        self.coordinator?.go(to: .mailbox, sender: MenuItem.inbox.menuToLabel)
    }

    func setupLabelsIfViewIsLoaded(shouldFetchLabels: Bool = true) {
        guard isViewLoaded else { return }
        viewModel.setupLabels(delegate: self, shouldFetchLabels: shouldFetchLabels)
    }
    
    func updateUser() {
        DispatchQueue.main.async(execute: { [weak self] in
            // pick it as current user
            self?.viewModel.updateCurrent()
            self?.setupLabelsIfViewIsLoaded()
            self?.hideUsers()
            self?.sectionClicked = false
            self?.tableView.reloadData()
            self?.coordinator?.go(to: .mailbox)
        })
    }
}

extension MenuViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = self.viewModel.section(at: section)
        switch section {
        case .inboxes:
            return self.viewModel.inboxesCount()
        case .others:
            return self.viewModel.othersCount()
        case .labels:
            return self.viewModel.labelsCount()
        case .users:
            return self.viewModel.usersCount
        case .disconnectedUsers:
            return self.viewModel.disconnectedUsersCount
        case .unknown:
            return 0
        case .accountManager:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let s = indexPath.section
        let row = indexPath.row
        let section = self.viewModel.section(at: s)
        
        let isLastSection = s == self.viewModel.sectionCount() - 1
        let isLastCell = row == self.tableView(tableView, numberOfRowsInSection: s) - 1
        let hideSepartor = isLastSection || !isLastCell
        
        switch section {
        case .inboxes:
            let cell = tableView.dequeueReusableCell(withIdentifier: kMenuTableCellId, for: indexPath) as! MenuTableViewCell
            let data = self.viewModel.item(inboxes: row)
            self.viewModel.count(by: data.menuToLabel.rawValue, userID: nil).done { (count) in
                cell.configUnreadCount(count: count)
            }.cauterize()
            cell.configCell(data, hideSepartor: hideSepartor)
            return cell
        case .others:
            let cell = tableView.dequeueReusableCell(withIdentifier: kMenuTableCellId, for: indexPath) as! MenuTableViewCell
            cell.configCell(self.viewModel.item(others: row), hideSepartor: hideSepartor)
            cell.hideCount()
            return cell
        case .labels:
            let cell = tableView.dequeueReusableCell(withIdentifier: kLabelTableCellId, for: indexPath) as! MenuLabelViewCell
            if let data = self.viewModel.label(at: row) {
                self.viewModel.count(by: data.labelID, userID: data.userID).done { (count) in
                    cell.configUnreadCount(count: count)
                }.cauterize()
                cell.configCell(data, hideSepartor: hideSepartor)
            }
            return cell
        case .users:
            let cell = tableView.dequeueReusableCell(withIdentifier: kUserTableCellID, for: indexPath) as! MenuUserViewCell
            if let user = self.viewModel.user(at: row) {
                cell.configCell(type: .LoggedIn, name: user.defaultDisplayName, email: user.defaultEmail)
                _ = user.getUnReadCount(by: Message.Location.inbox.rawValue).done { (count) in
                    cell.configUnreadCount(count: count)
                }
            }
            cell.hideSepartor(hideSepartor)
            return cell
        case .disconnectedUsers:
            let cell = tableView.dequeueReusableCell(withIdentifier: kUserTableCellID, for: indexPath) as! MenuUserViewCell
            if let disconnectedUser = self.viewModel.disconnectedUser(at: row) {
                let name = disconnectedUser.defaultDisplayName == "" ? disconnectedUser.defaultEmail : disconnectedUser.defaultDisplayName
                cell.configCell(type: .LoggedOut,
                                name: name,
                                email: disconnectedUser.defaultEmail)
            }
            cell.delegate = self
            cell.hideSepartor(hideSepartor)
            return cell
        case .accountManager:
            let cell = tableView.dequeueReusableCell(withIdentifier: kButtonTableCellID, for: indexPath) as! MenuButtonViewCell
            cell.configCell(LocalString._menu_manage_accounts, containsStackView: false, hideSepartor: false)
            return cell
        default:
            let cell: MenuTableViewCell = tableView.dequeueReusableCell(withIdentifier: kMenuTableCellId, for: indexPath) as! MenuTableViewCell
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let s = self.viewModel.section(at: section)
        switch s {
        case .users, .accountManager:
            return 0.5
        case .labels:
            return 0.0
        default:
            return 0.0
        }
    }
}

extension MenuViewController: MenuUserViewCellDelegate {
    func didClickedSignInButton(cell: MenuUserViewCell) {
        if let indexPath = self.tableView.indexPath(for: cell),
            let disConnectedUser = self.viewModel.disconnectedUser(at: indexPath.row) {
            self.coordinator?.go(to: .addAccount, sender: disConnectedUser)
        }
    }
}

extension MenuViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if !signingOut {
            tableView.endUpdates()
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if !signingOut {
            tableView.beginUpdates()
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        if !signingOut {
            switch(type) {
            case .delete:
                tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            case .insert:
                tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            default:
                return
            }
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any, at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if !signingOut {
            switch(type) {
            case .delete:
                if let indexPath = indexPath {
                    tableView.deleteRows(at: [IndexPath(row: indexPath.row, section: 2)], with: UITableView.RowAnimation.fade)
                }
            case .insert:
                if let newIndexPath = newIndexPath {
                    tableView.insertRows(at: [IndexPath(row: newIndexPath.row, section: 2)], with: UITableView.RowAnimation.fade)
                }
            case .move:
                if let indexPath = indexPath, let newIndexPath = newIndexPath {
                    if tableView.cellForRow(at: indexPath) != nil && tableView.cellForRow(at: newIndexPath) != nil {
                        tableView.moveRow(at: IndexPath(row: indexPath.row, section: 2), to: IndexPath(row: newIndexPath.row, section: 2))
                    }
                }
            case .update:
                if let indexPath = indexPath {
                    let index = IndexPath(row: indexPath.row, section: 2)
                    if let cell = tableView.cellForRow(at: index) as? MenuLabelViewCell {
                        if let data = self.viewModel.label(at: index.row) {
                            cell.configCell(data, hideSepartor: cell.separtor.isHidden)
                            self.viewModel.count(by: data.labelID, userID: nil).done { (count) in
                                cell.configUnreadCount(count: count)
                            }.cauterize()
                        }
                    }
                }
            @unknown default:
                break
            }
        }
    }
}

extension MenuViewController: Deeplinkable {
    var deeplinkNode: DeepLink.Node {
        return DeepLink.Node(name: String(describing: MenuViewController.self))
    }
}


extension MenuViewController: CoordinatedAlerts {
    func controller(notFount dest: String) {
        #if DEBUG
        let alertController = "can't open \(dest) ".alertController()
        alertController.addOKAction()
        self.present(alertController, animated: true, completion: nil)
        
        self.sectionClicked = false
        self.closeMenu()
        #endif
    }
}
