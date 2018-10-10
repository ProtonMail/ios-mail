//
//  KeychainWrapper.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/17/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation
import UICKeyChainStore

let sharedKeychain = KeychainWrapper()
final class KeychainWrapper {
    
    private var prefix : String!
    private var service : String!
    private var group : String!
    
    public func keychain() ->UICKeyChainStore! {
        return UICKeyChainStore(service: service, accessGroup: group)
    }
    
    init() {
        
        #if Enterprise
            prefix = "6UN54H93QT."
            group = prefix + "com.protonmail.protonmail"
            service = "com.protonmail"

        #else
            prefix = "2SB5Z68H26."
            group = prefix + "ch.protonmail.protonmail"
            service = "ch.protonmail"
        #endif
        
        defer {
            self.migration()
        }
    }
    
    private func migration() {
        self.keychain()?.removeItem(forKey: UserDataService.Key.password)
    }
    
    deinit {
        //
    }
}
