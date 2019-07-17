//
//  UserInfo.swift
//  ProtonMail
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


