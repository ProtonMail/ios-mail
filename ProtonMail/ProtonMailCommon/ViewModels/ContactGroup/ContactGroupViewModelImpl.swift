//
//  ContactGroupViewModelImpl.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/20.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class ContactGroupsViewModelImpl: ContactGroupsViewModel
{
    /**
     Fetch all contact groups from the server using API
     
     TODO: use event!
    */
    func fetchAllContactGroup()
    {
        // TODO: why error?
//        if let context = sharedCoreDataService.mainManagedObjectContext {
//            Label.deleteAll(inContext: context)
//        } else {
//            PMLog.D("Can't get context for fetchAllContactGroup")
//        }
        sharedLabelsDataService.fetchLabels(type: 2)
    }
}
