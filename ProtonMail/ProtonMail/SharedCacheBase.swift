//
//  SharedCacheBase.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/5/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


class  SharedCacheBase {
    
    private var userDefaults : NSUserDefaults!
    
    func getShared() ->NSUserDefaults! {
        return self.userDefaults
    }
        
    init (shared : NSUserDefaults) {
        self.userDefaults = shared
    }
    
    deinit {
        //
    }
    
    func setValue(value: AnyObject?, forKey key: String)
    {
        self.userDefaults.setValue(value, forKey: key)
        self.userDefaults.synchronize()
    }
}