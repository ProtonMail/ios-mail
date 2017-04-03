//
//  AFHTTPRequestSerializerExtension.swift
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

extension AFHTTPRequestSerializer {
    func setAuthorizationHeaderFieldWithCredential(_ credential: AuthCredential) {
        let accessToken = credential.token ?? ""
        setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        setValue(credential.userID, forHTTPHeaderField: "x-pm-uid")
    }
    
    func setVersionHeader (_ apiVersion: Int, appVersion:Int) {
        let appversion = "iOS_\(Bundle.main.majorVersion)"
        setValue(appversion, forHTTPHeaderField: "x-pm-appversion")
        setValue("1", forHTTPHeaderField: "x-pm-apiversion")
    }
}
