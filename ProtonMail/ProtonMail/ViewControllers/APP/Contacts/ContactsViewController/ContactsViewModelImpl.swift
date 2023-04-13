//
//  ContactViewModelImpl.swift
//  Proton Mail - Created on 5/1/17.
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

import Foundation
import CoreData

final class ContactsViewModelImpl: ContactsViewModel {
    // MARK: - fetch controller
    fileprivate var fetchedResultsController: NSFetchedResultsController<Contact>?
    fileprivate var isSearching: Bool = false

    private weak var uiDelegate: ContactsVCUIProtocol?
    
    lazy var contactService : ContactDataService = { [unowned self] in
        return self.user.contactService
    }()
    
    override func setupFetchedResults() {
        self.fetchedResultsController = self.getFetchedResultsController()
        self.correctCachedData() { [weak self] in
            guard let self = self else { return }
            self.fetchedResultsController?.delegate = self
            self.notifyDelegateToRefresh()
        }
    }

    override func resetFetchedController() {
        if let fetch = self.fetchedResultsController {
            fetch.delegate = nil
            self.fetchedResultsController = nil
        }
    }

    private func correctCachedData(completion: @escaping (() -> Void)) {
        coreDataService.enqueueOnRootSavingContext { context in
            if let objects = self.fetchedResultsController?.fetchedObjects {
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
            }

            DispatchQueue.main.async(execute: completion)
        }
    }

    private func getFetchedResultsController() -> NSFetchedResultsController<Contact> {
        let fetchedResultsController = contactService.resultController(context: coreDataService.mainContext)
        do {
            try fetchedResultsController.performFetch()
        } catch {
            assertionFailure("db error: \(error)")
        }
        return fetchedResultsController
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
            notifyDelegateToRefresh()
        } catch {
            assertionFailure("\(error)")
        }
    }

    // MARK: - table view part
    override func sectionCount() -> Int {
        fetchedResultsController?.numberOfSections() ?? 0
    }

    override func rowCount(section: Int) -> Int {
        fetchedResultsController?.numberOfRows(in: section) ?? 0
    }

    override func sectionIndexTitle() -> [String]? {
        if isSearching {
            return nil
        }
        return fetchedResultsController?.sectionIndexTitles.map(\.localizedUppercase)
    }

    override func sectionForSectionIndexTitle(title: String, at index: Int) -> Int {
        if isSearching {
            return -1
        }
        return fetchedResultsController?.section(forSectionIndexTitle: title, at: index) ?? -1
    }
    
    override func item(index: IndexPath) -> ContactEntity? {
        guard let fetchedResultsController = fetchedResultsController else {
            return nil
        }

        let contact = fetchedResultsController.object(at: index)
        return ContactEntity(contact: contact)
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
                                                 completion: { _ in
            })
            self.user.contactService.fetchContacts { error in
                self.isFetching = false
                self.fetchComplete?(nil)
            }
        }
    }

    // MARK: - timer overrride
    override internal func fireFetch() {
        self.fetchContacts(completion: nil)
    }

    private func notifyDelegateToRefresh() {
        uiDelegate?.reloadTable()
    }

    override func setup(uiDelegate: ContactsVCUIProtocol?) {
        self.uiDelegate = uiDelegate
    }
}

extension ContactsViewModelImpl: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        notifyDelegateToRefresh()
    }
}
