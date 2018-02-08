//
//  ContactImportViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/7/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit
import Contacts

protocol ContactImportVCDelegate {
    func done()
}

class ContactImportViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    
    private var cancelled : Bool = false
    
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
        titleLabel.text = NSLocalizedString("Importing Contacts", comment: "import contact title")
        if #available(iOS 9.0, *) {
            delay(0.5) {
                self.fetchedResultsController = self.getFetchedResultsController()
                self.messageLabel.text = NSLocalizedString("Reading device contacts data...", comment: "Title")
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
        self.cancelled = true
        self.dismiss()
    }
    
    private func dismiss() {
        delay(2) {
            self.dismiss(animated: true, completion: {
                
            })
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
                            self.messageLabel.text = NSLocalizedString("Cancelling", comment: "Title")
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
                            self.messageLabel.text = "Encrypting contacts...\(found)" //NSLocalizedString("Done", comment: "Title")
                            } ~> .main
                        
                        let rawData = try CNContactVCardSerialization.data(with: [contact])
                        let vcardStr = String(data: rawData, encoding: .utf8)!
                        if let vcard3 = PMNIEzvcard.parseFirst(vcardStr) {
                            let uuid = PMNIUid.createInstance(identifier)
                            guard let vcard2 = PMNIVCard.createInstance() else {
                                continue //with error
                            }
                            var defaultName = NSLocalizedString("Unknown", comment: "title, default display name")
                            let emails = vcard3.getEmails()
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
                            }
                            
                            if let fn = vcard3.getFormattedName() {
                                let name = fn.getValue().trim()
                                if name.isEmpty {
                                    if let fn = PMNIFormattedName.createInstance(defaultName) {
                                        vcard2.setFormattedName(fn)
                                    }
                                } else {
                                    vcard2.setFormattedName(fn)
                                }
                                vcard3.clearFormattedName()
                            } else {
                                if let fn = PMNIFormattedName.createInstance(defaultName) {
                                    vcard2.setFormattedName(fn)
                                }
                            }
                            
                            vcard2.setEmails(emails)
                            vcard3.clearEmails()
                            vcard2.setUid(uuid)
                            
                            // add others later
                            let vcard2Str = PMNIEzvcard.write(vcard2)
                            guard let userkey = sharedUserDataService.userInfo?.firstUserKey() else {
                                continue //with error
                            }
//                            PMLog.D(vcard2Str);
                            let signed_vcard2 = sharedOpenPGP.signDetached(userkey.private_key,
                                                                           plainText: vcard2Str,
                                                                           passphras: sharedUserDataService.mailboxPassword!)
                            
                            //card 2 object
                            let card2 = CardData(t: .SignedOnly, d: vcard2Str, s: signed_vcard2)
                            
                            vcard3.setUid(uuid)
                            vcard3.setVersion(PMNIVCardVersion.vCard40())
                            let vcard3Str = PMNIEzvcard.write(vcard3)
//                            PMLog.D(vcard3Str);
                            let encrypted_vcard3 = sharedOpenPGP.encryptMessageSingleKey(userkey.public_key, plainText: vcard3Str, privateKey: "", passphras: "")
//                            PMLog.D(encrypted_vcard3);
                            let signed_vcard3 = sharedOpenPGP.signDetached(userkey.private_key,
                                                                           plainText: vcard3Str,
                                                                           passphras: sharedUserDataService.mailboxPassword!)
                            //card 3 object
                            let card3 = CardData(t: .SignAndEncrypt, d: encrypted_vcard3, s: signed_vcard3)
                            
                            let cards : [CardData] = [card2, card3]
                            
                            pre_contacts.append(cards)
                        }
                    }
                }
            } catch let error as NSError {
                error.alertToast()
            }
            
            if !pre_contacts.isEmpty {
                if self.cancelled {
                    {
                        self.messageLabel.text = NSLocalizedString("Cancelling", comment: "Title")
                    } ~> .main
                    return
                }
                
                {
                    self.messageLabel.text = "uploading contacts "
                    //            sharedContactDataService.imports(cards: pre_contacts, completion:  { (contacts : [Contact]?, error : NSError?) in
                    //                if error == nil {
                    //                    let count = contacts?.count ?? 0
                    //                    // NSLocalizedString("You have imported \(count) of \(pre_contacts.count) contacts!", comment: "Title")
                    //                    self.messageLabel.text = "You have imported \(count) of \(found) contacts!"
                    //                    // "You have imported \(count) of \(pre_contacts.count) contacts!".alertToast()
                    //                } else {
                    //                    error?.alertToast()
                    //                }
                    //            })
                    
                    self.messageLabel.text = "You have imported \(found) of \(found) contacts!"
                    self.dismiss()
                } ~> .main
            } else {
                {
                    self.messageLabel.text = NSLocalizedString("All contacts are imported", comment: "Title")
                    self.dismiss()
                } ~> .main
            }
            
        } ~> .async
    }
    
}
