//
//  ContactGroupDetailViewModel.swift
//  Proton Mail - Created on 2018/9/10.
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
import PromiseKit
import CoreData

protocol ContactGroupDetailVMProtocol {
    var reloadView: (() -> Void)? { get set }

    var user: UserManager { get }
    var groupID: LabelID { get }
    var name: String { get }
    var color: String { get }
    var emails: [EmailEntity] { get }

    func getTotalEmailString() -> String

    func reload() -> Bool
}

final class ContactGroupDetailViewModel: NSObject, ContactGroupDetailVMProtocol {
    private var contactGroup: LabelEntity
    /// the contact group label ID
    var groupID: LabelID { self.contactGroup.labelID }
    var name: String { self.contactGroup.name }
    var color: String { self.contactGroup.color }
    private(set) var emails: [EmailEntity] = []

    let user: UserManager
    private let fetchedController: NSFetchedResultsController<Label>

    var reloadView: (() -> Void)?
    
    init(user: UserManager, contactGroup: LabelEntity, labelsDataService: LabelsDataService) {
        self.user = user
        self.contactGroup = contactGroup
        fetchedController = labelsDataService.labelFetchedController(by: contactGroup.labelID)

        super.init()
        self.sortEmails(emailArray: contactGroup.emailRelations)

        try? fetchedController.performFetch()
        fetchedController.delegate = self
    }
    
    private func sortEmails(emailArray: [EmailEntity]) {
        self.emails = emailArray.sorted { first, second in
            if first.name == second.name {
                return first.email < second.email
            }
            return first.name < second.name
        }
    }
    
    func getTotalEmailString() -> String {
        let count = self.emails.count
        return String(format: LocalString._contact_groups_member_count_description, count)
    }

    /**
     Reloads the contact group from core data
     
     - Returns: Bool. true if the reloading succeeds because the contact group can be fetched from core data; false if the contact group has been deleted from core data
     */
    func reload() -> Bool {
        guard let label = self.fetchedController.fetchedObjects?.first else {
            // deleted case
            return false
        }
        self.contactGroup = LabelEntity(label: label)
        return true
    }
}

extension ContactGroupDetailViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let objects = controller.fetchedObjects as? [Label],
              let labelObject = objects.first else {
            return
        }
        self.contactGroup = LabelEntity(label: labelObject)
        self.sortEmails(emailArray: contactGroup.emailRelations)
        self.reloadView?()
    }
}
