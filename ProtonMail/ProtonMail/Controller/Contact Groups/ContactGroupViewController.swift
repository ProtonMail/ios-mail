//
//  ContactGroupViewController.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/17.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

/*
 This is a temporary view. This should be integrate into the contact VC.
 
 Prototyping goals:
 1. Present all contact groups here
 2. Tap on the cell to view detail
 */

class ContactGroupViewController: ProtonMailViewController, ViewModelProtocol
{
    var viewModel: ContactGroupViewModel!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func cancelButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func setViewModel(_ vm: Any) {
    }
    
    func inactiveViewModel() {
    }
    
    override func viewDidLoad() {
        self.navigationItem.title = "[Locale] Contact Groups"
        
        viewModel = ContactGroupViewModelImpl()
        viewModel.fetchContactGroups()
        viewModel.contactGroupViewControllerDelegate = self
    }
}

extension ContactGroupViewController: UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getNumberOfRowsInSection()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "ContactGroupCell", for: indexPath)
        
        let data = viewModel.getContactGroupData(at: indexPath)
        if data == nil {
            cell.textLabel?.text = "Error in retrieving contact group name"
        }
        cell.textLabel?.text = data?.name
        
        return cell
    }
}

extension ContactGroupViewController: ContactGroupViewModelDelegate
{
    func updated() {
        self.tableView.reloadData()
    }
}
