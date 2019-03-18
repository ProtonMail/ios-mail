//
//  App.swift
//  ProtonMail - Created on 6/4/15.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation

struct Constants {
    
    /// use this to replace the version compare to decide feature on/off. this is easier to track
    enum Feature {
        static let snoozeOn : Bool = false
    }
    
    enum App {
        static let AuthCacheVersion : Int = 15 //this is user info cache
        
        static let SpaceWarningThreshold: Int = 80
        static let SpaceWarningThresholdDouble: Double = 80
        static let SplashVersion : Int = 1
        static let TourVersion : Int = 2

        static let AskTouchID : Int              = 1
        static var AppVersion : Int              = 1
        //
        //
        static let URL_Protocol : String = "https://"
        //static let URL_Protocol : String = "http://"
        
        //live api
        static let URL_HOST : String = "api.protonmail.ch"
        static let API_PATH : String = ""
        
        
        ///
        static let rediectURL = "https://protonmail.ch"
        
        //blue test
        //static let URL_HOST : String = "protonmail.blue"
        //static let API_PATH : String = "/api"
        //static let URL_HOST : String = "midnight.protonmail.blue"
        
        //live test api
        //static let URL_HOST : String = "test-api.protonmail.ch"
        
        //live dev api
        //static let URL_HOST : String = "dev-api.protonmail.ch"
        //    static let URL_HOST : String = "dev.protonmail.com"
        
        
        //static let URL_HOST : String = "http://127.0.0.1"  //http
        //static let URL_HOST : String = "http://protonmail.xyz"  //http
        
        //api options
        //static let API_PATH : String = "/api"
        
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
        
        static var DEBUG_OPTION : String {
            get {
                #if DEBUG
                return "" //"?XDEBUG_SESSION_START=\(18073)"
                #else
                return ""
                #endif
            }
        }
        
        //app share group
        static var APP_GROUP : String {
            get {
                #if Enterprise
                return "group.com.protonmail.protonmail"
                #else
                return "group.ch.protonmail.protonmail"
                #endif
            }
        }
        
        static let MaxNumberOfRecipients: Int = 100
    }
    

}

