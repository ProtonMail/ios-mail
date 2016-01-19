//
//  AppConstants.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/4/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


class AppConstants {
    
    static let CacheVersion : Int = 70
    static let AuthCacheVersion : Int = 9
    static let SpaceWarningThreshold: Double = 80
    
    static var AppVersion : Int = 1;
    //static let BaseURLString : String = "https://api.protonmail.ch"
    //static let BaseURLString : String = "http://protonmail.blue/api"
    //static let BaseURLString : String = "https://test-api.protonmail.ch"
    //static let BaseURLString : String = "http://feng.api.com"
    //static let BaseURLString : String = "https://dev-api.protonmail.ch"
    //static let BaseURLString : String = "http://protonmail.xyz"
    static let BaseURLString : String = "https://dev.protonmail.com"

    static let BaseAPIPath : String = "/api"
    //static let BaseAPIPath : String = ""

    static var getDebugOption : String {
        get {
            #if DEBUG
                return "?XDEBUG_SESSION_START=\(18073)"
            #else
                return ""
            #endif
        }
    }
}