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
    func setAuthorizationHeaderFieldWithCredential(credential: AuthCredential) {
        let accessToken = credential.accessToken ?? ""
        setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        setValue(credential.userID, forHTTPHeaderField: "x-pm-uid")
    }
    
    func setVersionHeader (apiVersion: Int, appVersion:Int) {
        //setValue("application/vnd.protonmail.api+json;apiversion=\(apiVersion);appversion=\(appVersion)", forHTTPHeaderField: "Accept")
    }
}