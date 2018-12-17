//
//  ContactGroupEditViewModel.swift
//  ProtonMail - Created on 2018/8/21.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation
import PromiseKit

protocol ContactGroupEditViewControllerDelegate: class {
    func update()
}

enum ContactGroupEditError: Error
{
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
