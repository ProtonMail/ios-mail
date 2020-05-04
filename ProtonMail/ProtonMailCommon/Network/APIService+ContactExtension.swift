//
//  APIService+ContactExtension.swift
//  ProtonMail
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

/// Contact extension
extension APIService {
    
    fileprivate struct ContactPath {
        static let base = "/contacts"
    }
    
    func contactDelete(contactID: String, completion: CompletionBlock?) {
        let path = ContactPath.base + "/delete"
        let parameters = ["IDs": [ contactID ] ]
        request(method: .put, path: path, parameters: parameters, headers: [HTTPHeader.apiVersion: 3], completion: completion)
    }
    
    func contactList(_ completion: CompletionBlock?) {
        let path = ContactPath.base
        request(method: .get, path: path, parameters: nil, headers: [HTTPHeader.apiVersion: 3], completion: completion)
    }
    
     func contactUpdate(contactID: String, name: String, email: String, completion: CompletionBlock?) {
         let path = ContactPath.base + "/\(contactID)"
         let parameters = parametersForName(name, email: email)
         request(method: .put, path: path, parameters: parameters, headers: [HTTPHeader.apiVersion: 3], completion: completion)
    }
    
    // MARK: - Private methods
    fileprivate func parametersForName(_ name: String, email: String) -> NSDictionary {
        return [
            "Name" : name,
            "Email" :email]
    }
}
