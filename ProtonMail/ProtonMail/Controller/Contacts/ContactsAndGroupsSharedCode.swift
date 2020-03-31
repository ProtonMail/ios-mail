//
//  ContactsAndGroupsSharedCode.swift
//  ProtonMail - Created on 2018/9/13.
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


import Foundation

class ContactsAndGroupsSharedCode: ProtonMailViewController
{
    var navigationItemRightNotEditing: [UIBarButtonItem]? = nil
    var navigationItemLeftNotEditing: [UIBarButtonItem]? = nil
    private var addBarButtonItem: UIBarButtonItem!
    private var importBarButtonItem: UIBarButtonItem!
    private var user: UserManager?
    
    let kAddContactSugue = "toAddContact"
    let kAddContactGroupSugue = "toAddContactGroup"
    let kSegueToImportView = "toImportContacts"
    let kToUpgradeAlertSegue = "toUpgradeAlertSegue"
    
    var isOnMainView = true {
        didSet {
            if isOnMainView {
                self.tabBarController?.tabBar.isHidden = false
            } else {
                self.tabBarController?.tabBar.isHidden = true
            }
        }
    }
    
    func prepareNavigationItemRightDefault(_ user: UserManager) {
        self.user = user
        self.addBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .add,
                                                         target: self,
                                                         action: #selector(self.addButtonTapped))
        self.importBarButtonItem = UIBarButtonItem.init(image: UIImage.init(named: "mail_attachment-closed"),
                                                        style: .plain,
                                                        target: self,
                                                        action: #selector(self.importButtonTapped))
        
        let rightButtons: [UIBarButtonItem] = [self.importBarButtonItem, self.addBarButtonItem]
        self.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
        
        navigationItemLeftNotEditing = navigationItem.leftBarButtonItems
        navigationItemRightNotEditing = navigationItem.rightBarButtonItems
    }
    
    @objc private func addButtonTapped() {
        /// set title
        let alertController = UIAlertController(title: LocalString._contacts_action_select_an_option,
                                                message: nil,
                                                preferredStyle: .actionSheet)
        
        /// set options
        alertController.addAction(UIAlertAction(title: LocalString._contacts_add_contact,
                                                style: .default,
                                                handler: {
                                                    (action) -> Void in
                                                    self.addContactTapped()
        }))
        
        alertController.addAction(UIAlertAction(title: LocalString._contact_groups_add,
                                                style: .default,
                                                handler: {
                                                    (action) -> Void in
                                                    self.addContactGroupTapped()
        }))
        
        /// set cancel
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button,
                                                style: .cancel,
                                                handler: nil))
        
        /// present
        alertController.popoverPresentationController?.barButtonItem = addBarButtonItem
        alertController.popoverPresentationController?.sourceRect = self.view.frame
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc private func importButtonTapped() {
        let alertController = UIAlertController(title: LocalString._contacts_action_select_an_option,
                                                message: nil,
                                                preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: LocalString._contacts_upload_contacts, style: .default, handler: { (action) -> Void in
            self.navigationController?.popViewController(animated: true)
            
            let alertController = UIAlertController(title: LocalString._contacts_title,
                                                    message: LocalString._upload_ios_contacts_to_protonmail,
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: LocalString._general_confirm_action,
                                                    style: .default,
                                                    handler: { (action) -> Void in
                                                        self.performSegue(withIdentifier: self.kSegueToImportView,
                                                                          sender: self)
            }))
            alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }))
        
        /// set cancel
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button,
                                                style: .cancel,
                                                handler: nil))
        
        /// present
        alertController.popoverPresentationController?.barButtonItem = addBarButtonItem
        alertController.popoverPresentationController?.sourceRect = self.view.frame
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc private func addContactTapped() {
        self.performSegue(withIdentifier: kAddContactSugue, sender: self)
    }
    
    @objc private func addContactGroupTapped() {
        if let user = self.user, user.isPaid  {
            self.performSegue(withIdentifier: kAddContactGroupSugue, sender: self)
        } else {
            self.performSegue(withIdentifier: kToUpgradeAlertSegue, sender: self)
        }
    }
}
