//
//  ContactTabBarViewController.swift
//  ProtonMail - Created on 2018/9/4.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import UIKit

class ContactTabBarViewController: UITabBarController, CoordinatedNew {
    typealias coordinatorType = ContactTabBarCoordinator
    private var coordinator : ContactTabBarCoordinator?
    func set(coordinator: ContactTabBarCoordinator) {
        self.coordinator = coordinator
    }
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
    
    enum Tab : Int {
        case contacts = 0
        case group = 1
    }
    
    var groupsViewController: ContactGroupsViewController? {
        get {
            let index = Tab.group.rawValue
            if let viewControllers = self.viewControllers, viewControllers.count > index,
                let navigation = viewControllers[index] as? UINavigationController,
                let viewController = navigation.firstViewController() as? ContactGroupsViewController {
                return viewController
            }
            return nil
        }
    }
    
    var contactsViewController: ContactsViewController? {
        get {
            let index = Tab.contacts.rawValue
            if let viewControllers = self.viewControllers, viewControllers.count > index,
                let navigation = viewControllers[index] as? UINavigationController,
                let viewController = navigation.firstViewController() as? ContactsViewController {
                return viewController
            }
            return nil
        }
    }
    
    ///    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup tab bar item title
        self.tabBar.items?[0].title = LocalString._menu_contacts_title
        self.tabBar.items?[0].image = UIImage.init(named: "contact_groups_contacts_tabbar")
        self.tabBar.items?[1].title = LocalString._menu_contact_group_title
        self.tabBar.items?[1].image = UIImage.init(named: "contact_groups_groups_tabbar")
        self.tabBar.assignItemsAccessibilityIdentifiers()
    }
}

