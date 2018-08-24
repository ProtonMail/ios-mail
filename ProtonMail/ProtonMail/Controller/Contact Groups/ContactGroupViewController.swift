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

class ContactGroupsViewController: ProtonMailViewController, ViewModelProtocol
{
    var viewModel: ContactGroupsViewModel!
    let kToContactGroupDetailSegue: String = "toContactGroupDetailSegue"
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func cancelButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func setViewModel(_ vm: Any) {
        viewModel = vm as! ContactGroupsViewModel
    }
    
    func inactiveViewModel() {
    }
    
    override func viewDidLoad() {
        self.navigationItem.title = "Contact Groups"
        
        tableView.noSeparatorsBelowFooter()
        
        viewModel.fetchContactGroups()
        viewModel.contactGroupsViewControllerDelegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kToContactGroupDetailSegue {
            let contactGroupEditViewController = segue.destination.childViewControllers[0] as! ContactGroupEditViewController
            let contactGroup = sender as! ContactGroup

            let refreshHandler = {
                () -> Void in
                
                self.viewModel.fetchContactGroups()
            }
            
            sharedVMService.contactGroupEditViewModel(contactGroupEditViewController,
                                                      state: .edit,
                                                      contactGroupID: contactGroup.ID,
                                                      name: contactGroup.name,
                                                      color: contactGroup.color,
                                                      refreshHandler: refreshHandler)
        }
    }
}

extension ContactGroupsViewController: UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getNumberOfRowsInSection()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "ContactGroupCell", for: indexPath)
        
        if let data = viewModel.getContactGroupData(at: indexPath), let name = data.name {
            cell.textLabel?.text = name
        } else {
            cell.textLabel?.text = "Error in retrieving contact group name"
        }
        
        return cell
    }
}

extension ContactGroupsViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let contactGroup = viewModel.getContactGroupData(at: indexPath) {
            self.performSegue(withIdentifier: kToContactGroupDetailSegue, sender: contactGroup)
        }
    }
}

extension ContactGroupsViewController: ContactGroupsViewModelDelegate
{
    func updated() {
        self.tableView.reloadData()
    }
}
