//
//  ContactTabBarViewController.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/9/4.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

class ContactTabBarViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup tab bar item title
        self.tabBar.items?[0].title = "Contacts"
        self.tabBar.items?[1].title = "Groups"
    }
}

