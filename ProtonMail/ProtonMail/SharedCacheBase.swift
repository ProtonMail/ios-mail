//
//  SharedCacheBase.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/5/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


public class SharedCacheBase {
    
    fileprivate var userDefaults : UserDefaults!
    
    func getShared() ->UserDefaults! {
        return self.userDefaults
    }
    
    init () {
        #if Enterprise
            self.userDefaults = UserDefaults(suiteName: "group.com.protonmail.protonmail")
        #else
            self.userDefaults = UserDefaults(suiteName: "group.ch.protonmail.protonmail")
        #endif
    }
        
    convenience init (shared : UserDefaults) {
        self.init()
        self.userDefaults = shared
    }
    
    deinit {
        //
    }
    
    func setValue(_ value: Any?, forKey key: String)
    {
        self.userDefaults.setValue(value, forKey: key)
        self.userDefaults.synchronize()
    }
    
    class func getDefault() ->UserDefaults! {
        #if Enterprise
            return UserDefaults(suiteName: "group.com.protonmail.protonmail")
        #else
            return UserDefaults(suiteName: "group.ch.protonmail.protonmail")
        #endif
    }
}
