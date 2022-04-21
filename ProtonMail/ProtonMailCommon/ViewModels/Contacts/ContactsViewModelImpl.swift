//
//  ContactViewModelImpl.swift
//  ProtonMail - Created on 5/1/17.
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
import CoreData

final class ContactsViewModelImpl: ContactsViewModel {
    // MARK: - fetch controller
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    fileprivate var isSearching: Bool = false
    private var contactSections: [String] = []
    private var contacts: [String: [ContactEntity]] = [:] {
        didSet {
            DispatchQueue.main.async {
                self.uiDelegate?.reloadTable()
            }
        }
    }
    private weak var uiDelegate: ContactsVCUIProtocol?
    
    lazy var contactService : ContactDataService = { [unowned self] in
        return self.user.contactService
    }()
    
    override func setupFetchedResults() {
        self.fetchedResultsController = self.getFetchedResultsController()
        self.correctCachedData() { [weak self] in
            guard let self = self else { return }
            self.fetchedResultsController?.delegate = self
            self.transformCoreDataObjects()
        }
    }

    override func resetFetchedController() {
        if let fetch = self.fetchedResultsController {
            fetch.delegate = nil
            self.fetchedResultsController = nil
        }
    }

    func correctCachedData(completion: (() -> Void)?) {
        if let objects = fetchedResultsController?.fetchedObjects as? [Contact] {
            let context = self.coreDataService.rootSavingContext
            self.coreDataService.enqueue(context: context) { (context) in
                var needsSave = false
                let objectsToUpdate = objects.compactMap { obj -> Contact? in
                    return try? context.existingObject(with: obj.objectID) as? Contact
                }

                for obj in objectsToUpdate {
                    if obj.fixName() {
                        needsSave = true
                    }
                }
                if needsSave {
                    _ = context.saveUpstreamIfNeeded()
                }
                completion?()
            }
        } else {
            completion?()
        }
    }

    private func getFetchedResultsController() -> NSFetchedResultsController<NSFetchRequestResult>? {
        if let fetchedResultsController = contactService.resultController() {
            do {
                try fetchedResultsController.performFetch()
            } catch {
            }
            return fetchedResultsController
        }
        return nil
    }

    override func set(searching isSearching: Bool) {
        self.isSearching = isSearching
    }

    override func search(text: String) {
        var predicate: NSPredicate?
        if text.isEmpty {
            predicate = NSPredicate(format: "%K == %@", Contact.Attributes.userID, self.user.userInfo.userId)
        } else {
            predicate = NSPredicate(format: "(name CONTAINS[cd] %@ OR ANY emails.email CONTAINS[cd] %@) AND %K == %@", argumentArray: [text, text, Contact.Attributes.userID, self.user.userInfo.userId])
        }
        fetchedResultsController?.fetchRequest.predicate = predicate

        do {
            try fetchedResultsController?.performFetch()
            self.transformCoreDataObjects()
        } catch {
        }

    }

    // MARK: - table view part
    override func sectionCount() -> Int {
        return self.contactSections.count
    }

    override func rowCount(section: Int) -> Int {
        guard let key = self.contactSections[safe: section],
              let data = self.contacts[key] else {
            return 0
        }
        return data.count
    }

    override func sectionIndexTitle() -> [String]? {
        if isSearching {
            return nil
        }
        return self.contactSections.map(\.localizedUppercase)
    }

    override func sectionForSectionIndexTitle(title: String, atIndex: Int) -> Int {
        if isSearching {
            return -1
        }
        return self.contactSections.firstIndex(of: title.lowercased()) ?? -1
    }
    
    override func item(index: IndexPath) -> ContactEntity? {
        guard let key = self.contactSections[safe: index.section],
              let data = self.contacts[key] else {
                  return nil
              }
        return data[safe: index.row]
    }

    override func getContactObject(by contactID: ContactID) -> Contact? {
        guard let objects = self.fetchedResultsController?.fetchedObjects as? [Contact],
              let contact = objects.first(where: { $0.contactID == contactID.rawValue }) else {
                  return nil
              }
        return contact
    }

    // MARK: - api part
    override func delete(contactID: ContactID, complete : @escaping ContactDeleteComplete) {
        self.contactService
            .delete(contactID: contactID, completion: { (error) in
            if let err = error {
                complete(err)
            } else {
                complete(nil)
            }
        })
    }

    private var isFetching: Bool = false
    private var fetchComplete: ContactFetchComplete?
    override func fetchContacts(completion: ContactFetchComplete?) {
        if let c = completion {
            fetchComplete = c
        }
        if !isFetching {
            isFetching = true
            
            self.user.eventsService.fetchEvents(byLabel: Message.Location.inbox.labelID,
                                                 notificationMessageID: nil,
                                                 completion: { (task, res, error) in

            })
            self.user.contactService.fetchContacts { (_, error) in
                self.isFetching = false
                self.fetchComplete?(nil, nil)
            }
        }
    }

    // MARK: - timer overrride
    override internal func fireFetch() {
        self.fetchContacts(completion: nil)
    }

    override func transformCoreDataObjects() {
        let objects = self.fetchedResultsController?.fetchedObjects as? [Contact] ?? []
        let transforms = objects.map(ContactEntity.init(contact:))
        self.contactSections = Array(Set(transforms.map(\.sectionName))).sorted()
        var data: [String: [ContactEntity]] = [:]
        transforms.forEach { item in
            let section = item.sectionName
            if data[section] == nil {
                data[section] = [item]
            } else {
                data[section]?.append(item)
            }
        }
        self.contacts = data
    }

    override func setup(uiDelegate: ContactsVCUIProtocol?) {
        self.uiDelegate = uiDelegate
    }
}

extension ContactsViewModelImpl: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.transformCoreDataObjects()
    }
}
