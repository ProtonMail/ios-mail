//
//  ContactTabBarViewController.swift
//  ProtonMail - Created on 2018/9/4.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
    }
}

