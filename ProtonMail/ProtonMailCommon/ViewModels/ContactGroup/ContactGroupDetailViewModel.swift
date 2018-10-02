//
//  ContactGroupDetailViewModel.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/9/10.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import PromiseKit

protocol ContactGroupDetailViewModel
{
    func getGroupID() -> String
    func getName() -> String
    func getColor() -> String
    func getTotalEmails() -> Int
    func getEmailIDs() -> NSSet
    func getTotalEmailString() -> String
    func getEmail(at indexPath: IndexPath) -> (name: String, email: String)
    
    func reload() -> Promise<Bool>
}
