//
//  ServiceFactory.swift
//  ProtonMail - Created on 12/13/18.
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

protocol Service: AnyObject {}

final class ServiceFactory {
    
    ///this is the a tempary.
    static let `default` : ServiceFactory = {
        let helper = ServiceFactory()
        helper.add(AppCacheService.self, for: AppCacheService())
        helper.add(AddressBookService.self, for: AddressBookService())
        helper.add(APIService.self, for: APIService.shared)
        
        ///TEST
        let apiService : APIService = helper.get()
        let addrService: AddressBookService = helper.get()
//        helper.add(ContactDataService.self, for: ContactDataService(api:apiService))
        helper.add(BugDataService.self, for: BugDataService(api: apiService))
        
        ///
//        let msgService: MessageDataService = MessageDataService(api: apiService)
//        helper.add(MessageDataService.self, for: msgService)
//
        return helper
    }()
    
    private var servicesDictionary: [String: Service] = [:]
    
    public func add<T>(_ type: T.Type, with name: String? = nil, constructor: () -> Service) {
        self.add(type, for: constructor(), with: name)
    }
    
    public func add<T>(_ protocolType: T.Type, for instance: Service, with name: String? = nil) {
        let name = name ?? String(reflecting: protocolType)
        servicesDictionary[name] = instance
    }
    
    public func get<T>(by type: T.Type = T.self) -> T {
        return get(by: String(reflecting: type))
    }
    
    public func get<T>(by name: String) -> T {
        guard let service = servicesDictionary[name] as? T else {
            fatalError("firstly you have to add the service")
        }
        return service
    }
}
