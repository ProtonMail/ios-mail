//
//  ContactGroupViewModelImpl.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/20.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

protocol ContactGroupsViewModelDelegate {
    func updated()
}

class ContactGroupsViewModelImpl: ContactGroupsViewModel
{
    var cachedContactGroups: [ContactGroup]?
    var contactGroupsViewControllerDelegate: ContactGroupsViewModelDelegate?
    
    /**
     Fetch all contact groups that is in the user's contact
     
     Only ID, name, and color, etc. is fetched at this stage (no email list)
    */
    func fetchContactGroups() {
        let completionHandler = {
            (contactGroups: [[String : Any]]?) -> Void in
            
            // TODO: parse the data into array of label struct
            self.cachedContactGroups = [ContactGroup]()
            if let data = contactGroups {
                for contactGroup in data {
                    let extractedContactGroup = ContactGroup(ID: contactGroup["ID"] as? String,
                                                             name: contactGroup["Name"] as? String,
                                                             color: contactGroup["Color"] as? String)
                    self.cachedContactGroups!.append(extractedContactGroup)
                }
            }
            
            self.contactGroupsViewControllerDelegate?.updated()
        }
        
        // get the contact group listing
        sharedContactGroupsDataService.fetchContactGroups(completionHandler: completionHandler)
    }
    
    func getNumberOfRowsInSection() -> Int {
        if let data = cachedContactGroups {
            return data.count
        }
        return 0
    }
    
    func getContactGroupData(at indexPath: IndexPath) -> ContactGroup? {
        guard cachedContactGroups != nil else {
            return nil
        }
        guard indexPath.item < cachedContactGroups?.count else {
            return nil
        }
        
        return cachedContactGroups?[indexPath.item]
    }
    
}
