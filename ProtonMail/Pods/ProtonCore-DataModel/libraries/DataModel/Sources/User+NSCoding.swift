//
//  User+NSCoding.swift
//  ProtonCore-DataModel - Created on 17/03/2020.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

// MARK: - NSCoding
extension UserInfo: NSCoding {
    
    fileprivate struct CoderKey {
        static let displayName = "displayName"
        static let maxSpace = "maxSpace"
        static let notificationEmail = "notificationEmail"
        static let signature = "signature"
        static let usedSpace = "usedSpace"
        static let userStatus = "userStatus"
        static let userAddress = "userAddresses"
        
        static let autoSaveContact = "autoSaveContact"
        static let language = "language"
        static let maxUpload = "maxUpload"
        static let notify = "notify"
        static let showImages = "showImages"
        
        static let swipeLeft = "swipeLeft"
        static let swipeRight = "swipeRight"
        
        static let role = "role"
        
        static let delinquent = "delinquent"
        
        static let userKeys = "userKeys"
        static let userId = "userId"
        
        static let attachPublicKey = "attachPublicKey"
        static let sign = "sign"
        
        static let linkConfirmation = "linkConfirmation"
        
        static let credit = "credit"
        static let currency = "currency"
        static let subscribed = "subscribed"
        
        static let pwdMode = "passwordMode"
        static let twoFA = "2faStatus"
        
        static let enableFolderColor = "enableFolderColor"
        static let inheritParentFolderColor = "inheritParentFolderColor"
        static let groupingMode = "groupingMode"
        static let weekStart = "weekStart"
        static let delaySendSeconds = "delaySendSeconds"
    }
    
    public convenience init(coder aDecoder: NSCoder) {
        self.init(
            displayName: aDecoder.string(forKey: CoderKey.displayName),
            maxSpace: aDecoder.decodeInt64(forKey: CoderKey.maxSpace),
            notificationEmail: aDecoder.string(forKey: CoderKey.notificationEmail),
            signature: aDecoder.string(forKey: CoderKey.signature),
            usedSpace: aDecoder.decodeInt64(forKey: CoderKey.usedSpace),
            userAddresses: aDecoder.decodeObject(forKey: CoderKey.userAddress) as? [Address],
            
            autoSC: aDecoder.decodeInteger(forKey: CoderKey.autoSaveContact),
            language: aDecoder.string(forKey: CoderKey.language),
            maxUpload: aDecoder.decodeInt64(forKey: CoderKey.maxUpload),
            notify: aDecoder.decodeInteger(forKey: CoderKey.notify),
            showImage: aDecoder.decodeInteger(forKey: CoderKey.showImages),
            
            swipeL: aDecoder.decodeInteger(forKey: CoderKey.swipeLeft),
            swipeR: aDecoder.decodeInteger(forKey: CoderKey.swipeRight),
            
            role: aDecoder.decodeInteger(forKey: CoderKey.role),
            
            delinquent: aDecoder.decodeInteger(forKey: CoderKey.delinquent),
            
            keys: aDecoder.decodeObject(forKey: CoderKey.userKeys) as? [Key],
            userId: aDecoder.string(forKey: CoderKey.userId),
            sign: aDecoder.decodeInteger(forKey: CoderKey.sign),
            attachPublicKey: aDecoder.decodeInteger(forKey: CoderKey.attachPublicKey),
            
            linkConfirmation: aDecoder.string(forKey: CoderKey.linkConfirmation),
            
            credit: aDecoder.decodeInteger(forKey: CoderKey.credit),
            currency: aDecoder.string(forKey: CoderKey.currency),
            
            pwdMode: aDecoder.decodeInteger(forKey: CoderKey.pwdMode),
            twoFA: aDecoder.decodeInteger(forKey: CoderKey.twoFA),
            enableFolderColor: aDecoder.decodeInteger(forKey: CoderKey.enableFolderColor),
            inheritParentFolderColor: aDecoder.decodeInteger(forKey: CoderKey.inheritParentFolderColor),
            subscribed: aDecoder.decodeInteger(forKey: CoderKey.subscribed),
            groupingMode: aDecoder.decodeInteger(forKey: CoderKey.groupingMode),
            weekStart: aDecoder.decodeInteger(forKey: CoderKey.weekStart),
            delaySendSeconds: aDecoder.decodeInteger(forKey: CoderKey.delaySendSeconds)
        )
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(maxSpace, forKey: CoderKey.maxSpace)
        aCoder.encode(notificationEmail, forKey: CoderKey.notificationEmail)
        aCoder.encode(usedSpace, forKey: CoderKey.usedSpace)
        aCoder.encode(userAddresses, forKey: CoderKey.userAddress)
        
        aCoder.encode(language, forKey: CoderKey.language)
        aCoder.encode(maxUpload, forKey: CoderKey.maxUpload)
        aCoder.encode(notify, forKey: CoderKey.notify)
        
        aCoder.encode(role, forKey: CoderKey.role)
        aCoder.encode(delinquent, forKey: CoderKey.delinquent)
        aCoder.encode(userKeys, forKey: CoderKey.userKeys)
        
        // get from mail settings
        aCoder.encode(displayName, forKey: CoderKey.displayName)
        aCoder.encode(defaultSignature, forKey: CoderKey.signature)
        aCoder.encode(autoSaveContact, forKey: CoderKey.autoSaveContact)
        aCoder.encode(showImages.rawValue, forKey: CoderKey.showImages)
        aCoder.encode(swipeLeft, forKey: CoderKey.swipeLeft)
        aCoder.encode(swipeRight, forKey: CoderKey.swipeRight)
        aCoder.encode(userId, forKey: CoderKey.userId)
        aCoder.encode(enableFolderColor, forKey: CoderKey.enableFolderColor)
        aCoder.encode(inheritParentFolderColor, forKey: CoderKey.inheritParentFolderColor)
        
        aCoder.encode(sign, forKey: CoderKey.sign)
        aCoder.encode(attachPublicKey, forKey: CoderKey.attachPublicKey)
        
        aCoder.encode(linkConfirmation.rawValue, forKey: CoderKey.linkConfirmation)
        
        aCoder.encode(credit, forKey: CoderKey.credit)
        aCoder.encode(currency, forKey: CoderKey.currency)
        aCoder.encode(subscribed, forKey: CoderKey.subscribed)
        
        aCoder.encode(passwordMode, forKey: CoderKey.pwdMode)
        aCoder.encode(twoFactor, forKey: CoderKey.twoFA)
        aCoder.encode(groupingMode, forKey: CoderKey.groupingMode)
        aCoder.encode(weekStart, forKey: CoderKey.weekStart)
        aCoder.encode(delaySendSeconds, forKey: CoderKey.delaySendSeconds)
    }
}

extension UserInfo {
    public func archive() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }
    
    public static func unarchive(_ data: Data?) -> UserInfo? {
        guard let data = data else { return nil }
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? UserInfo
    }
}
