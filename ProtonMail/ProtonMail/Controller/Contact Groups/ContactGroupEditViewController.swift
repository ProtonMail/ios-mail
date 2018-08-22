//
//  ContactGroupEditViewController.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/16.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

/*
 Prototyping goals:
 1. Able to handle create/edit/delete operations, without caching mechanism
 2. Able to handle saving operation
 */

class ContactGroupEditViewController: ProtonMailViewController, ViewModelProtocol {
    @IBOutlet weak var contactGroupNameLabel: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var navigationBarItem: UINavigationItem!
    @IBOutlet weak var tableView: UITableView!
    var viewModel: ContactGroupEditViewModel!
    
    func setViewModel(_ vm: Any) {
        viewModel = vm as! ContactGroupEditViewModel
    }
    
    func inactiveViewModel() {}
    
    @IBAction func cancelItem(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.contactGroupEditViewDelegate = self
        viewModel.fetchContactGroupDetail()
        
        navigationBarItem.title = viewModel.getViewTitle()
        contactGroupNameLabel.text = viewModel.getContactGroupName()
        
        tableView.noSeparatorsBelowFooter()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func saveAction(_ sender: UIBarButtonItem) {
        // TODO: ask view model to save it
        viewModel.saveContactGroupDetail(name: contactGroupNameLabel.text,
                                         color: "#f66", /* TODO: remove this hardcoded color */
            emailList: nil)
        
        // TODO: spinning while saving... (blocking)
        self.dismiss(animated: true, completion: nil)
    }
}

extension ContactGroupEditViewController: UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.getTotalSections()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getTotalRows(for: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewModel.getCellType(at: indexPath) {
        case .selectColor:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactGroupColorCell", for: indexPath)
            return cell
        case .manageContact:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactGroupManageCell", for: indexPath)
            return cell
        case .email:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactGroupMemberCell", for: indexPath)
            return cell
        case .deleteGroup:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactGroupDeleteCell", for: indexPath)
            return cell
        case .error:
            fatalError("This is a bug")
        }
    }
}

extension ContactGroupEditViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch viewModel.getCellType(at: indexPath) {
        case .selectColor:
            print("go to select color view")
        case .manageContact:
            print("go to select email view")
        case .email:
            print("email actions")
        case .deleteGroup:
            viewModel.deleteContactGroup()
            self.dismiss(animated: true, completion: nil)
        case .error:
            fatalError("This is a bug")
        }
    }
}

extension ContactGroupEditViewController: ContactGroupsViewModelDelegate
{
    func updated() {
        // TODO: load data into view
        
    }
}
