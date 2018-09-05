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
}

extension ContactGroupEditError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noEmailInGroup:
            return NSLocalizedString("No email is selected in the contact group", comment: "Contact group no email")
        case .noNameForGroup:
            return NSLocalizedString("No name is provided for the contact group", comment: "Contact group no name")
        }
    }
}

enum ContactGroupEditTableCellType
{
    case selectColor
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
    
    // create and edit
    func saveDetail() -> Promise<Void>
    
    // delete
    func deleteContactGroup()
    
    // table operation
    func getTotalSections() -> Int
    func getTotalRows(for section: Int) -> Int
    func getCellType(at indexPath: IndexPath) -> ContactGroupEditTableCellType
    func getEmail(at indexPath: IndexPath) -> (String, String)
}
