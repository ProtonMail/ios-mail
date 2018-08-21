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
    
    @IBOutlet weak var ContactGroupName: UITextField!
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
        
        viewModel.fetchContactGroupDetail()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension ContactGroupEditViewController: ContactGroupsViewModelDelegate
{
    func updated() {
        // TODO: load data into view
    }
}
