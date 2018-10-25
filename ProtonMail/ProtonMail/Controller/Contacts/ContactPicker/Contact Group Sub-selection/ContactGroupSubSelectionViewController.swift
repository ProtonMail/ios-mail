//
//  ContactGroupSubSelectionViewController.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/10/13.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

class ContactGroupSubSelectionViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var contactGroupName: String = ""
    var selectedEmails: [DraftEmailData] = []
    var callback: (([DraftEmailData]) -> Void)? = nil
    
    private var viewModel: ContactGroupSubSelectionViewModel!
    private let kContactGroupSubSelectionHeaderCell = "ContactGroupSubSelectionHeaderCell"
    private let kContactGroupSubSelectionEmailCell  = "ContactGroupSubSelectionEmailCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = ContactGroupSubSelectionViewModelImpl.init(contactGroupName: contactGroupName,
                                                               selectedEmails: selectedEmails,
                                                               delegate: self)
        
        prepareTableView()
    }
    
    func prepareTableView() {
        let contactGroupSubSelectionHeaderCellNib = UINib.init(nibName: "ContactGroupSubSelectionHeaderCell",
                                                               bundle: nil)
        let ContactGroupSubSelectionEmailCellNib = UINib.init(nibName: "ContactGroupSubSelectionEmailCell",
                                                              bundle: nil)
        tableView.register(contactGroupSubSelectionHeaderCellNib,
                           forCellReuseIdentifier: kContactGroupSubSelectionHeaderCell)
        tableView.register(ContactGroupSubSelectionEmailCellNib,
                           forCellReuseIdentifier: kContactGroupSubSelectionEmailCell)
        
        tableView.noSeparatorsBelowFooter()
        
        tableView.allowsSelection = false
    }
    
    /**
     Send currently selected contact emailID information back
     to the collection cell
     */
    @IBAction func tappedApplyButton(_ sender: UIButton) {
        self.callback?(self.viewModel.getCurrentlySelectedEmails())
        self.dismiss(animated: true,
                     completion: nil)
    }
    
    
    @IBAction func tappedCancelButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension ContactGroupSubSelectionViewController: UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getTotalRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            // header row
            let cell = tableView.dequeueReusableCell(withIdentifier: kContactGroupSubSelectionHeaderCell,
                                                     for: indexPath) as! ContactGroupSubSelectionHeaderCell
            cell.config(groupName: viewModel.getGroupName(),
                        groupColor: viewModel.getGroupColor(),
                        delegate: viewModel)
            return cell
        } else {
            // email rows
            let cell = tableView.dequeueReusableCell(withIdentifier: kContactGroupSubSelectionEmailCell,
                                                     for: indexPath) as! ContactGroupSubSelectionEmailCell
            let data = viewModel.cellForRow(at: indexPath)
            
            cell.config(emailText: data.getEmailDescription(),
                        email: data.email,
                        name: data.name,
                        isEndToEndEncrypted: data.isEncrypted,
                        isCurrentlySelected: data.isSelected,
                        at: indexPath,
                        checkEncryptedStatus: data.checkEncryptedStatus,
                        delegate: viewModel)
            return cell
        }
    }
}

extension ContactGroupSubSelectionViewController: ContactGroupSubSelectionViewModelDelegate
{
    func reloadTable() {
        tableView.reloadData()
    }
}
