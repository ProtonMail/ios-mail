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
import PromiseKit
import PMCommon

protocol Service: AnyObject {}
protocol HasLocalStorage {
    func cleanUp() -> Promise<Void>
    static func cleanUpAll() -> Promise<Void>
}

/// tempeary here. //device level service
let sharedServices: ServiceFactory = {
    let helper = ServiceFactory()
    // app cache service
    helper.add(AppCacheService.self, for: AppCacheService())
    helper.add(CoreDataService.self, for: CoreDataService.shared)
    #if !APP_EXTENSION
    // view model factory
    helper.add(ViewModelService.self, for: ViewModelServiceImpl(coreDataService: CoreDataService.shared))
    
    // push service
    helper.add(PushNotificationService.self, for: PushNotificationService())
    
    // from old ServiceFactory.default
    helper.add(AddressBookService.self, for: AddressBookService())
    helper.add(BugDataService.self, for: BugDataService(api: PMAPIService.unauthorized))
    #endif
    
    return helper
}()

final class ServiceFactory {
    
    ///this is the a tempary.
    static let `default` : ServiceFactory = sharedServices
    
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
