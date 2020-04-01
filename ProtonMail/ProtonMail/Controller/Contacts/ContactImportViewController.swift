//
//  ContactImportViewController.swift
//  ProtonMail - Created on 2/7/18.
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
import Contacts
import CoreData

protocol ContactImportVCDelegate {
    func cancel()
    func done(error: String)
}

class ContactImportViewController: UIViewController {
    var user: UserManager!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    
    private var cancelled : Bool = false
    private var showedCancel : Bool = false
    private var finished : Bool = false
    
    // MARK: - fetch controller
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    fileprivate var isSearching: Bool = false
    
    private func getFetchedResultsController() -> NSFetchedResultsController<NSFetchRequestResult>? {
        if let fetchedResultsController = self.user.contactService.resultController() {
            do {
                try fetchedResultsController.performFetch()
            } catch let ex as NSError {
                PMLog.D("error: \(ex)")
            }
            return fetchedResultsController
        }
        return nil
    }
    
    func isExsit(uuid: String) -> Bool {
        if let contacts = fetchedResultsController?.fetchedObjects as? [Contact] {
            for c in contacts {
                if c.uuid == uuid {
                    return true
                }
            }
        }
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressView.progress = 0.0
        titleLabel.text = LocalString._contacts_import_title
        
        delay(0.5) {
            self.fetchedResultsController = self.getFetchedResultsController()
            self.messageLabel.text = LocalString._contacts_reading_contacts_data
            self.getContacts()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.cancelled = true
        self.dismiss()
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        
        if self.finished {
            return
        }
        
        let alertController = UIAlertController(title: LocalString._contacts_title,
                                                message: LocalString._contacts_import_cancel_wanring,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: LocalString._general_confirm_action,
                                                style: .destructive, handler: { (action) -> Void in
            self.showedCancel = false
            self.cancelled = true
            self.dismiss()
        }))
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: {(action) -> Void in
            self.showedCancel = false
        }))
        self.present(alertController, animated: true, completion: nil)
        self.showedCancel = true
    }
    
    private func dismiss() {
        delay(2) {
            self.dismiss(animated: true, completion: {
                
            })
            
            if self.showedCancel {
                self.dismiss(animated: true, completion: {
                    
                })
            }
        }
    }
    
    internal func getContacts() {
        let store = CNContactStore()
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .notDetermined:
            store.requestAccess(for: .contacts, completionHandler: { (authorized, error) in
                if authorized {
                    self.retrieveContactsWithStore(store: store)
                } else {
                    {"Contacts access is not authorized".alertToast()} ~> .main
                }
            })
        case .authorized:
            self.retrieveContactsWithStore(store: store)
        case .denied:
            {"Contacts access denied, please allow access from settings".alertToast()} ~> .main
        case .restricted:
            {"The application is not authorized to access contact data".alertToast()} ~> .main
        @unknown default:
            {"Contacts access denied, please allow access from settings".alertToast()} ~> .main
        }
    }
    
    lazy var contacts: [CNContact] = sharedServices.get(by: AddressBookService.self).getAllContacts()
    
    internal func retrieveContactsWithStore(store: CNContactStore) {
        guard case let mailboxPassword = self.user.mailboxPassword,
            let userkey = self.user.userInfo.firstUserKey(),
            case let authCredential = self.user.authCredential else
        {
            NSError.lockError().alertToast()
            return
        }
        
        {
            var pre_contacts : [[CardData]] = []
            var found: Int = 0
            //build boday first
            do {
                let contacts = self.contacts
                let titleCount = contacts.count
                var index : Float = 0
                for contact in contacts {
                    if self.cancelled {
                        {
                            self.messageLabel.text = LocalString._contacts_cancelling_title
                        } ~> .main
                        return
                    }
                    
                    {
                        let offset = index / Float(titleCount)
                        self.progressView.setProgress(offset, animated: true)
                    } ~> .main
                    
                    index += 1.0
                    
                    //check is uuid in the exsiting contacts
                    let identifier = contact.identifier
                    
                    if !self.isExsit(uuid: identifier) {
                        found += 1
                        {
                            self.messageLabel.text = "Encrypting contacts...\(found)"
                        } ~> .main
                        
                        /* not included into requested keys since iOS 13 SDK, see comment in AddressBookSerivice.getAllContacts() */
                        // let note = contact.note
                        let note = ""
                        
                        let rawData = try CNContactVCardSerialization.data(with: [contact])
                        let vcardStr = String(data: rawData, encoding: .utf8)!
                        if let vcard3 = PMNIEzvcard.parseFirst(vcardStr) {
                            let uuid = PMNIUid.createInstance(identifier)
                            guard let vcard2 = PMNIVCard.createInstance() else {
                                continue
                            }
                            var defaultName = LocalString._general_unknown_title
                            let emails = vcard3.getEmails()
                            var vcard2Emails: [PMNIEmail] = []
                            var i : Int = 1
                            for e in emails {
                                let ng = "EItem\(i)"
                                let group = e.getGroup()
                                if group.isEmpty {
                                    e.setGroup(ng)
                                    i += 1
                                }
                                let em = e.getValue()
                                if !em.isEmpty {
                                    defaultName = em
                                }
                                
                                if em.isValidEmail() {
                                    vcard2Emails.append(e)
                                }
                            }
                            
                            if let fn = vcard3.getFormattedName() {
                                var name = fn.getValue().trim()
                                name = name.preg_replace("  ", replaceto: " ")
                                if name.isEmpty {
                                    if let fn = PMNIFormattedName.createInstance(defaultName) {
                                        vcard2.setFormattedName(fn)
                                    }
                                } else {
                                    if let fn = PMNIFormattedName.createInstance(name) {
                                        vcard2.setFormattedName(fn)
                                    }
                                }
                                vcard3.clearFormattedName()
                            } else {
                                if let fn = PMNIFormattedName.createInstance(defaultName) {
                                    vcard2.setFormattedName(fn)
                                }
                            }
                            
                            vcard2.setEmails(vcard2Emails)
                            vcard3.clearEmails()
                            vcard2.setUid(uuid)
                            
                            do {
                                // add others later
                                guard let vcard2Str = try vcard2.write() else {
                                    continue
                                }
                                let signed_vcard2 = try Crypto().signDetached(plainData: vcard2Str,
                                                                              privateKey: userkey.private_key,
                                                                              passphrase: mailboxPassword)
                                
                                //card 2 object
                                let card2 = CardData(t: .SignedOnly, d: vcard2Str, s: signed_vcard2)
                                
                                vcard3.setUid(uuid)
                                vcard3.setVersion(PMNIVCardVersion.vCard40())
                                
                                if !note.isEmpty {
                                    vcard3.setNote(PMNINote.createInstance("", note: note))
                                }
                                
                                guard let vcard3Str = try vcard3.write() else {
                                    continue
                                }
                                let encrypted_vcard3 = try vcard3Str.encrypt(withPubKey: userkey.publicKey, privateKey: "", passphrase: "")
                                let signed_vcard3 = try Crypto().signDetached(plainData: vcard3Str,
                                                                              privateKey: userkey.private_key,
                                                                              passphrase: mailboxPassword)
                                //card 3 object
                                let card3 = CardData(t: .SignAndEncrypt, d: encrypted_vcard3 ?? "", s: signed_vcard3)
                                
                                let cards : [CardData] = [card2, card3]
                                
                                pre_contacts.append(cards)
                            } catch {
                                // upload vcardStr when see error
                                BugDataService.debugReport("VCARD", vcardStr, completion: nil)
                            }
                        }
                    }
                }
            } catch let error as NSError {
                error.alertToast()
            }
            
            if !pre_contacts.isEmpty {
                let pre_count = pre_contacts.count
                if self.cancelled {
                    {
                        self.messageLabel.text = LocalString._contacts_cancelling_title
                    } ~> .main
                    return
                }

                {
                    self.progressView.setProgress(0.0, animated: false)
                    self.messageLabel.text = "Uploading contacts. 0/\(pre_count)"
                } ~> .main
                
                self.user.contactService.imports(cards: pre_contacts, authCredential: authCredential, cancel: { () -> Bool in
                    return self.cancelled
                }, update: { (processed) in
                    {
                        let uploadOffset = Float(processed) / Float(pre_count)
                        self.progressView.setProgress(uploadOffset, animated: true)
                        self.messageLabel.text = "Uploading contacts. \(processed)/\(pre_count)"
                    } ~> .main
                }, completion: { (contacts : [Contact]?, error : String) in
                    {
                        self.finished = true
                        if let conts = contacts {
                            let count = conts.count
                            self.progressView.setProgress(1, animated: true)
                            self.messageLabel.text = "You have imported \(count) of \(found) contacts!"
                        }
                        
                        if error.isEmpty {
                            self.dismiss()
                        } else {
                            let alertController = UIAlertController(title: LocalString._contacts_import_error,
                                                                    message: error,
                                                                    preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: LocalString._general_ok_action,
                                                                    style: .default, handler: {(action) -> Void in
                                self.dismiss()
                            }))
                            self.present(alertController, animated: true, completion: nil)
                        }
                    } ~> .main
                })
                
            } else {
                {
                    self.finished = true
                    self.messageLabel.text = LocalString._contacts_all_imported
                    self.dismiss()
                } ~> .main
            }
            
        } ~> .async
    }
    
}
