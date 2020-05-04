//
//  ContactGroupSubSelectionViewController.swift
//  ProtonMail - Created on 2018/10/13.
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

class ContactGroupSubSelectionViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var contactGroupName: String = ""
    var selectedEmails: [DraftEmailData] = []
    var callback: (([DraftEmailData]) -> Void)? = nil
    
    var user: UserManager!
    private var viewModel: ContactGroupSubSelectionViewModel!
    private let kContactGroupSubSelectionHeaderCell = "ContactGroupSubSelectionHeaderCell"
    private let kContactGroupSubSelectionEmailCell  = "ContactGroupSubSelectionEmailCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = ContactGroupSubSelectionViewModelImpl.init(contactGroupName: contactGroupName,
                                                               selectedEmails: selectedEmails,
                                                               user: self.user,
                                                               delegate: self)
        
        prepareTableView()
        tableView.zeroMargin()
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
            
            cell.config(email: data.email,
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

extension ContactGroupSubSelectionViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let cell = tableView.cellForRow(at: indexPath) as? ContactGroupSubSelectionHeaderCell {
            cell.rowTapped()
        } else if let cell = tableView.cellForRow(at: indexPath) as? ContactGroupSubSelectionEmailCell {
            cell.rowTapped()
        }
    }
}

extension ContactGroupSubSelectionViewController: ContactGroupSubSelectionViewModelDelegate
{
    func reloadTable() {
        tableView.reloadData()
    }
}
