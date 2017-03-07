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
    internal static let ObserverSwitchView:String = "Push_Switch_View"
    
    // MARK - Views Outlets
    
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var headerView: UIView!
    
    // MARK: - Private constants
    
    fileprivate let inboxItems : [MenuItem] = [.inbox, .drafts, .sent, .starred, .archive, .spam, .trash, .allmail]
    fileprivate var otherItems : [MenuItem] = [.contacts, .settings, .bugs, /*MenuItem.feedback,*/ .signout]
    fileprivate var fetchedLabels: NSFetchedResultsController<NSFetchRequestResult>?
    fileprivate var signingOut: Bool = false
    
    fileprivate let kMenuCellHeight: CGFloat = 44.0
    fileprivate let kMenuOptionsWidth: CGFloat = 300.0 //227.0
    fileprivate let kMenuOptionsWidthOffset: CGFloat = 80.0
    
    fileprivate let kSegueToMailbox: String = "toMailboxSegue"
    fileprivate let kSegueToLabelbox: String = "toLabelboxSegue"
    fileprivate let kSegueToSettings: String = "toSettingsSegue"
    fileprivate let kSegueToBugs: String = "toBugsSegue"
    fileprivate let kSegueToContacts: String = "toContactsSegue"
    fileprivate let kSegueToFeedback: String = "toFeedbackSegue"
    fileprivate let kMenuTableCellId = "menu_table_cell"
    fileprivate let kLabelTableCellId = "menu_label_cell"
    
    // temp vars
    fileprivate var lastSegue: String = "toMailboxSegue"
    fileprivate var lastMenuItem: MenuItem = MenuItem.inbox
    fileprivate var sectionClicked : Bool = false
    
    // private data
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    deinit{
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: MenuViewController.ObserverSwitchView), object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFetchedResultsController()
        
        let w = UIScreen.main.applicationFrame.width;
        let offset =  (w - kMenuOptionsWidthOffset)
        self.revealViewController().rearViewRevealWidth = kMenuOptionsWidth > offset ? offset : kMenuOptionsWidth
        
        tableView.dataSource = self
        tableView.delegate = self
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(MenuViewController.performLastSegue(_:)),
            name: NSNotification.Name(rawValue: MenuViewController.ObserverSwitchView),
            object: nil)
        
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.layoutMargins = UIEdgeInsets.zero
        
        sharedLabelsDataService.fetchLabels();
    }
    
    func performLastSegue(_ notification: Notification)
    {
        self.performSegue(withIdentifier: lastSegue, sender: IndexPath(row: 0, section: 0))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let w = UIScreen.main.applicationFrame.width;
        let offset =  (w - kMenuOptionsWidthOffset)
        self.revealViewController().rearViewRevealWidth = kMenuOptionsWidth > offset ? offset : kMenuOptionsWidth
        
        self.revealViewController().frontViewController.view.isUserInteractionEnabled = false
        self.revealViewController().view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        
        self.sectionClicked = false
        
        if ((userCachedStatus.isPinCodeEnabled && !userCachedStatus.pinCode.isEmpty) || (!userCachedStatus.touchIDEmail.isEmpty && userCachedStatus.isTouchIDEnabled)) {
            otherItems = [.contacts, .settings, .bugs, /*MenuItem.feedback,*/ .lockapp, .signout]
        } else {
            otherItems = [MenuItem.contacts, MenuItem.settings, MenuItem.bugs, /*MenuItem.feedback,*/ MenuItem.signout]
        }
        
        
        updateEmailLabel()
        updateDisplayNameLabel()
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.revealViewController().frontViewController.view.isUserInteractionEnabled = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navigationController = segue.destination as! UINavigationController
        if let firstViewController: UIViewController = navigationController.viewControllers.first as UIViewController? {
            if (firstViewController.isKind(of: MailboxViewController.self)) {
                let mailboxViewController: MailboxViewController = navigationController.viewControllers.first as! MailboxViewController
                if let indexPath = sender as? IndexPath {
                    PMLog.D("Menu Table Clicked -- Done")
                    if indexPath.section == 0 {
                        self.lastMenuItem = self.itemForIndexPath(indexPath)
                        mailboxViewController.viewModel = MailboxViewModelImpl(location: self.lastMenuItem.menuToLocation)
                    } else if indexPath.section == 1 {
                    } else if indexPath.section == 2 {
                        //if indexPath.row < fetchedLabels?.fetchedObjects?.count {
                        let label = self.fetchedLabels?.object(at: IndexPath(row: indexPath.row, section: 0)) as! Label
                        mailboxViewController.viewModel = LabelboxViewModelImpl(label: label)
                        //}
                    } else {
                    }
                }
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        PMLog.D("Menu Table Clicked -- Checked")
        return true
    }
    
    // MARK: - Methods
    fileprivate func setupFetchedResultsController() {
        self.fetchedLabels = sharedLabelsDataService.fetchedResultsController(.all)
        self.fetchedLabels?.delegate = self
        PMLog.D("INFO: \(String(describing: fetchedLabels?.sections))")
        if let fetchedResultsController = fetchedLabels {
            do {
                try fetchedResultsController.performFetch()
            } catch let ex as NSError {
                PMLog.D("error: \(ex)")
            }
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    func handleSignOut(_ sender : UIView?) {
        let alertController = UIAlertController(title: NSLocalizedString("Confirm"), message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Sign Out"), style: .destructive, handler: { (action) -> Void in
            self.signingOut = true
            UserTempCachedStatus.backup()
            sharedUserDataService.signOut(true)
            userCachedStatus.signOut()
        }))
        alertController.popoverPresentationController?.sourceView = sender ?? self.view
        alertController.popoverPresentationController?.sourceRect = (sender == nil ? self.view.frame : sender!.bounds)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .cancel, handler: nil))
        self.sectionClicked = false
        present(alertController, animated: true, completion: nil)
    }
    
    func itemForIndexPath(_ indexPath: IndexPath) -> MenuItem {
        return inboxItems[indexPath.row]
    }
    
    func updateDisplayNameLabel() {
        let displayName = sharedUserDataService.defaultDisplayName
        if !displayName.isEmpty {
            displayNameLabel.text = displayName
            return
        }
        displayNameLabel.text = emailLabel.text
    }
    
    func updateEmailLabel() {
        emailLabel.text = sharedUserDataService.defaultEmail;
    }
}

