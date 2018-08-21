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
    
    let kToContactGroupDetailSegue: String = "toContactGroupDetailSegue"
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func cancelButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func setViewModel(_ vm: Any) {
        viewModel = vm as! ContactGroupViewModel
    }
    
    func inactiveViewModel() {
    }
    
    override func viewDidLoad() {
        self.navigationItem.title = "[Locale] Contact Groups"
        
        tableView.noSeparatorsBelowFooter()
        
        viewModel = ContactGroupViewModelImpl()
        viewModel.fetchContactGroups()
        viewModel.contactGroupViewControllerDelegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kToContactGroupDetailSegue {
            // setup the VC for editing state
            let contactGroupEditViewController = segue.destination as! ContactGroupEditViewController
            let contactGroup = sender as! ContactGroup
            
            contactGroupEditViewController.state = .edit
            
            // TODO:
            // 1. use API to get contact group details
            // 2. preload the VC with data
        }
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
        
        if let data = viewModel.getContactGroupData(at: indexPath) {
            cell.textLabel?.text = data.name
        } else {
            cell.textLabel?.text = "Error in retrieving contact group name"
        }
        
        return cell
    }
}

extension ContactGroupViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let contactGroup = viewModel.getContactGroupData(at: indexPath) {
            self.performSegue(withIdentifier: kToContactGroupDetailSegue, sender: contactGroup)
        }
    }
}

extension ContactGroupViewController: ContactGroupViewModelDelegate
{
    func updated() {
        self.tableView.reloadData()
    }
}
