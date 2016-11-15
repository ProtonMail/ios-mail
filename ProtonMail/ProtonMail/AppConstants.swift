//
//  AppConstants.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/4/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


class AppConstants {
    
    
    static let CacheVersion : Int = 82
    static let AuthCacheVersion : Int = 12
    static let SpaceWarningThreshold: Double = 80
    static let SplashVersion : Int = 1
    static let TourVersion : Int = 2
    
    static let AskTouchID : Int = 1
    static var AppVersion : Int = 1;
    
    //live api
    //static let BaseURLString : String = "https://api.protonmail.ch"
    
    //live test api
    //static let BaseURLString : String = "https://test-api.protonmail.ch"
    
    //live dev api
    //static let BaseURLString : String = "https://dev-api.protonmail.ch"
    static let BaseURLString : String = "https://dev.protonmail.com"
    
    //blue test
    //static let BaseURLString : String = "http://protonmail.blue"
    //static let BaseURLString : String = "https://midnight.protonmail.blue"
    
    //static let BaseURLString : String = "http://127.0.0.1"
    //static let BaseURLString : String = "http://protonmail.xyz"
    
    //api options
    static let BaseAPIPath : String = "/api"
    //static let BaseAPIPath : String = ""
    
    static var getDebugOption : String {
        get {
            #if DEBUG
                return "" //"?XDEBUG_SESSION_START=\(18073)"
            #else
                return ""
            #endif
        }
    }
}

