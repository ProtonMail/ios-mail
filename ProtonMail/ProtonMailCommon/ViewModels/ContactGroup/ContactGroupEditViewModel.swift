//
//  ContactGroupEditViewModel.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/21.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

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
    var emailIDs: NSMutableSet
    
    let originalName: String?
    let originalColor: String
    let originalEmailIDs: NSSet
    
    init(ID: String?,
         name: String?,
         color: String?,
         emailIDs: NSSet)
    {
        self.ID = ID
        self.name = name
        self.color = color ?? ColorManager.getRandomColor()
        self.emailIDs = NSMutableSet(set: emailIDs)
        
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
        
        if let originalEmailIDs = originalEmailIDs as? Set<Email>,
            let currentEmailIDs = emailIDs as? Set<Email> {
            if originalEmailIDs != currentEmailIDs {
                return true
            }
        } else {
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
    func setEmails(emails: NSSet)
    func setColor(newColor: String)
    
    func removeEmail(emailID: String)
    
    // get operations
    func getViewTitle() -> String
    func getName() -> String
    func getContactGroupID() -> String?
    func getColor() -> String
    func getEmails() -> NSSet
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
