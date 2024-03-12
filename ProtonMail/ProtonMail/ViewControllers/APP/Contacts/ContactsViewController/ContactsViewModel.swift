//
//  ContactsViewModel.swift
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

import Combine
import CoreData
import Foundation
import UIKit

final class ContactsViewModel: ViewModelTimer {
    typealias Dependencies = HasCoreDataContextProviderProtocol
    & HasMailEventsPeriodicScheduler
    & HasUserManager
    & HasContactsSyncQueueProtocol
    & HasAutoImportContactsFeature
    & HasUserDefaults
    & HasImportDeviceContacts

    private let dependencies: Dependencies

    let importContactsProgress: CurrentValueSubject<String, Never> = .init("")
    private var snapshotPublisher: SnapshotPublisher<Contact>?
    private var cancellables: Set<AnyCancellable> = .init()

    var contactService: ContactDataService {
        return dependencies.user.contactService
    }

    var contentDidChange: ((NSDiffableDataSourceSnapshot<String, ContactEntity>) -> Void)?
    var hasPaidMailPlan: Bool {
        dependencies.user.hasPaidMailPlan
    }

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        super.init()
        setUpBindings()
    }

    private func setUpBindings() {
        dependencies
            .contactSyncQueue
            .progressPublisher
            .sink { [weak self] progress in
                guard progress.total > 0 else {
                    self?.importContactsProgress.send(.empty)
                    return
                }
                self?.importContactsProgress.send("\(progress.finished)/\(progress.total)")
            }
            .store(in: &cancellables)
    }

    func setupFetchedResults() {
        createSnapshotPublisher(searchText: nil)
    }

    func search(text: String) {
        createSnapshotPublisher(searchText: text)
    }

    private func createSnapshotPublisher(searchText: String?) {
        let sortDescriptor = NSSortDescriptor(
            key: Contact.Attributes.name,
            ascending: true,
            selector: #selector(NSString.caseInsensitiveCompare(_:))
        )
        let predicate: NSPredicate
        if let searchText = searchText, !searchText.isEmpty {
            predicate = NSPredicate(
                format: "(name CONTAINS[cd] %@ OR ANY emails.email CONTAINS[cd] %@) AND %K == %@",
                argumentArray: [
                    searchText,
                    searchText,
                    Contact.Attributes.userID,
                    dependencies.user.userID.rawValue
                ]
            )
        } else {
            predicate = NSPredicate(
                format: "%K == %@ AND %K == 0",
                Contact.Attributes.userID,
                dependencies.user.userID.rawValue,
                Contact.Attributes.isSoftDeleted
            )
        }

        snapshotPublisher = SnapshotPublisher<Contact>(
            entityName: Contact.Attributes.entityName,
            predicate: predicate,
            sortDescriptors: [sortDescriptor],
            sectionNameKeyPath: Contact.Attributes.sectionName,
            contextProvider: dependencies.contextProvider
        )
        snapshotPublisher?.contentDidChange
            .sink(receiveValue: { [weak self] snapshot in
                let snapshot = snapshot as NSDiffableDataSourceSnapshot<String, Contact>
                var newSnapShot = NSDiffableDataSourceSnapshot<String, ContactEntity>()
                let sections = snapshot.sectionIdentifiers
                newSnapShot.appendSections(sections)
                for section in sections {
                    let rows = snapshot.itemIdentifiers(inSection: section).map(ContactEntity.init)
                    newSnapShot.appendItems(rows, toSection: section)
                }
                self?.contentDidChange?(newSnapShot)
            }).store(in: &cancellables)
        snapshotPublisher?.start()
    }

    func delete(contactID: ContactID, complete: @escaping ContactDeleteComplete) {
        self.contactService
            .delete(contactID: contactID, completion: { error in
                if let err = error {
                    complete(err)
                } else {
                    complete(nil)
                }
            })
    }

    private var isFetching: Bool = false
    private var fetchComplete: ContactFetchComplete?
    func fetchContacts(completion: ContactFetchComplete?) {
        if let c = completion {
            fetchComplete = c
        }
        if !isFetching {
            isFetching = true

            if dependencies.user.isNewEventLoopEnabled {
                dependencies.mailEventsPeriodicScheduler.triggerSpecialLoop(
                    forSpecialLoopID: dependencies.user.userID.rawValue
                )
            } else {
                dependencies.user.eventsService.fetchEvents(
                    byLabel: Message.Location.inbox.labelID,
                    notificationMessageID: nil,
                    discardContactsMetadata: EventCheckRequest.isNoMetaDataForContactsEnabled,
                    completion: { _ in
                    }
                )
            }
            dependencies.user.contactService.fetchContacts { _ in
                self.isFetching = false
                self.fetchComplete?(nil)
            }
        }
    }

    override func fireFetch() {
        self.fetchContacts(completion: nil)
    }

    func showShowContactAutoSyncBanner() -> Bool {
        let isFunctionEnabled = dependencies.autoImportContactsFeature.isSettingEnabledForUser
        if isFunctionEnabled {
            markAutoContactSyncAsSeen()
            return false
        }
        if dependencies.userDefaults[.hasContactAutoSyncBannerShown] {
            return false
        }
        return true
    }

    func enableAutoContactSync() {
        dependencies.autoImportContactsFeature.enableSettingForUser()
        let params = ImportDeviceContacts.Params(
            userKeys: dependencies.user.userInfo.userKeys,
            mailboxPassphrase: dependencies.user.mailboxPassword
        )
        dependencies.importDeviceContacts.execute(params: params)
        markAutoContactSyncAsSeen()
    }

    func markAutoContactSyncAsSeen() {
        dependencies.userDefaults[.hasContactAutoSyncBannerShown] = true
    }
}
