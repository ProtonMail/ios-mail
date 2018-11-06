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
        self.tabBar.items?[0].title = LocalString._menu_contacts_title
        self.tabBar.items?[0].image = UIImage.init(named: "contact_groups_contacts_tabbar")
        self.tabBar.items?[1].title = LocalString._menu_contact_group_title
        self.tabBar.items?[1].image = UIImage.init(named: "contact_groups_groups_tabbar")
    }
}

