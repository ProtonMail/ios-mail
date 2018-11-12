//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import UIKit
import CoreData


class MenuViewController: UIViewController {
    
    // MARK - Views Outlets
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var snoozeButton: UIButton!
    
    // MARK: - Private constants
    //here need to change to set by view model factory
    fileprivate let viewModel : MenuViewModel! = MenuViewModelImpl()
    
    @available(iOS 10.0, *)
    fileprivate lazy var notificationsSnoozer = NotificationsSnoozer()
    
    //
    fileprivate var signingOut: Bool                 = false
    
    fileprivate let kMenuCellHeight: CGFloat         = 44.0
    fileprivate let kMenuOptionsWidth: CGFloat       = 300.0 //227.0
    fileprivate let kMenuOptionsWidthOffset: CGFloat = 80.0
    
    fileprivate let kSegueToMailbox: String   = "toMailboxSegue"
    fileprivate let kSegueToLabelbox: String  = "toLabelboxSegue"
    internal let kSegueToSettings: String  = "toSettingsSegue"
    fileprivate let kSegueToBugs: String      = "toBugsSegue"
    fileprivate let kSegueToContacts: String  = "toContactsSegue"
    fileprivate let kSegueToFeedback: String  = "toFeedbackSegue"
    fileprivate let kMenuTableCellId: String  = "menu_table_cell"
    fileprivate let kLabelTableCellId: String = "menu_label_cell"
    
    // temp vars
    fileprivate var lastSegue: String      = "toMailboxSegue"
    fileprivate var lastMenuItem: MenuItem = .inbox
    fileprivate var sectionClicked : Bool  = false
    
    // private data
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    deinit{
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setup labels fetch controller
        self.viewModel.setupLabels(delegate: self)
        
        //setup rear view reveal width based on screen size
        self.updateRevealWidth()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(MenuViewController.performLastSegue(_:)),
            name: .switchView,
            object: nil)

        sharedLabelsDataService.fetchLabels()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateRevealWidth()
        
        self.revealViewController().frontViewController.view.accessibilityElementsHidden = true
        self.view.accessibilityElementsHidden = false
        self.view.becomeFirstResponder()
        
        self.revealViewController().frontViewController.view.isUserInteractionEnabled = false
        self.revealViewController().view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        
        self.sectionClicked = false
        
        self.viewModel.setupMenu()
        
        updateEmailLabel()
        updateDisplayNameLabel()
        tableView.reloadData()
        
        if #available(iOS 10.0, *), AppVersion.current >= NotificationsSnoozer.appVersion {
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
    
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        return true
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        segue.destination.view.accessibilityElementsHidden = false
        self.view.accessibilityElementsHidden = true
        
        // TODO: this deeplink implementation is ugly, consider using Coordinators pattern
        if #available(iOS 10.0, *),
            sender is NotificationsSnoozer,
            let navigation = segue.destination as? UINavigationController,
            let settings = navigation.topViewController as? SettingTableViewController
        {
            settings.performSegue(withIdentifier: settings.kNotificationsSnoozeSegue, sender: sender)
        }
        
        
        
        if let navigation = segue.destination as? UINavigationController {
            let segueID = segue.identifier
            //right now all mailbox view controller all could process together.
            if let mailbox: MailboxViewController = navigation.firstViewController() as? MailboxViewController {
                if let indexPath = sender as? IndexPath {
                    let s = indexPath.section
                    let row = indexPath.row
                    let section = self.viewModel.section(at: s)
                    switch section {
                    case .inboxes:
                        self.lastMenuItem = self.viewModel.item(inboxes: row)
                        sharedVMService.mailbox(fromMenu: mailbox, location: self.lastMenuItem.menuToLocation)
                    case .labels:
                        if  let label = self.viewModel.label(at: row) {
                            sharedVMService.labelbox(fromMenu: mailbox, label: label)
                        }
                    default:
                        break
                    }
                }
            } else if (segueID == kSegueToContacts ) {
                // setup contact group view controller
                if let tabBarController = navigation.firstViewController() as? UITabBarController,
                    let viewControllers = tabBarController.viewControllers {
                    if let contactViewController = viewControllers[0] as? ContactsViewController {
                        sharedVMService.contactsViewModel(contactViewController)
                    }
                    
                    if let contactGroupsViewController = viewControllers[1] as? ContactGroupsViewController {
                        sharedVMService.contactGroupsViewModel(contactGroupsViewController)
                    }
                }
            }
        } else if let tabBarController = segue.destination as? UITabBarController,
            let viewControllers = tabBarController.viewControllers {
            if let contactNavigation = viewControllers[0] as? UINavigationController,
                let contactViewController = contactNavigation.firstViewController() as? ContactsViewController {
                sharedVMService.contactsViewModel(contactViewController)
            }
            
            if let contactGroupNavigation = viewControllers[1] as? UINavigationController,
                let contactGroupsViewController = contactGroupNavigation.firstViewController() as? ContactGroupsViewController {
                sharedVMService.contactGroupsViewModel(contactGroupsViewController)
            }
        }
    }
    
    // MARK: - Methods
    func updateDisplayNameLabel() {
        let displayName = sharedUserDataService.defaultDisplayName
        if !displayName.isEmpty {
            displayNameLabel.text = displayName
        } else {
            displayNameLabel.text = emailLabel.text
        }
    }
    
    func updateEmailLabel() {
        emailLabel.text = sharedUserDataService.defaultEmail
    }
    
    func updateRevealWidth() {
        let w = UIScreen.main.bounds.width
        let offset =  (w - kMenuOptionsWidthOffset)
        self.revealViewController().rearViewRevealWidth = kMenuOptionsWidth > offset ? offset : kMenuOptionsWidth
    }
    
    func handleSignOut(_ sender : UIView?) {
        let alertController = UIAlertController(title: LocalString._general_confirm_action, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: LocalString._sign_out, style: .destructive, handler: { (action) -> Void in
            self.signingOut = true
            UserTempCachedStatus.backup()
            sharedUserDataService.signOut(true)
            userCachedStatus.signOut()
        }))
        alertController.popoverPresentationController?.sourceView = sender ?? self.view
        alertController.popoverPresentationController?.sourceRect = (sender == nil ? self.view.frame : sender!.bounds)
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
        self.sectionClicked = false
        present(alertController, animated: true, completion: nil)
    }
    
    //@objc for #seclector()
    @objc func performLastSegue(_ notification: Notification) {
        if let nextTo = notification.object as? MenuItem {
            if nextTo == .servicePlan {
                let coordinator = MenuCoordinator()
                coordinator.controller = self
                coordinator.go(to: .serviceLevel, creating: ServiceLevelViewController.self)
                return
            }
        }
        self.performSegue(withIdentifier: lastSegue, sender: IndexPath(row: 0, section: 0))
    }
}

