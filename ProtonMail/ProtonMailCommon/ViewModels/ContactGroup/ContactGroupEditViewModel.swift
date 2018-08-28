//
//  ContactGroupEditViewModel.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/21.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

protocol ContactGroupEditViewModelDelegate {
    func updated()
}

enum ContactGroupTableCellType
{
    case selectColor
    case manageContact
    case email
    case deleteGroup
    case error
}

protocol ContactGroupEditViewModel {
    var contactGroupEditViewDelegate: ContactGroupsViewModelDelegate! { get set }
    
    // title
    func getViewTitle() -> String
    func getContactGroupName() -> String
    func getContactGroupID() -> String
    
    // fetch operation
    func fetchContactGroupEmailList()
    func getContactGroupDetail() -> ContactGroup
    func getCurrentColor() -> String?
    func getCurrentColorWithDefault() -> String
    func getEmailIDsInContactGroup() -> NSMutableSet
    
    // mutate operation
    func addEmailsToContactGroup(emailList: [String])
    func removeEmailsFromContactGroup(emailList: [String])
    func updateColor(newColor: String?)
    
    // create and edit
    func saveContactGroupDetail(name: String?, color: String?, emailList: [String]?)
    
    // delete
    func deleteContactGroup()
    
    // table operation
    func getTotalSections() -> Int
    func getTotalRows(for section: Int) -> Int
    func getCellType(at indexPath: IndexPath) -> ContactGroupTableCellType
    func getEmail(at indexPath: IndexPath) -> (String, String)
}
