//
//  UserInfo.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation

@objc(User)
final class User : NSObject {
    var auth : AuthCredential
    var userInfo : UserInfo?
    
    // init from cache
    init(auth: AuthCredential) {
        self.auth = auth
    }
    
    /// Update user
    func set(userInfo : UserInfo?) {
        self.userInfo = userInfo
    }
}

// MARK: - NSCoding
extension User: NSCoding {
    
    fileprivate struct CoderKey {
        static let authInfo = "User.AuthInfo"
        static let userInfo = "User.UserInfo"
    }
    
    func archive() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }
    
    static func unarchive(_ data: Data?) -> UserInfo? {
        guard let data = data else { return nil }
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? UserInfo
    }
    
    convenience init?(coder aDecoder: NSCoder) {
        guard let auth = aDecoder.decodeObject(forKey: CoderKey.authInfo) as? AuthCredential else {
            return nil
        }
        self.init( auth: auth )
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.auth, forKey: CoderKey.authInfo)
//        aCoder.encode(maxSpace, forKey: CoderKey.maxSpace)
//        aCoder.encode(notificationEmail, forKey: CoderKey.notificationEmail)
//        aCoder.encode(usedSpace, forKey: CoderKey.usedSpace)
//        aCoder.encode(userAddresses, forKey: CoderKey.userAddress)
//
//        aCoder.encode(language, forKey: CoderKey.language)
//        aCoder.encode(maxUpload, forKey: CoderKey.maxUpload)
//        aCoder.encode(notify, forKey: CoderKey.notify)
//
//        aCoder.encode(role, forKey: CoderKey.role)
//        aCoder.encode(delinquent, forKey: CoderKey.delinquent)
//        aCoder.encode(userKeys, forKey: CoderKey.userKeys)
//
//        //get from mail settings
//        aCoder.encode(displayName, forKey: CoderKey.displayName)
//        aCoder.encode(defaultSignature, forKey: CoderKey.signature)
//        aCoder.encode(autoSaveContact, forKey: CoderKey.autoSaveContact)
//        aCoder.encode(showImages.rawValue, forKey: CoderKey.showImages)
//        aCoder.encode(swipeLeft, forKey: CoderKey.swipeLeft)
//        aCoder.encode(swipeRight, forKey: CoderKey.swipeRight)
//        aCoder.encode(userId, forKey: CoderKey.userId)
//
//
//        aCoder.encode(sign, forKey: CoderKey.sign)
//        aCoder.encode(attachPublicKey, forKey: CoderKey.attachPublicKey)
//
//        aCoder.encode(linkConfirmation.rawValue, forKey: CoderKey.linkConfirmation)
//
//        aCoder.encode(credit, forKey: CoderKey.credit)
//        aCoder.encode(currency, forKey: CoderKey.currency)
        
        // add a clean up function to remove lagcy code
    }

}


