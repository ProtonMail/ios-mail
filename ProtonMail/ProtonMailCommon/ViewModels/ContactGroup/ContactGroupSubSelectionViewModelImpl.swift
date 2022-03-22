//
//  ContactGroupSubSelectionViewModelImpl.swift
//  ProtonMail - Created on 2018/10/13.
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

class ContactGroupSubSelectionViewModelImpl: ContactGroupSubSelectionViewModel {
    private let user: UserManager
    private let groupName: String
    private let groupColor: String
    private var emailArray: [ContactGroupSubSelectionViewModelEmailInfomation]
    private var delegate: ContactGroupSubSelectionViewModelDelegate?

    /**
     Setup the sub-selection view of a specific group, at a specific state
     
     For every given contact group, we
     (1) Attempt to get all emails associated with the group name -> email list G
     - might be empty, if the group name was changed to others, etc.
     (2) For every selectedEmails, we compare it to G.
     - If the (name, email) pair is missing from G, we add it in, and mark as selected
     - If the (name, email) pair is in G, we mark it as selected
     (3) Produce an email array, sorted by name, then email
     */
    init(contactGroupName: String,
         selectedEmails: [DraftEmailData],
         user: UserManager,
         delegate: ContactGroupSubSelectionViewModelDelegate? = nil,
         labelsDataService: LabelsDataService) {
        self.user = user
        self.groupName = contactGroupName
        self.delegate = delegate

        var emailData: [ContactGroupSubSelectionViewModelEmailInfomation] = []

        // (1)
        if let label = labelsDataService.label(name: groupName),
            let emails = label.emails.allObjects as? [Email] {
            self.groupColor = label.color

            for email in emails {
                emailData.append(ContactGroupSubSelectionViewModelEmailInfomation.init(email: email.email,
                                                                                       name: email.name))
            }
        } else {
            // the group might be renamed or deleted
            self.groupColor = ColorManager.defaultColor
        }

        // (2)
        for member in selectedEmails {
            var found = false
            for (i, candidate) in emailData.enumerated() {
                if member.email == candidate.email &&
                    member.name == candidate.name &&
                    emailData[i].isSelected == false { // case: >= 2 identical name-email pair occurs
                    emailData[i].isSelected = true
                    found = true
                    break
                }
            }

            if found {
                continue
            }

            emailData.append(ContactGroupSubSelectionViewModelEmailInfomation(email: member.email,
                                                                              name: member.name,
                                                                              isSelected: true))
        }

        // (3)
        emailData.sort {
            if $0.name == $1.name {
                return $0.email < $1.email
            }
            return $0.name < $1.name
        }

        emailArray = emailData // query
    }

    /**
     - Returns: currently selected email addresses
    */
    func getCurrentlySelectedEmails() -> [DraftEmailData] {
        var result: [DraftEmailData] = []
        for e in emailArray {
            if e.isSelected {
                result.append(DraftEmailData.init(name: e.name, email: e.email))
            }
        }

        return result
    }

    /**
     Select the given email data
    */
    func select(indexPath: IndexPath) {
        emailArray[indexPath.row].isSelected = true

        // TODO: performance improvement
        if self.isAllSelected() {
            delegate?.reloadTable()
        }
    }

    /**
     Deselect the given email data
    */
    func deselect(indexPath: IndexPath) {
        // TODO: performance improvement
        let performDeselectInHeader = self.isAllSelected()

        emailArray[indexPath.row].isSelected = false

        if performDeselectInHeader {
             delegate?.reloadTable()
        }
    }

    /**
     - Returns: true if all of the email are selected
    */
    func isAllSelected() -> Bool {
        for i in emailArray.indices {
            if emailArray[i].isSelected == false {
                return false
            }
        }
        return true
    }

    func getGroupName() -> String {
        return self.groupName
    }

    func getTotalRows() -> Int {
        self.emailArray.count
    }

    func cellForRow(at indexPath: IndexPath) -> ContactGroupSubSelectionViewModelEmailInfomation {
        guard indexPath.row < self.getTotalRows() else {
            return ContactGroupSubSelectionViewModelEmailInfomation.init(email: "", name: "")
        }

        return self.emailArray[indexPath.row]
    }
}
