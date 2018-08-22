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

extension ContactGroupEditViewController: ContactGroupsViewModelDelegate
{
    func updated() {
        // TODO: load data into view
        
    }
}
