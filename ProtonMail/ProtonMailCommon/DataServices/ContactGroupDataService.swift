//
//  ContactGroupDataService.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/20.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import CoreData
import Groot

let sharedContactGroupsDataService = ContactGroupsDataService()

/*
 Prototyping:
 1. Currently all of the operations are not saved.
 */

class ContactGroupsDataService {
    var contactGroups: [[String : Any]]?
    
    func fetchContactGroups() {
        let eventAPI = GetLabelsRequest(type: 2)
        
        eventAPI.call() {
            task, response, hasError in
            if response == nil {
                // TODO: handle error
            } else if let latestContactGroups = response?.labels {
                // TODO: save
                PMLog.D("[Contact Group API] result = \(latestContactGroups)")
                self.contactGroups = latestContactGroups
            } else {
                // TODO: handle error
            }
        }
        
        /*
         do {
         PMLog.D("[Contact Group API] before syncCall()")
         let ret = try eventAPI.syncCall()
         PMLog.D("[Contact Group API] after syncCall()")
         
         guard ret != nil else {
         PMLog.D("[Contact Group API] now return value")
         return
         }
         
         if ret?.error != nil {
         // TODO: handle error
         } else if let latestContactGroups = ret?.labels {
         // TODO: save
         PMLog.D("[Contact Group API] result = \(latestContactGroups)")
         self.contactGroups = latestContactGroups
         } else {
         // TODO: handle error
         }
         } catch {
         PMLog.D("[Contact Group API] error = \(error)")
         }
        */
    }
}
