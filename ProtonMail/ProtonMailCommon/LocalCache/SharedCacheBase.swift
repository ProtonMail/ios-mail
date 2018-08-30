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
        self.userDefaults = UserDefaults(suiteName: AppConstants.APP_GROUP)
    }
        
    convenience init (shared : UserDefaults) {
        self.init()
        self.userDefaults = shared
    }
    
    deinit {
        //
    }
    
    func setValue(_ value: Any?, forKey key: String) {
        self.userDefaults.setValue(value, forKey: key)
        self.userDefaults.synchronize()
    }
    
    class func getDefault() ->UserDefaults! {
        return UserDefaults(suiteName: AppConstants.APP_GROUP)
    }
}
