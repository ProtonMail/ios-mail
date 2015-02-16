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
    
    
    // MARK - Views Outlets
    
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    
    // MARK: - Private constants
    
    private let items = [MenuItem.inbox, MenuItem.starred, MenuItem.drafts, MenuItem.sent, MenuItem.trash, MenuItem.spam, MenuItem.contacts, MenuItem.settings, MenuItem.signout]
    private let kMenuCellHeight: CGFloat = 62.0
    private let kMenuOptionsWidth: CGFloat = 227.0
    
    private let kSegueToInbox: String = "toInbox"
    private let kSegueToStarred: String = "toStarred"
    private let kSegueToDrafts: String = "toDrafts"
    private let kSegueToSent: String = "toSent"
    private let kSegueToTrash: String = "toTrash"
    private let kSegueToSpam: String = "toSpam"
    
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.revealViewController().rearViewRevealWidth = kMenuOptionsWidth
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateEmailLabel()
        updateDisplayNameLabel()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let navigationController = segue.destinationViewController as UINavigationController
        
        if let firstViewController: UIViewController = navigationController.viewControllers.first as? UIViewController {
            if (firstViewController.isKindOfClass(MailboxViewController)) {
                let mailboxViewController: MailboxViewController = navigationController.viewControllers.first as MailboxViewController
                
                switch(segue.identifier!) {
                case kSegueToInbox:
                    mailboxViewController.mailboxLocation = .inbox
                    mailboxViewController.setNavigationTitleText("INBOX")
                    
                case kSegueToStarred:
                    mailboxViewController.mailboxLocation = .starred
                    mailboxViewController.setNavigationTitleText("STARRED")
                    
                case kSegueToDrafts:
                    mailboxViewController.mailboxLocation = .draft
                    mailboxViewController.setNavigationTitleText("DRAFTS")
                    
                case kSegueToSent:
                    mailboxViewController.mailboxLocation = .outbox
                    mailboxViewController.setNavigationTitleText("SENT")
                    
                case kSegueToTrash:
                    mailboxViewController.mailboxLocation = .trash
                    mailboxViewController.setNavigationTitleText("TRASH")
                    
                case kSegueToSpam:
                    mailboxViewController.mailboxLocation = .spam
                    mailboxViewController.setNavigationTitleText("SPAM")
                default:
                    mailboxViewController.mailboxLocation = .inbox
                    mailboxViewController.setNavigationTitleText("INBOX")
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
            sharedUserDataService.signOut()
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .Cancel, handler: nil))
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func itemForIndexPath(indexPath: NSIndexPath) -> MenuItem {
        return items[indexPath.row]
    }
    
    func updateDisplayNameLabel() {
        if let displayName = sharedUserDataService.displayName {
            if !displayName.isEmpty {
                displayNameLabel.text = displayName
                return
            }
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
        }
    }
}

extension MenuViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: MenuTableViewCell = tableView.dequeueReusableCellWithIdentifier(itemForIndexPath(indexPath).identifier, forIndexPath: indexPath) as MenuTableViewCell
        
        let selectedBackgroundView = UIView(frame: CGRectZero)
        selectedBackgroundView.backgroundColor = UIColor.ProtonMail.Blue_5C7A99
        
        cell.selectedBackgroundView = selectedBackgroundView
        return cell
    }
}

extension MenuViewController {
    enum MenuItem: String {
        case inbox = "Inbox"
        case starred = "Starred"
        case drafts = "Drafts"
        case sent = "Sent"
        case trash = "Trash"
        case spam = "Spam"
        case contacts = "Contacts"
        case settings = "Settings"
        case signout = "Signout"
        
        var identifier: String { return rawValue }
    }
}