//
//  BugDataService.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

class BugDataService {
    
    func reportBug(bug: String, completion: (NSError? -> Void)?) {
        var systemVersion = UIDevice.currentDevice().systemVersion;
        let model = UIDevice.currentDevice().model
        let mainBundle = NSBundle.mainBundle()
        let username = sharedUserDataService.username ?? ""
        let butAPI = BugReportRequest(os: model, osVersion: "\(systemVersion)", clientVersion: mainBundle.appVersion, title: "ProtonMail App bug report", desc: bug, userName: username, email: "\(username)@protonmail.ch")
        
        butAPI.call { (task, response, hasError) -> Void in
            completion?(response?.error)
        }
    }
}
