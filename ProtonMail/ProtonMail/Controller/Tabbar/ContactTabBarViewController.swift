//
//  ContactTabBarViewController.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/9/4.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

class ContactTabBarViewController: ProtonMailTabBarController {
    
    
    fileprivate let kAddContactSugue: String      = "toAddContact"
    fileprivate let kAddContactGroupSugue: String = "toAddContactGroup"
    fileprivate let kSegueToImportView: String    = "toImportContacts"

    fileprivate var addBarButtonItem: UIBarButtonItem!
    fileprivate var importBarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        // setup navigtion bar
//        let back = UIBarButtonItem(title: LocalString._general_back_action,
//                                   style: UIBarButtonItemStyle.plain,
//                                   target: nil,
//                                   action: nil)
//        self.navigationItem.backBarButtonItem = back
        
        self.addBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .add,
                                                     target: self,
                                                     action: #selector(self.addButtonTapped))
        self.importBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .bookmarks,
                                                        target: self,
                                                        action: #selector(self.importButtonTapped))
        
        let rightButtons: [UIBarButtonItem] = [self.importBarButtonItem, self.addBarButtonItem]
        self.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
        
        // setup tab bar item title
        self.tabBar.items?[0].title = "Contacts"
        self.tabBar.items?[1].title = "Groups"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc internal func addButtonTapped() {
        /// set title
        let alertController = UIAlertController(title: "Select An Option",
                                                message: nil,
                                                preferredStyle: .actionSheet)
        
        /// set options
        alertController.addAction(UIAlertAction(title: "Create Contact",
                                                style: .default,
                                                handler: {
            (action) -> Void in
            self.addContactTapped()
        }))
        alertController.addAction(UIAlertAction(title: "Create Group",
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
    
    @objc internal func importButtonTapped() {
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
    
    @objc internal func addContactTapped() {
        self.performSegue(withIdentifier: kAddContactSugue, sender: self)
    }
    
    @objc internal func addContactGroupTapped() {
        self.performSegue(withIdentifier: kAddContactGroupSugue, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == kAddContactSugue) {
            let addContactViewController = segue.destination.childViewControllers[0] as! ContactEditViewController
            sharedVMService.contactAddViewModel(addContactViewController)
        } else if (segue.identifier == kAddContactGroupSugue) {
            let addContactGroupViewController = segue.destination.childViewControllers[0] as! ContactGroupEditViewController
            sharedVMService.contactGroupEditViewModel(addContactGroupViewController, state: .create)
        } else if segue.identifier == kSegueToImportView {
            let popup = segue.destination as! ContactImportViewController
            self.setPresentationStyleForSelfController(self,
                                                       presentingController: popup,
                                                       style: .overFullScreen)
        }
    }
}

