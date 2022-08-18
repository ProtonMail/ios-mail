//
//  ContactGroupEditViewModel.swift
//  Proton Mail - Created on 2018/8/21.
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

protocol ContactGroupEditViewControllerDelegate: AnyObject {
    func update()
    func updateAddressSection()
}

enum ContactGroupEditTableCellType {
    case manageContact
    case email
    case deleteGroup
    case error
}

struct ContactGroupData {
    var ID: String?
    var name: String?
    var color: String
    var emailIDs: Set<EmailEntity>
    
    let originalName: String?
    let originalColor: String
    let originalEmailIDs: Set<EmailEntity>
    
    init(ID: String?,
         name: String?,
         color: String?,
         emailIDs: Set<EmailEntity>)
    {
        self.ID = ID
        self.name = name
        self.color = color ?? ColorManager.getRandomColor()
        self.emailIDs = emailIDs

        self.originalEmailIDs = emailIDs
        self.originalName = self.name
        self.originalColor = self.color
    }

    func hasChanged() -> Bool {
        if name != originalName {
            return true
        }

        if color != originalColor {
            return true
        }

        let currentEmailIDs = emailIDs
        if originalEmailIDs != currentEmailIDs {
            return true
        }

        return false
    }
}

protocol ContactGroupEditViewModel: AnyObject {
    var user: UserManager { get }
    // delegate
    var delegate: ContactGroupEditViewControllerDelegate? { get set }

    // set operations
    func setName(name: String)
    func setEmails(emails: Set<EmailEntity>)
    func setColor(newColor: String)
    
    func removeEmail(emailID: EmailID)
    
    // get operations
    func getViewTitle() -> String
    func getName() -> String
    func getColor() -> String
    func getEmails() -> Set<EmailEntity>
    func getSectionTitle(for: Int) -> String

    // create and edit
    func saveDetail() -> Promise<Void>
    func hasUnsavedChanges() -> Bool

    // delete
    func deleteContactGroup() -> Promise<Void>

    // table operation
    func getTotalSections() -> Int
    func getTotalRows(for section: Int) -> Int
    func getCellType(at indexPath: IndexPath) -> ContactGroupEditTableCellType
    func getEmail(at indexPath: IndexPath) -> (EmailID, String, String)
}
