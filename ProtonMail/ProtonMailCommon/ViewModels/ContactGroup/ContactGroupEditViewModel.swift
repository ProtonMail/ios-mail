//
//  ContactGroupEditViewModel.swift
//  ProtonMail - Created on 2018/8/21.
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
import PromiseKit

protocol ContactGroupEditViewControllerDelegate: class {
    func update()
}

enum ContactGroupEditError: Error {
    case noEmailInGroup
    case noNameForGroup
    
    case updateFailed
    
    case cannotGetCoreDataContext
    
    case InternalError
    case TypeCastingError
}

extension ContactGroupEditError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noEmailInGroup:
            return LocalString._contact_groups_no_email_selected
        case .noNameForGroup:
            return LocalString._contact_groups_no_name_entered
        case .InternalError:
            return LocalString._internal_error
        case .TypeCastingError:
            return LocalString._type_casting_error
            
        case .updateFailed:
            return LocalString._contact_groups_api_update_error
        case .cannotGetCoreDataContext:
            return LocalString._cannot_get_coredata_context
        }
    }
}

enum ContactGroupEditTableCellType
{
    case manageContact
    case email
    case deleteGroup
    case error
}

struct ContactGroupData
{
    var ID: String?
    var name: String?
    var color: String
    var emailIDs: Set<Email>
    
    let originalName: String?
    let originalColor: String
    let originalEmailIDs: Set<Email>
    
    init(ID: String?,
         name: String?,
         color: String?,
         emailIDs: Set<Email>)
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

protocol ContactGroupEditViewModel {
    var user: UserManager { get }
    // delegate
    var delegate: ContactGroupEditViewControllerDelegate? { get set }
    
    // set operations
    func setName(name: String)
    func setEmails(emails: Set<Email>)
    func setColor(newColor: String)
    
    func removeEmail(emailID: String)
    
    // get operations
    func getViewTitle() -> String
    func getName() -> String
    func getContactGroupID() -> String?
    func getColor() -> String
    func getEmails() -> Set<Email>
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
    func getEmail(at indexPath: IndexPath) -> (String, String, String)
}
