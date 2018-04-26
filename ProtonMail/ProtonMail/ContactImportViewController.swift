//
//  ContactImportViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/7/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit
import Contacts
import CoreData

protocol ContactImportVCDelegate {
    func cancel()
    func done(error: String)
}

class ContactImportViewController: UIViewController {
    
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
        if let fetchedResultsController = sharedContactDataService.resultController() {
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
        if #available(iOS 9.0, *) {
            delay(0.5) {
                self.fetchedResultsController = self.getFetchedResultsController()
                self.messageLabel.text = LocalString._contacts_reading_contacts_data
                self.getContacts()
            }
        } else {
            self.dismiss()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.cancelled = true
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
    
    @available(iOS 9.0, *)
    internal func getContacts() {
        let store = CNContactStore()
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .notDetermined:
            store.requestAccess(for: .contacts, completionHandler: { (authorized, error) in
                if authorized {
                    self.retrieveContactsWithStore(store: store)
                } else {
                    "Contacts access is not authorized".alertToast()
                }
            })
        case .authorized:
            self.retrieveContactsWithStore(store: store)
        case .denied:
            "Contacts access denied, please allow access from settings".alertToast()
        case .restricted:
            "The application is not authorized to access contact data".alertToast()
        }
    }
    
    @available(iOS 9.0, *)
    lazy var contacts: [CNContact] = {
        let contactStore = CNContactStore()
        let keysToFetch : [CNKeyDescriptor] = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactImageDataAvailableKey as CNKeyDescriptor,
            CNContactImageDataKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactNoteKey as CNKeyDescriptor,
            CNContactVCardSerialization.descriptorForRequiredKeys()]
        
        // Get all the containers
        var allContainers: [CNContainer] = []
        do {
            allContainers = try contactStore.containers(matching: nil)
        } catch {
            print("Error fetching containers")
        }
        
        var results: [CNContact] = []
        
        // Iterate all containers and append their contacts to our results array
        for container in allContainers {
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            do {
                let containerResults = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch)
                results.append(contentsOf: containerResults)
            } catch {
                print("Error fetching results for container")
            }
        }
        
        return results
    }()
    
    @available(iOS 9.0, *)
    internal func retrieveContactsWithStore(store: CNContactStore) {
        
        {
            var pre_contacts : [[CardData]] = []
            var found: Int = 0
            //build boday first
            do {
                let contacts = self.contacts
                let titleCount = contacts.count
                var index : Float = 0;
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
                        
                        let note = contact.note
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
                                
                                guard let userkey = sharedUserDataService.userInfo?.firstUserKey() else {
                                    continue //with error
                                }
                                
                                let signed_vcard2 = sharedOpenPGP.signDetached(userkey.private_key,
                                                                               plainText: vcard2Str,
                                                                               passphras: sharedUserDataService.mailboxPassword!)
                                
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
                                let encrypted_vcard3 = sharedOpenPGP.encryptMessageSingleKey(userkey.public_key, plainText: vcard3Str, privateKey: "", passphras: "", trim: true)
                                let signed_vcard3 = sharedOpenPGP.signDetached(userkey.private_key,
                                                                               plainText: vcard3Str,
                                                                               passphras: sharedUserDataService.mailboxPassword!)
                                //card 3 object
                                let card3 = CardData(t: .SignAndEncrypt, d: encrypted_vcard3, s: signed_vcard3)
                                
                                let cards : [CardData] = [card2, card3]
                                
                                pre_contacts.append(cards)
                            } catch {
                                // upload vcardStr when see error
                                BugDataService().debugReport("VCARD", vcardStr, completion: nil)
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
                
                sharedContactDataService.imports(cards: pre_contacts, cancel: { () -> Bool in
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
