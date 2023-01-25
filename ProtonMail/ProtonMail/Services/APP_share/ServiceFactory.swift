//
//  ServiceFactory.swift
//  Proton Mail - Created on 12/13/18.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import PromiseKit
import ProtonCore_Services

protocol Service: AnyObject {}

/// temporary here: device level service
let sharedServices: ServiceFactory = {
    let helper = ServiceFactory()
    // app cache service
    let appCache = AppCacheService()
    helper.add(AppCacheService.self, for: appCache)
    appCache.restoreCacheWhenAppStart()
    if ProcessInfo.isRunningUnitTests {
        helper.add(CoreDataService.self, for: CoreDataService.shared)
        helper.add(LastUpdatedStore.self,
                   for: LastUpdatedStore(contextProvider: helper.get(by: CoreDataService.self)))
    }
    #if !APP_EXTENSION
    // from old ServiceFactory.default
    helper.add(AddressBookService.self, for: AddressBookService())
    #endif

    return helper
}()

final class ServiceFactory {

    /// this is the a tempary.
    static let `default`: ServiceFactory = sharedServices

    private var servicesDictionary: [String: Service] = [:]

    func add<T>(_ protocolType: T.Type, for instance: Service, with name: String? = nil) {
        let name = name ?? String(reflecting: protocolType)
        servicesDictionary[name] = instance
    }

    func get<T>(by type: T.Type = T.self) -> T {
        return get(by: String(reflecting: type))
    }

    func get<T>(by name: String) -> T {
        guard let service = servicesDictionary[name] as? T else {
            fatalError("firstly you have to add the service")
        }
        return service
    }
}
