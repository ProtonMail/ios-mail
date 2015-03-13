//
//  APIService+BugExtension.swift
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

extension APIService {
    
    func bug(bug: String, completion: CompletionBlock) {
        let path = "/bugs"
        let device = UIDevice.currentDevice()
        let mainBundle = NSBundle.mainBundle()
        let iOSLocation = 1000
        let username = sharedUserDataService.username ?? ""
        
        let parameters = [
            "bug_os" : "\(device.model) \(device.systemVersion)",
            "bug_browser" : mainBundle.appVersion,
            "bug_location" : iOSLocation,
            "bug_description" : bug,
            "bug_email" : "\(username)@protonmail.com"
        ]
        
        request(method: .POST, path: path, parameters: parameters, completion: completion)
    }
}
