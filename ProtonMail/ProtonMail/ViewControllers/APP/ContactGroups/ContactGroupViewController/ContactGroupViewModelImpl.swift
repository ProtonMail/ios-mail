//
//  ContactGroupViewModelImpl.swift
//  Proton Mail - Created on 2018/8/20.
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

import CoreData
import Foundation
import PromiseKit

class ContactGroupsViewModelImpl: ViewModelTimer, ContactGroupsViewModel {
    typealias Dependencies = HasCoreDataContextProviderProtocol
        & HasMailEventsPeriodicScheduler
        & HasUserManager
    private let dependencies: Dependencies

    private var contactGroupPublisher: LabelPublisher?
    private var isFetching: Bool = false

    var user: UserManager {
        dependencies.user
    }

    private var contactGroupService: ContactGroupsDataService {
        user.contactGroupService
    }

    private var eventsService: EventsFetching {
        user.eventsService
    }

    private var selectedGroupIDs: Set<String> = .init()

    private(set) var isSearching: Bool = false
    private(set) var searchText: String?
    private var filtered: [LabelEntity] = []
    private weak var uiDelegate: ContactGroupsUIProtocol?
    private var labelEntities: [LabelEntity] = []

    /**
     Init the view model with state

     State "ContactGroupsView" is for showing all contact groups in the contact group tab
     State "ContactSelectGroups" is for showing all contact groups in the contact creation / editing page
     */
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func initEditing() -> Bool {
        return false
    }

    /**
     - Returns: if the give group is currently selected or not
     */
    func isSelected(groupID: String) -> Bool {
        return selectedGroupIDs.contains(groupID)
    }

    /**
     Call this function when we are in "ContactSelectGroups" for returning the selected conatct groups
     */
    func save() {}

    /**
     Add the group ID to the selected group list
     */
    func addSelectedGroup(ID: String) {
        if selectedGroupIDs.contains(ID) == false {
            selectedGroupIDs.insert(ID)
        }
    }

    /**
     Remove the group ID from the selected group list
     */
    func removeSelectedGroup(ID: String) {
        if selectedGroupIDs.contains(ID) {
            selectedGroupIDs.remove(ID)
        }
    }

    /**
     Remove all group IDs from the selected group list
     */
    func removeAllSelectedGroups() {
        selectedGroupIDs.removeAll()
    }

    /**
     Get the count of currently selected groups
     */
    func getSelectedCount() -> Int {
        return selectedGroupIDs.count
    }

    /**
     Fetch all contact groups from the server using API
     */
    func fetchLatestContactGroup(completion: @escaping (Error?) -> Void) {
        if self.isFetching == false {
            self.isFetching = true
            if user.isNewEventLoopEnabled {
                dependencies.mailEventsPeriodicScheduler.triggerSpecialLoop(forSpecialLoopID: user.userID.rawValue)
                self.user.contactService.fetchContacts { error in
                    completion(error)
                }
            } else {
                self.eventsService.fetchEvents(
                    byLabel: Message.Location.inbox.labelID,
                    notificationMessageID: nil,
                    discardContactsMetadata: EventCheckRequest.isNoMetaDataForContactsEnabled,
                    completion: { result in
                        self.isFetching = false
                        completion(result.error)
                    })
                self.user.contactService.fetchContacts { _ in
                }
            }
        } else {
            completion(nil)
        }
    }

    func timerStart(_ run: Bool = true) {
        super.setupTimer(run)
    }

    func timerStop() {
        super.stopTimer()
    }

    private func fetchContacts() {
        if isFetching == false {
            isFetching = true

            if user.isNewEventLoopEnabled {
                dependencies.mailEventsPeriodicScheduler.triggerSpecialLoop(forSpecialLoopID: user.userID.rawValue)
                isFetching = false
            } else {
                self.eventsService.fetchEvents(
                    byLabel: Message.Location.inbox.labelID,
                    notificationMessageID: nil,
                    discardContactsMetadata: EventCheckRequest.isNoMetaDataForContactsEnabled,
                    completion: { _ in
                        self.isFetching = false
                    })
            }
        }
    }

    override func fireFetch() {
        self.fetchContacts()
    }

    func set(uiDelegate: ContactGroupsUIProtocol) {
        self.uiDelegate = uiDelegate
    }

    func setupDataSource() {
        contactGroupPublisher = .init(
            parameters: .init(userID: user.userID),
            dependencies: dependencies
        )
        contactGroupPublisher?.delegate = self
        contactGroupPublisher?.fetchLabels(labelType: .contactGroup)
    }

    func search(text: String?, searchActive: Bool) {
        self.isSearching = searchActive
        self.searchText = text

        guard self.isSearching else {
            self.filtered = []
            return
        }

        guard let query = text, !query.isEmpty else {
            self.filtered = self.labelEntities
            return
        }

        self.filtered = self.labelEntities.compactMap {
            let name = $0.name
            if name.range(of: query, options: [.caseInsensitive]) != nil {
                return $0
            }
            return nil
        }
    }

    func deleteGroups() -> Promise<Void> {
        return Promise {
            seal in

            if selectedGroupIDs.count > 0 {
                var arrayOfPromises: [Promise<Void>] = []
                for groupID in selectedGroupIDs {
                    arrayOfPromises.append(self.contactGroupService.queueDelete(groupID: groupID))
                }

                when(fulfilled: arrayOfPromises).done {
                    seal.fulfill(())
                    self.selectedGroupIDs.removeAll()
                }.catch(policy: .allErrors) {
                    error in
                    seal.reject(error)
                }
            } else {
                seal.fulfill(())
            }
        }
    }

    func count() -> Int {
        if self.isSearching {
            return filtered.count
        }
        return self.labelEntities.count
    }

    func dateForRow(at indexPath: IndexPath) -> (ID: String, name: String, color: String, count: Int, wasSelected: Bool, showEmailIcon: Bool) {
        if self.isSearching {
            guard self.filtered.count > indexPath.row else {
                return ("", "", "", 0, false, false)
            }

            let label = filtered[indexPath.row]
            return (label.labelID.rawValue, label.name, label.color, label.emailRelations.count, false, true)
        }
        guard let label = labelEntities[safe: indexPath.row] else {
            return ("", "", "", 0, false, false)
        }
        return (label.labelID.rawValue, label.name, label.color, label.emailRelations.count, false, true)
    }

    func labelForRow(at indexPath: IndexPath) -> LabelEntity? {
        if self.isSearching {
            guard self.filtered.count > indexPath.row else {
                return nil
            }
            let label = filtered[indexPath.row]
            return label
        }
        return labelEntities[safe: indexPath.row]
    }
}

extension ContactGroupsViewModelImpl: LabelListenerProtocol {
    func receivedLabels(labels: [LabelEntity]) {
        guard labelEntities != labels else {
            return
        }
        self.labelEntities = labels
        search(text: searchText, searchActive: isSearching)
        uiDelegate?.reloadTable()
    }
}
