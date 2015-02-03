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

class SearchViewController: ProtonMailViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    
    
    // MARK: - Private Constants
    
    private let kInboxCellHeight: CGFloat = 64.0
    private let kCellIdentifier: String = "SearchedCell"

    
    // MARK: - Private attributes
    
    private var messages: [EmailThread] = []
    private var filteredMessages: [EmailThread] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.whiteColor()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        searchTextField.autocapitalizationType = UITextAutocapitalizationType.None
        searchTextField.delegate = self
        searchTextField.font = UIFont.robotoRegular(size: UIFont.Size.h4)
        searchTextField.textColor = UIColor.whiteColor()
        searchTextField.tintColor = UIColor.whiteColor()
        searchTextField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Search"), attributes:
            [
                NSForegroundColorAttributeName: UIColor.whiteColor(),
                NSFontAttributeName: UIFont.robotoLight(size: UIFont.Size.h3)
            ])
        
        self.messages = EmailService.retrieveInboxMessages()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        searchTextField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        searchTextField.resignFirstResponder()
    }
    
    override func configureNavigationBar() {
        super.configureNavigationBar()
        self.searchDisplayController?.displaysSearchBarInNavigationBar = true
        self.navigationController?.navigationBar.barTintColor = UIColor.ProtonMail.Blue_5C7A99        
    }
    
    
    // MARK: - Button Actions
    
    @IBAction func cancelButtonTapped(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}


// MARK: - UITableViewDataSource

extension SearchViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredMessages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let thread: EmailThread = filteredMessages[indexPath.row]
        var cell = tableView.dequeueReusableCellWithIdentifier(kCellIdentifier, forIndexPath: indexPath) as InboxTableViewCell
        cell.configureCell(thread)
        
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if (cell.respondsToSelector("setSeparatorInset:")) {
            cell.separatorInset = UIEdgeInsetsZero
        }
        
        if (cell.respondsToSelector("setLayoutMargins:")) {
            cell.layoutMargins = UIEdgeInsetsZero
        }
    }
}


// MARK: - UITableViewDelegate

extension SearchViewController: UITableViewDelegate {
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if (self.tableView.respondsToSelector("setSeparatorInset:")) {
            self.tableView.separatorInset = UIEdgeInsetsZero
        }
        
        if (self.tableView.respondsToSelector("setLayoutMargins:")) {
            self.tableView.layoutMargins = UIEdgeInsetsZero
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return kInboxCellHeight
    }
}


// MARK: - UITextFieldDelegate

extension SearchViewController: UITextFieldDelegate {
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        self.filteredMessages.removeAll(keepCapacity: true)
        
        var filterText = textField.text
        filterText = (filterText as NSString).stringByReplacingCharactersInRange(range, withString: string)
        for message in messages {
            if (message.title.lowercaseString.rangeOfString(filterText.lowercaseString) != nil) {
                filteredMessages.append(message)
            }
        }
        
        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
        return true
    }
}


