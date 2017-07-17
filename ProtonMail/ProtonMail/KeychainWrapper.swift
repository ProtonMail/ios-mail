//
//  KeychainWrapper.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/17/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation

let sharedKeychain = KeychainWrapper()
final class KeychainWrapper {
    
    private var prefix : String!
    private var service : String!
    private var group : String!
    
    public func keychain() ->UICKeyChainStore! {
        return UICKeyChainStore(service: service, accessGroup: group)
    }
    
    init() {
        prefix = "6UN54H93QT."
        #if Enterprise
            group = prefix + "com.protonmail.protonmail"
            service = "com.protonmail"

        #else
            group = prefix + "ch.protonmail.protonmail"
            service = "ch.protonmail"
        #endif
    }
    
    deinit {
        //
    }
    
//    func setValue(_ value: Any?, forKey key: String)
//    {
//        self.userDefaults.setValue(value, forKey: key)
//        self.userDefaults.synchronize()
//    }
}
