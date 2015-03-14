//
//  UserInfo.swift
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

final class UserInfo: NSObject {
    let displayName: String
    let maxSpace: Int
    let notificationEmail: String
    let privateKey: String
    let publicKey: String
    let signature: String
    let usedSpace: Int
    let userStatus: Int
    
    required init(displayName: String?, maxSpace: Int?, notificationEmail: String?, privateKey: String?, publicKey: String?, signature: String?, usedSpace: Int?, userStatus: Int?) {
        self.displayName = displayName ?? ""
        self.maxSpace = maxSpace ?? 0
        self.notificationEmail = notificationEmail ?? ""
        self.privateKey = privateKey ?? ""
        self.publicKey = publicKey ?? ""
        self.signature = signature ?? ""
        self.usedSpace = usedSpace ?? 0
        self.userStatus = userStatus ?? 0
    }
}

// MARK: - NSCoding

extension UserInfo: NSCoding {
    
    private struct CoderKey {
        static let displayName = "displayName"
        static let maxSpace = "maxSpace"
        static let notificationEmail = "notificationEmail"
        static let privateKey = "privateKey"
        static let publicKey = "publicKey"
        static let signature = "signature"
        static let usedSpace = "usedSpace"
        static let userStatus = "userStatus"
    }
    
    convenience init(coder aDecoder: NSCoder) {
        self.init(
            displayName: aDecoder.decodeStringForKey(CoderKey.displayName),
            maxSpace: aDecoder.decodeIntegerForKey(CoderKey.maxSpace),
            notificationEmail: aDecoder.decodeStringForKey(CoderKey.notificationEmail),
            privateKey: aDecoder.decodeStringForKey(CoderKey.privateKey),
            publicKey: aDecoder.decodeStringForKey(CoderKey.publicKey),
            signature: aDecoder.decodeStringForKey(CoderKey.signature),
            usedSpace: aDecoder.decodeIntegerForKey(CoderKey.usedSpace),
            userStatus: aDecoder.decodeIntegerForKey(CoderKey.userStatus))
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(displayName, forKey: CoderKey.displayName)
        aCoder.encodeInteger(maxSpace, forKey: CoderKey.maxSpace)
        aCoder.encodeObject(notificationEmail, forKey: CoderKey.notificationEmail)
        aCoder.encodeObject(privateKey, forKey: CoderKey.privateKey)
        aCoder.encodeObject(publicKey, forKey: CoderKey.publicKey)
        aCoder.encodeObject(signature, forKey: CoderKey.signature)
        aCoder.encodeInteger(usedSpace, forKey: CoderKey.usedSpace)
        aCoder.encodeInteger(userStatus, forKey: CoderKey.userStatus)
    }
}