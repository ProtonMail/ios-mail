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

class MenuViewController: UIViewController {
    internal static let ObserverSwitchView:String = "Push_Switch_View"
    
    // MARK - Views Outlets
    
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    
    // MARK: - Private constants
    
    private let items = [MenuItem.inbox, MenuItem.starred, MenuItem.drafts, MenuItem.sent, MenuItem.archive, MenuItem.trash, MenuItem.spam, MenuItem.contacts, MenuItem.settings, MenuItem.bugs, MenuItem.signout]
    private let kMenuCellHeight: CGFloat = 48.0
    private let kMenuOptionsWidth: CGFloat = 300.0 //227.0
    private let kMenuOptionsWidthOffset: CGFloat = 80.0
    
//    private let kSegueToBugs: String = "toBugs"
//    private let kSegueToInbox: String = "toInbox"
//    private let kSegueToStarred: String = "toStarred"
//    private let kSegueToDrafts: String = "toDrafts"
//    private let kSegueToSent: String = "toSent"
//    private let kSegueToTrash: String = "toTrash"
//    private let kSegueToSpam: String = "toSpam"
    private let kSegueToMailbox: String = "toMailboxSegue"
    private let kSegueToSettings: String = "toSettingsSegue"
    
    private var kLastSegue: String = "toInbox"
    private var kLastMenuItem: MenuItem = MenuItem.inbox
    
    private let kMenuTableCellId = "menu_table_cell"
    private let kLabelTableCellId = "menu_label_cell"
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MenuViewController.ObserverSwitchView, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let w = UIScreen.mainScreen().applicationFrame.width;
        
        self.revealViewController().rearViewRevealWidth = w - kMenuOptionsWidthOffset
        
        tableView.dataSource = self
        tableView.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "performLastSegue:",
            name: MenuViewController.ObserverSwitchView,
            object: nil)
        
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.layoutMargins = UIEdgeInsetsZero
    }
    
    func performLastSegue(notification: NSNotification)
    {
        self.performSegueWithIdentifier(kLastSegue, sender: self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.revealViewController().frontViewController.view.userInteractionEnabled = false
        self.revealViewController().view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        
        updateEmailLabel()
        updateDisplayNameLabel()
        tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.revealViewController().frontViewController.view.userInteractionEnabled = true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let navigationController = segue.destinationViewController as! UINavigationController
        
        if let firstViewController: UIViewController = navigationController.viewControllers.first as? UIViewController {
            if (firstViewController.isKindOfClass(MailboxViewController)) {
                let mailboxViewController: MailboxViewController = navigationController.viewControllers.first as! MailboxViewController
                if let indexPath = sender as? NSIndexPath {
                    kLastSegue = segue.identifier!
                    self.kLastMenuItem = self.itemForIndexPath(indexPath)
                    switch(self.kLastMenuItem) {
                    case .inbox:
                        mailboxViewController.mailboxLocation = .inbox
                        mailboxViewController.setNavigationTitleText("INBOX")
                    case .starred:
                        mailboxViewController.mailboxLocation = .starred
                        mailboxViewController.setNavigationTitleText("STARRED")
                    case .drafts:
                        mailboxViewController.mailboxLocation = .draft
                        mailboxViewController.setNavigationTitleText("DRAFTS")
                    case .sent:
                        mailboxViewController.mailboxLocation = .outbox
                        mailboxViewController.setNavigationTitleText("SENT")
                    case .trash:
                        mailboxViewController.mailboxLocation = .trash
                        mailboxViewController.setNavigationTitleText("TRASH")
                    case .archive:
                        mailboxViewController.mailboxLocation = .archive
                        mailboxViewController.setNavigationTitleText("ARCHIVE")
                    case .spam:
                        mailboxViewController.mailboxLocation = .spam
                        mailboxViewController.setNavigationTitleText("SPAM")
                    default:
                        mailboxViewController.mailboxLocation = .inbox
                        mailboxViewController.setNavigationTitleText("INBOX")
                    }
                }
            }
        }
    }
    
    
    // MARK: - Methods
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func handleSignOut() {
        let alertController = UIAlertController(title: NSLocalizedString("Confirm"), message: nil, preferredStyle: .ActionSheet)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Sign Out"), style: .Destructive, handler: { (action) -> Void in
            sharedUserDataService.signOut(true)
            userCachedStatus.signOut()
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .Cancel, handler: nil))
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func itemForIndexPath(indexPath: NSIndexPath) -> MenuItem {
        return items[indexPath.row]
    }
    
    func updateDisplayNameLabel() {
        let displayName = sharedUserDataService.displayName
        
        if !displayName.isEmpty {
            displayNameLabel.text = displayName
            return
        }
        
        displayNameLabel.text = emailLabel.text
    }
    
    func updateEmailLabel() {
        if let username = sharedUserDataService.username {
            if !username.isEmpty {
                emailLabel.text = "\(username)@protonmail.ch"
                return
            }
        }
        emailLabel.text = ""
    }
}

extension MenuViewController: UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return kMenuCellHeight
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let item = itemForIndexPath(indexPath)
        if item == .signout {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            self.handleSignOut()
        } else if item == .settings {
            self.performSegueWithIdentifier(kSegueToSettings, sender: indexPath);
        } else {
            self.performSegueWithIdentifier(kSegueToMailbox, sender: indexPath);
        }
    }
}

extension MenuViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return items.count
        }
        return 3
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            var cell = tableView.dequeueReusableCellWithIdentifier(kMenuTableCellId, forIndexPath: indexPath) as! MenuTableViewCell
            cell.configCell(items[indexPath.row])
            cell.configUnreadCount()
            return cell
        } else {
            var cell: MenuTableViewCell = tableView.dequeueReusableCellWithIdentifier(kMenuTableCellId, forIndexPath: indexPath) as! MenuTableViewCell
            return cell
        }
    }
}
