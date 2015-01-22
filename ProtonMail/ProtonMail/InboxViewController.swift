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

class InboxViewController: ProtonMailViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private let kInboxCellHeight: CGFloat = 64.0
    private let kCellIdentifier: String = "InboxCell"
    
    private var messages: [EmailThread]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.messages = EmailService.retrieveMessages()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        var composeBarButtonItem = UIBarButtonItem(image: UIImage(named: "compose"), style: UIBarButtonItemStyle.Plain, target: self, action: "composeButtonTapped")
        var searchBarButtonItem = UIBarButtonItem(image: UIImage(named: "search"), style: UIBarButtonItemStyle.Plain, target: self, action: "searchButtonTapped")
        var rightButtons = [composeBarButtonItem, searchBarButtonItem]
        
        self.navigationItem.rightBarButtonItems = rightButtons
    }
    
    func composeButtonTapped() {
        
    }
    
    func searchButtonTapped() {
        
    }
}

extension InboxViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let thread: EmailThread = messages[indexPath.row]
        var inboxCell = tableView.dequeueReusableCellWithIdentifier(kCellIdentifier, forIndexPath: indexPath) as InboxTableViewCell
        inboxCell.title.text = thread.title
        inboxCell.sender.text = thread.sender
        inboxCell.time.text = thread.time
        inboxCell.encryptedImage.hidden = !thread.isEncrypted
        inboxCell.attachImage.hidden = !thread.hasAttachments
        
        if (thread.isFavorite) {
            inboxCell.favoriteButton.setImage(UIImage(named: "favorite_main_selected"), forState: UIControlState.Normal)
        }
        
        return inboxCell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
}

extension InboxViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return kInboxCellHeight
    }
}