@available(iOS 10.0, *)
extension MenuViewController {
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
        return kMenuCellHeight
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
            self.performSegue(withIdentifier: kSegueToMailbox, sender: indexPath)
        case .others:
            let item = self.viewModel.item(others: row)
            if item == .signout {
                tableView.deselectRow(at: indexPath, animated: true)
                let cell = tableView.cellForRow(at: indexPath)
                self.handleSignOut(cell)
            } else if item == .settings {
                self.performSegue(withIdentifier: kSegueToSettings, sender: indexPath)
            } else if item == .bugs {
                self.performSegue(withIdentifier: kSegueToBugs, sender: indexPath)
            } else if item == .contacts {
                self.performSegue(withIdentifier: kSegueToContacts, sender: indexPath)
            } else if item == .feedback {
                self.performSegue(withIdentifier: kSegueToFeedback, sender: indexPath)
            } else if item == .lockapp {
                keymaker.lockTheApp() // remove mainKey from memory
                let _ = keymaker.mainKey // provoke mainKey obtaining
                sharedVMService.resetView() // FIXME: do we still need this?
            } else if item == .servicePlan {
                let coordinator = MenuCoordinator()
                coordinator.controller = self
                coordinator.go(to: .serviceLevel, creating: ServiceLevelViewController.self)
            }
        case .labels:
            self.performSegue(withIdentifier: kSegueToLabelbox, sender: indexPath)
        default:
            break
        }
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
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let s = indexPath.section
        let row = indexPath.row
        let section = self.viewModel.section(at: s)
        switch section {
        case .inboxes:
            let cell = tableView.dequeueReusableCell(withIdentifier: kMenuTableCellId, for: indexPath) as! MenuTableViewCell
            cell.configCell(self.viewModel.item(inboxes: row))
            cell.configUnreadCount()
            return cell
        case .others:
            let cell = tableView.dequeueReusableCell(withIdentifier: kMenuTableCellId, for: indexPath) as! MenuTableViewCell
            cell.configCell(self.viewModel.item(others: row))
            cell.hideCount()
            return cell
        case .labels:
            let cell = tableView.dequeueReusableCell(withIdentifier: kLabelTableCellId, for: indexPath) as! MenuLabelViewCell
            if let data = self.viewModel.label(at: row) {
                cell.configCell(data)
                cell.configUnreadCount()
            }
            return cell
        default:
            let cell: MenuTableViewCell = tableView.dequeueReusableCell(withIdentifier: kMenuTableCellId, for: indexPath) as! MenuTableViewCell
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let s = self.viewModel.section(at: section)
        switch s {
        case .labels:
            return 0.0
        default:
            return 1.0
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
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
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
                if let indexPath = indexPath {
                    if let newIndexPath = newIndexPath {
                        tableView.moveRow(at: IndexPath(row: indexPath.row, section: 2), to: IndexPath(row: newIndexPath.row, section: 2))
                    }
                }
            case .update:
                if let indexPath = indexPath {
                    let index = IndexPath(row: indexPath.row, section: 2)
                    if let cell = tableView.cellForRow(at: index) as? MenuLabelViewCell {
                        if let data = self.viewModel.label(at: index.row) {
                            cell.configCell(data)
                            cell.configUnreadCount()
                        }
                    }
                }
            }
        }
    }
}
