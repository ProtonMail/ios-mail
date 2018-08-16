//
//  ContactGroupViewController.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/16.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

class ContactGroupViewController: ProtonMailViewController, ViewModelProtocol {
    fileprivate var viewModel : ContactEditViewModel!
    
    func setViewModel(_ vm: Any) {
        viewModel = vm as! ContactEditViewModel
    }
    
    func inactiveViewModel() {
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
