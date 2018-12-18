//
//  ServiceFactory.swift
//  ProtonMail - Created on 12/13/18.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

import Foundation

protocol Service: AnyObject {}

final class ServiceFactory {
    
    static let `default` : ServiceFactory = {
        let helper = ServiceFactory()
        helper.add(AppCacheService.self, for: AppCacheService())
        helper.add(AddressBookService.self, for: AddressBookService())
        ///TEST
        let addrService: AddressBookService = helper.get()
        helper.add(ContactDataService.self, for: ContactDataService(addressBookService: addrService))
        helper.add(BugDataService.self, for: BugDataService())
        
        ///
        let msgService: MessageDataService = MessageDataService()
        helper.add(MessageDataService.self, for: msgService)
        
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
