//
//  KeychainWrapper.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/17/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation

let sharedKeychain = KeychainWrapper()
class KeychainWrapper {
    
    private var prefix : String!
    
    private func getKeychain() ->UICKeyChainStore! {
        return UICKeyChainStore(service: "com.protonmail", accessGroup: "")
    }
    
    init() {
        prefix = Bundle.main.infoDictionary!["AppIdentifierPrefix"] as! String
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
