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
    case noContactGroupID
    
    case NSSetConversionToEmailArrayFailure
    case NSSetConversionToEmailSetFailure
    
    case addFailed
    case updateFailed
}

extension ContactGroupEditError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noEmailInGroup:
            return NSLocalizedString("No email is selected in the contact group",
                                     comment: "Contact group no email")
        case .noNameForGroup:
            return NSLocalizedString("No name is provided for the contact group",
                                     comment: "Contact group no name")
        case .noContactGroupID:
            return NSLocalizedString("No group ID is returned from the contact group API",
                                     comment: "Contact group no ID")
        case .NSSetConversionToEmailArrayFailure:
            return NSLocalizedString("Can't convert NSSet to array of Email",
                                     comment: "Contact group NSSet to array conversion failed")
        case .NSSetConversionToEmailSetFailure:
            return NSLocalizedString("Can't convert NSSet to Set of Email",
                                     comment: "Contact group NSSet to Set conversion failed")
        case .addFailed:
            return NSLocalizedString("Can't create contact group through API",
                                     comment: "Contact group creation failed")
        case .updateFailed:
            return NSLocalizedString("Can't update contact group through API",
                                     comment: "Contact group update failed")
            
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
    let originalEmailIDs: NSSet
    var emailIDs: NSSet
    
    init(ID: String? = nil,
         name: String? = nil,
         color: String? = nil,
         emailIDs: NSSet = NSSet())
    {
        self.ID = ID
        self.name = name
        self.color = color ?? ColorManager.defaultColor
        self.originalEmailIDs = emailIDs
        self.emailIDs = emailIDs
    }
}

protocol ContactGroupEditViewModel {
    // delegate
    var delegate: ContactGroupEditViewControllerDelegate? { get set }
    
    // set operations
    func setName(name: String)
    func setEmails(emails: NSSet)
    func setColor(newColor: String?)
    
    // get operations
    func getViewTitle() -> String
    func getName() -> String
    func getContactGroupID() -> String?
    func getColor() -> String
    func getEmails() -> NSSet
    func getSectionTitle(for: Int) -> String
    
    // create and edit
    func saveDetail() -> Promise<Void>
    
    // delete
    func deleteContactGroup() -> Promise<Void>
    
    // table operation
    func getTotalSections() -> Int
    func getTotalRows(for section: Int) -> Int
    func getCellType(at indexPath: IndexPath) -> ContactGroupEditTableCellType
    func getEmail(at indexPath: IndexPath) -> (String, String)
}
