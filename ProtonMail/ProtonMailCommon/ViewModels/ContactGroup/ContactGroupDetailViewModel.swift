//
//  ContactGroupDetailViewModel.swift
//  ProtonMail - Created on 2018/9/10.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation
import PromiseKit

protocol ContactGroupDetailViewModel {
    var user: UserManager { get }
    
    func getGroupID() -> String
    func getName() -> String
    func getColor() -> String
    func getTotalEmails() -> Int
    func getEmailIDs() -> Set<Email>
    func getTotalEmailString() -> String
    func getEmail(at indexPath: IndexPath) -> (emailID: String, name: String, email: String)
    
    func reload() -> Promise<Bool>
}