extension MenuViewController: UITableViewDelegate {
    
    func closeMenu() {
        self.revealViewController().revealToggle(animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return kMenuCellHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if !self.sectionClicked {
            self.sectionClicked = true
        } else {
            return
        }
        
        PMLog.D("Menu Table Clicked")
        if indexPath.section == 0 { //inbox
            self.performSegue(withIdentifier: kSegueToMailbox, sender: indexPath);
        } else if (indexPath.section == 1) {
            //others
            let item = otherItems[indexPath.row]
            if item == .signout {
                tableView.deselectRow(at: indexPath, animated: true)
                let cell = tableView.cellForRow(at: indexPath)
                self.handleSignOut(cell)
            } else if item == .settings {
                self.performSegue(withIdentifier: kSegueToSettings, sender: indexPath);
            } else if item == .bugs {
                self.performSegue(withIdentifier: kSegueToBugs, sender: indexPath);
            } else if item == .contacts {
                self.performSegue(withIdentifier: kSegueToContacts, sender: indexPath);
            } else if item == .feedback {
                self.performSegue(withIdentifier: kSegueToFeedback, sender: indexPath);
            } else if item == .lockapp {
                userCachedStatus.lockedApp = true;
                (UIApplication.shared.delegate as! AppDelegate).switchTo(storyboard: .signIn, animated: true)
                sharedVMService.resetComposerView()
            }
        } else if (indexPath.section == 2) {
            //labels
            self.performSegue(withIdentifier: kSegueToLabelbox, sender: indexPath);
        }
    }
}

extension MenuViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return inboxItems.count
        } else if (section == 1) {
            return otherItems.count
        } else if (section == 2) {
            let count = fetchedLabels?.numberOfRowsInSection(0) ?? 0
            return count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: kMenuTableCellId, for: indexPath) as! MenuTableViewCell
            cell.configCell(inboxItems[indexPath.row])
            cell.configUnreadCount()
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: kMenuTableCellId, for: indexPath) as! MenuTableViewCell
            cell.configCell(otherItems[indexPath.row])
            cell.hideCount()
            return cell
        } else if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: kLabelTableCellId, for: indexPath) as! MenuLabelViewCell
            if  fetchedLabels?.fetchedObjects?.count ?? 0 > indexPath.row {
                if let data = fetchedLabels?.object(at: IndexPath(row: indexPath.row, section: 0)) as? Label {
                    cell.configCell(data)
                    cell.configUnreadCount()
                }
            }
            return cell
        } else {
            let cell: MenuTableViewCell = tableView.dequeueReusableCell(withIdentifier: kMenuTableCellId, for: indexPath) as! MenuTableViewCell
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.0
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
                    tableView.deleteRows(at: [IndexPath(row: indexPath.row, section: 2)], with: UITableViewRowAnimation.fade)
                }
            case .insert:
                if let newIndexPath = newIndexPath {
                    tableView.insertRows(at: [IndexPath(row: newIndexPath.row, section: 2)], with: UITableViewRowAnimation.fade)
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
                        if  fetchedLabels?.fetchedObjects?.count ?? 0 > indexPath.row {
                            if let label = fetchedLabels?.object(at: indexPath) as? Label {
                                cell.configCell(label);
                                cell.configUnreadCount()
                            }
                        }
                    }
                }
            }
        }
    }
}
