//
//  ContactGroupViewController.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/17.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

/*
 Prototyping goals:
 1. Present all contact groups here
 2. Tap on the cell to view detail
 */

class ContactGroupViewController: ProtonMailViewController, ViewModelProtocol
{
    
    @IBAction func cancelButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func setViewModel(_ vm: Any) {
        
    }
    
    func inactiveViewModel() {
        
    }
    
    
}
