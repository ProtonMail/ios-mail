//
//  AppConstants.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/4/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


class AppConstants {
    
    
    static let CacheVersion : Int = 85
    static let AuthCacheVersion : Int = 12
    static let SpaceWarningThreshold: Double = 80
    static let SplashVersion : Int = 1
    static let TourVersion : Int = 2
    
    static let AskTouchID : Int = 1
    static var AppVersion : Int = 1
    
    //
    static let URL_Protocol : String = "https://"
    //static let URL_Protocol : String = "http://"
    
    //live api
    //static let URL_Host : String = "api.protonmail.ch"
    
    //live test api
    //static let URL_Host : String = "test-api.protonmail.ch"
    
    //live dev api
    //static let URL_Host : String = "dev-api.protonmail.ch"
    static let URL_HOST : String = "dev.protonmail.com"
    
    //blue test
    //static let URL_Host : String = "protonmail.blue"
    //static let URL_Host : String = "midnight.protonmail.blue"

    
    //static let URL_Host : String = "http://127.0.0.1"  //http
    //static let URL_Host : String = "http://protonmail.xyz"  //http
    
    //api options
    static let API_PATH : String = "/api"
    //static let API_PATH : String = ""
    
    static var API_HOST_URL : String {
        get {
            return URL_Protocol + URL_HOST
        }
    }
    
    static var API_FULL_URL : String {
        get {
            return API_HOST_URL + API_PATH
        }
    }
    
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

