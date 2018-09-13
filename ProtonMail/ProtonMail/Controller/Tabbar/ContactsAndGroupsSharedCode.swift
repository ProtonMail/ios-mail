//
//  ContactsAndGroupsSharedCode.swift
//  
//
//  Created by Chun-Hung Tseng on 2018/9/13.
//

import Foundation

class ContactsAndGroupsSharedCode: ProtonMailViewController
{
    private var addBarButtonItem: UIBarButtonItem!
    private var importBarButtonItem: UIBarButtonItem!
    
    let kAddContactSugue: String      = "toAddContact"
    let kAddContactGroupSugue: String = "toAddContactGroup"
    let kSegueToImportView: String    = "toImportContacts"
    
    func prepareNavigationItem() {
        self.addBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .add,
                                                     target: self,
                                                     action: #selector(self.addButtonTapped))
        self.importBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .bookmarks,
                                                        target: self,
                                                        action: #selector(self.importButtonTapped))
        
        let rightButtons: [UIBarButtonItem] = [self.importBarButtonItem, self.addBarButtonItem]
        self.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
    }
    
    @objc private func addButtonTapped() {
        /// set title
        let alertController = UIAlertController(title: "Select An Option",
                                                message: nil,
                                                preferredStyle: .actionSheet)
        
        /// set options
        alertController.addAction(UIAlertAction(title: "Add new contact",
                                                style: .default,
                                                handler: {
                                                    (action) -> Void in
                                                    self.addContactTapped()
        }))
        alertController.addAction(UIAlertAction(title: "Add new contact group",
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
        let alertController = UIAlertController(title: "Select An Option",
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
        self.performSegue(withIdentifier: kAddContactGroupSugue, sender: self)
    }
}
