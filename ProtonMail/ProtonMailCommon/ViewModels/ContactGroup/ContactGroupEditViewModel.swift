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

protocol ContactGroupEditViewModel {
    var state: ContactGroupEditViewControllerState { get set }
    var contactGroup: ContactGroup { get set }
    var contactGroupEditViewDelegate: ContactGroupsViewModelDelegate! { get set }
    
    // general operation
    func fetchContactGroupDetail()
    func getContactGroupDetail() -> ContactGroup
    func addEmailsToContactGroup(emailList: [String])
    func removeEmailsFromContactGroup(emailList: [String])
    
    // create and edit
    func saveContactGroupDetail(name: String?, color: String?, emailList: [String]?)
    
    // delete
    func deleteContactGroup()
}
