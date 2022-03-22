//
//  ContactImportViewController.swift
//  ProtonMail - Created on 2/7/18.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit
import Contacts
import CoreData
import OpenPGP
import ProtonCore_DataModel

class ContactImportViewController: UIViewController {
    var user: UserManager

    private(set) lazy var customView = ContactImportView()

    override func loadView() {
        self.view = customView
    }

    init(user: UserManager) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var cancelled: Bool = false
    private var showedCancel: Bool = false
    private var finished: Bool = false
    private var appleContactParser: AppleContactParserProtocol?

    var reloadAllContact: (() -> Void)?

    // MARK: - fetch controller
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?

    private func getFetchedResultsController() -> NSFetchedResultsController<NSFetchRequestResult>? {
        if let fetchedResultsController = self.user.contactService.resultController() {
            do {
                try fetchedResultsController.performFetch()
            } catch {
            }
            return fetchedResultsController
        }
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.appleContactParser = AppleContactParser(delegate: self,
                                                     coreDataService: sharedServices.get(by: CoreDataService.self))
        customView.progressView.progress = 0.0
        customView.titleLabel.attributedText = LocalString._contacts_import_title.apply(style: .Headline.alignment(.center))

        delay(0.5) {
            self.fetchedResultsController = self.getFetchedResultsController()
            self.customView.messageLabel.attributedText = LocalString._contacts_reading_contacts_data.apply(style: .CaptionWeak.alignment(.center))
            self.getContacts()
        }
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
            self.appleContactParser?.cancelImportTask()
        }))
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: {(action) -> Void in
            self.showedCancel = false
        }))
        self.present(alertController, animated: true, completion: nil)
        self.showedCancel = true
    }

    private func dismiss() {
        delay(2) {
            let isOffline = !self.isOnline
            self.dismiss(animated: true, completion: {
                if isOffline {
                    LocalString._contacts_saved_offline_hint.alertToastBottom()
                }
                self.reloadAllContact?()
            })

            if self.showedCancel {
                self.dismiss(animated: true, completion: nil)
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
                    self.dismiss()
                }
            })
        case .authorized:
            self.retrieveContactsWithStore(store: store)
        case .denied: {"Contacts access denied, please allow access from settings".alertToast()} ~> .main
            self.dismiss()
        case .restricted: {"The application is not authorized to access contact data".alertToast()} ~> .main
            self.dismiss()
        @unknown default: {"Contacts access denied, please allow access from settings".alertToast()} ~> .main
            self.dismiss()
        }
    }

    lazy var contacts: [CNContact] = sharedServices.get(by: AddressBookService.self).getAllContacts()

    internal func retrieveContactsWithStore(store: CNContactStore) {
        self.appleContactParser?.queueImport(contacts: self.contacts)
    }

}

extension ContactImportViewController: AppleContactParserDelegate {
    func update(progress: Double) {
        DispatchQueue.main.async {
            self.customView.progressView.progress = Float(progress)
        }
    }

    func update(message: String) {
        DispatchQueue.main.async {
            self.customView.messageLabel.attributedText = message.apply(style: .CaptionWeak.alignment(.center))
        }
    }

    func showParser(error: String) {
        DispatchQueue.main.async {
            error.alertToastBottom()
        }
    }

    func dismissImportPopup() {
        DispatchQueue.main.async {
            self.dismiss()
        }
    }

    func disableCancel() {
        DispatchQueue.main.async {
            self.customView.cancelButton.isEnabled = false
        }
    }

    func updateUserData() -> (userKey: Key, passphrase: String, existedContactIDs: [String])? {
        guard let userKey = self.user.userInfo.firstUserKey() else { return nil }
        let passphrase = self.user.mailboxPassword
        let existed = (fetchedResultsController?.fetchedObjects as? [Contact]) ?? []

        return (userKey: userKey,
                passphrase: passphrase,
                existedContactIDs: existed.map { $0.uuid })
    }

    func scheduleUpload(data: AppleContactParsedResult) {
        let error = self.user.contactService.queueAddContact(cardDatas: data.cardDatas,
                                                             name: data.name,
                                                             emails: data.definedMails)
        error?.localizedFailureReason?.alertToastBottom()
    }
}
