//
//  AppCacheService.swift
//  ProtonMail - Created on 12/4/18.
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

class AppCacheService: Service {
    
    enum Constants {
//        static let AuthCacheVersion : Int = 15 //this is user info cache
//        static let SpaceWarningThreshold: Int = 80
//        static let SpaceWarningThresholdDouble: Double = 80
//        static let SplashVersion : Int = 1
//        static let TourVersion : Int = 2
//
//        static let AskTouchID : Int              = 1
//        static var AppVersion : Int              = 1
    }
    private let userDefault = SharedCacheBase()
    private let coreDataCache: CoreDataCache
    private let appCache: AppCache
    
    init() {
        self.coreDataCache = CoreDataCache()
        self.appCache = AppCache()
    }
    
    func restoreCacheWhenAppStart() {
        self.coreDataCache.run()
        self.appCache.run()
    }
    
    func restoreCacheAfterAuthorized() {
        
    }
    
    func logout() {
        
    }
}

