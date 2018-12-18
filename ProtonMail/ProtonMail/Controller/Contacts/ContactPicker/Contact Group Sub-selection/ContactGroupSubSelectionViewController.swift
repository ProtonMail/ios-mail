//
//  ContactGroupSubSelectionViewController.swift
//  ProtonMail - Created on 2018/10/13.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
