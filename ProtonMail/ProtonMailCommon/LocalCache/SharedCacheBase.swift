//
//  SharedCacheBase.swift
//  ProtonMail - Created on 6/5/15.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation


public class SharedCacheBase {
    fileprivate var userDefaults : UserDefaults!
    
    func getShared() -> UserDefaults! {
        return self.userDefaults
    }
    
    init () {
        self.userDefaults = UserDefaults(suiteName: Constants.App.APP_GROUP)
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
        return UserDefaults(suiteName: Constants.App.APP_GROUP)
    }
}
