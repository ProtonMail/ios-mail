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
    
    public func getShared() ->UserDefaults! {
        return self.userDefaults
    }
        
    public convenience init (shared : UserDefaults) {
        self.init()
        self.userDefaults = shared
    }
    
    deinit {
        //
    }
    
    public func setValue(_ value: Any?, forKey key: String)
    {
        self.userDefaults.setValue(value, forKey: key)
        self.userDefaults.synchronize()
    }
}
