//
//  SharedCacheBase.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/5/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


class SharedCacheBase {
    
    fileprivate var userDefaults : UserDefaults!
    
    func getShared() ->UserDefaults! {
        return self.userDefaults
    }
        
    convenience init (shared : UserDefaults) {
        self.init()
        
//        shared.addSuite(named: "group.com.protonmail.protonmail")
//        self.userDefaults = shared
        
        self.userDefaults = UserDefaults(suiteName: "group.com.protonmail.protonmail")
    }
    
    deinit {
        //
    }
    
    func setValue(_ value: Any?, forKey key: String)
    {
        self.userDefaults.setValue(value, forKey: key)
        self.userDefaults.synchronize()
    }
}
