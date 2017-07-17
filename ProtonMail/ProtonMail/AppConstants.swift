//
//  AppConstants.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/4/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


public class AppConstants {
    
    
    static public let CacheVersion : Int = 96
    static public let AuthCacheVersion : Int = 12
    static public let SpaceWarningThreshold: Double = 80
    static public let SplashVersion : Int = 1
    static public let TourVersion : Int = 2
    
    static public let AskTouchID : Int = 1
    static public var AppVersion : Int = 1
    
    //
    static public let URL_Protocol : String = "https://"
    //static let URL_Protocol : String = "http://"
    
    //live api
//    static public let URL_HOST : String = "api.protonmail.ch"
    
    //live test api
    //static let URL_HOST : String = "test-api.protonmail.ch"
    
    //live dev api
    //static let URL_HOST : String = "dev-api.protonmail.ch"
    //static let URL_HOST : String = "dev.protonmail.com"
    
    //blue test
    static let URL_HOST : String = "protonmail.blue"
    //static let URL_HOST : String = "midnight.protonmail.blue"

    
    //static let URL_HOST : String = "http://127.0.0.1"  //http
    //static let URL_HOST : String = "http://protonmail.xyz"  //http
    
    //api options
    static let API_PATH : String = "/api"
//    static public let API_PATH : String = ""
    
    static public var API_HOST_URL : String {
        get {
            return URL_Protocol + URL_HOST
        }
    }
    
    static public var API_FULL_URL : String {
        get {
            return API_HOST_URL + API_PATH
        }
    }
    
    static public var getDebugOption : String {
        get {
            #if DEBUG
                return "" //"?XDEBUG_SESSION_START=\(18073)"
            #else
                return ""
            #endif
        }
    }
}

