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
import Crypto
import PMCommon



//struct ShowImages : OptionSet {
//    let rawValue: Int
//    // 0 for none, 1 for remote, 2 for embedded, 3 for remote and embedded (
//    static let none     = ShowImages([])
//    static let remote   = ShowImages(rawValue: 1 << 0) // auto load remote images
//    static let embedded = ShowImages(rawValue: 1 << 1) // auto load embedded images
//}

//@objc(UserInfo)
//final class UserInfo : NSObject {
//
//    //1.9.0 phone local cache
//    var language : String
//
//    //1.9.1 user object
//    var delinquent : Int
//    var role : Int
//    var maxSpace: Int64
//    var usedSpace: Int64
//    var maxUpload: Int64
//    var userId: String
//
//    var userKeys: [Key] //user key
//
//    // 1.11.12 user object
//    var credit: Int
//    var currency: String
//
//    //1.9.1 mail settings
//    var displayName: String = ""
//    var defaultSignature: String = ""
//    var autoSaveContact : Int = 0
//    var showImages : ShowImages = .none
//    var autoShowRemote : Bool {
//        get {
//            return self.showImages.contains(.remote)
//        }
//    }
//    var swipeLeft : Int = 3
//    var swipeRight : Int = 0
//    var linkConfirmation: LinkOpeningMode = .confirmationAlert
//
//    var attachPublicKey : Int = 0
//    var sign : Int = 0
//
//    var swipeLeftAction: MessageSwipeAction! {
//        return MessageSwipeAction(rawValue: self.swipeLeft)
//    }
//    var swipeRightAction: MessageSwipeAction! {
//        return MessageSwipeAction(rawValue: self.swipeRight)
//    }
//
//
//    //1.9.1 user settings
//    var notificationEmail: String = ""
//    var notify: Int = 0
//
//    //1.9.0 get from addresses route
//    var userAddresses: [Address] = [Address]()
//
//
//    //1.12.0
//    var passwordMode: Int = 1
//    var twoFactor: Int = 0
//
//    static func getDefault() -> UserInfo {
//        return .init(maxSpace: 0, usedSpace: 0, language: "",
//                     maxUpload: 0, role: 0, delinquent: 0,
//                     keys: nil, userId: "", linkConfirmation: 0,
//                     credit: 0, currency: "")
//    }
//
//    var isPaid: Bool {
//        return self.role > 0 ? true : false
//    }
//
//    // init from cache
//    required init(
//        displayName: String?, maxSpace: Int64?, notificationEmail: String?, signature: String?,
//        usedSpace: Int64?, userAddresses: [Address]?,
//        autoSC:Int?, language:String?, maxUpload:Int64?, notify:Int?, showImage:Int?,  //v1.0.8
//        swipeL:Int?, swipeR:Int?,  //v1.1.4
//        role:Int?,
//        delinquent : Int?,
//        keys : [Key]?,
//        userId: String?,
//        sign: Int?,
//        attachPublicKey: Int?,
//        linkConfirmation: String?,
//        credit: Int?,
//        currency: String?,
//        pwdMode: Int?,
//        twoFA: Int?)
//    {
//        self.maxSpace = maxSpace ?? 0
//        self.usedSpace = usedSpace ?? 0
//        self.language = language ?? "en_US"
//        self.maxUpload = maxUpload ?? 0
//        self.role = role ?? 0
//        self.delinquent = delinquent ?? 0
//        self.userKeys = keys ?? [Key]()
//        self.userId = userId ?? ""
//
//        // get from user settings
//        self.notificationEmail = notificationEmail ?? ""
//        self.notify = notify ?? 0
//
//        // get from mail settings
//        self.displayName = displayName ?? ""
//        self.defaultSignature = signature ?? ""
//        self.autoSaveContact  = autoSC ?? 0
//        self.showImages = ShowImages(rawValue: showImage ?? 0)
//        self.swipeLeft = swipeL ?? 3
//        self.swipeRight = swipeR ?? 0
//
//        self.sign = sign ?? 0
//        self.attachPublicKey = attachPublicKey ?? 0
//
//        // addresses
//        self.userAddresses = userAddresses ?? [Address]()
//
//        if let linkConfirmation = linkConfirmation {
//            self.linkConfirmation = LinkOpeningMode(rawValue: linkConfirmation) ?? .confirmationAlert
//        }
//
//        self.credit = credit ?? 0
//        self.currency = currency ?? "USD"
//
//        self.passwordMode = pwdMode ?? 1
//        self.twoFactor = twoFA ?? 0
//    }
//
//    // init from api
//    required init(maxSpace: Int64?, usedSpace: Int64?,
//                  language:String?, maxUpload:Int64?,
//                  role:Int?,
//                  delinquent : Int?,
//                  keys : [Key]?,
//                  userId: String?,
//                  linkConfirmation : Int?,
//                  credit: Int?,
//                  currency: String?) {
//        self.maxSpace = maxSpace ?? 0
//        self.usedSpace = usedSpace ?? 0
//        self.language = language ?? "en_US"
//        self.maxUpload = maxUpload ?? 0
//        self.role = role ?? 0
//        self.delinquent = delinquent ?? 0
//        self.userId = userId ?? ""
//        self.userKeys = keys ?? [Key]()
//        self.linkConfirmation = linkConfirmation == 0 ? .openAtWill : .confirmationAlert
//        self.credit = credit ?? 0
//        self.currency = currency ?? "USD"
//    }
//
//    /// Update user addresses
//    ///
//    /// - Parameter addresses: new addresses
//    func set(addresses : [Address]) {
//        self.userAddresses = addresses
//    }
//
//    /// set User, copy the data from input user object
//    ///
//    /// - Parameter userinfo: New user info
//    func set(userinfo : UserInfo) {
//        self.maxSpace = userinfo.maxSpace
//        self.usedSpace = userinfo.usedSpace
//        self.language = userinfo.language
//        self.maxUpload = userinfo.maxUpload
//        self.role = userinfo.role
//        self.delinquent = userinfo.delinquent
//        self.userId = userinfo.userId
//        self.linkConfirmation = userinfo.linkConfirmation
//        self.userKeys = userinfo.userKeys
//    }
//
//    func parse(userSettings: [String : Any]?) {
//        if let settings = userSettings {
//            if let email = settings["Email"] as? [String : Any] {
//                self.notificationEmail = email["Value"] as? String ?? ""
//                self.notify = email["Notify"] as? Int ?? 0
//            }
//
//            if let pwdMode = settings["PasswordMode"] as? Int {
//                self.passwordMode = pwdMode
//            } else {
//                if let pwd = settings["Password"] as? [String : Any] {
//                    if let mode = pwd["Mode"] as? Int {
//                        self.passwordMode = mode
//                    }
//                }
//            }
//
//            if let twoFA = settings["2FA"]  as? [String : Any] {
//                self.twoFactor = twoFA["Enabled"] as? Int ?? 0
//            }
//        }
//    }
//
//    func parse(mailSettings: [String : Any]?) {
//        if let settings = mailSettings {
//            self.displayName = settings["DisplayName"] as? String ?? "'"
//            self.defaultSignature = settings["Signature"] as? String ?? ""
//            self.autoSaveContact  = settings["AutoSaveContacts"] as? Int ?? 0
//            self.showImages = ShowImages(rawValue: settings["ShowImages"] as? Int ?? 0)
//            self.swipeLeft = settings["SwipeLeft"] as? Int ?? 3
//            self.swipeRight = settings["SwipeRight"] as? Int ?? 0
//            self.linkConfirmation = settings["ConfirmLink"] as? Int == 0 ? .openAtWill : .confirmationAlert
//
//            self.attachPublicKey = settings["AttachPublicKey"] as? Int ?? 0
//            self.sign = settings["Sign"] as? Int ?? 0
//        }
//    }
//
//    func firstUserKey() -> Key? {
//        if self.userKeys.count > 0 {
//            return self.userKeys[0]
//        }
//        return nil
//    }
//
//    func getPrivateKey(by keyID: String?) -> String? {
//        if let keyID = keyID {
//            for userkey in self.userKeys {
//                if userkey.key_id == keyID {
//                    return userkey.private_key
//                }
//            }
//        }
//        return firstUserKey()?.private_key
//    }
//
//    var newSchema : Bool {
//        for k in addressKeys {
//            if k.newSchema {
//                return true
//            }
//        }
//        return false
//    }
//
//    var addressPrivateKeys : Data {
//        var out = Data()
//        var error : NSError?
//        for addr in userAddresses {
//            for key in addr.keys {
//                if let privK = ArmorUnarmor(key.private_key, &error) {
//                    out.append(privK)
//                }
//            }
//        }
//        return out
//    }
//
//    var addressPrivateKeysArray: [Data] {
//        var out: [Data] = []
//        var error: NSError?
//        for addr in userAddresses {
//            for key in addr.keys {
//                if let privK = ArmorUnarmor(key.private_key, &error) {
//                    out.append(privK)
//                }
//            }
//        }
//        return out
//    }
//
//
//    var firstUserPublicKey: String? {
//        if userKeys.count > 0 {
//            for k in userKeys {
//                return k.publicKey
//            }
//        }
//        return nil
//    }
//
//    func getAddressPrivKey(address_id : String) -> String {
//        let addr = userAddresses.indexOfAddress(address_id) ?? userAddresses.defaultSendAddress()
//        return addr?.keys.first?.private_key ?? ""
//    }
//
//    func getAddressKey(address_id : String) -> Key? {
//        let addr = userAddresses.indexOfAddress(address_id) ?? userAddresses.defaultSendAddress()
//        return addr?.keys.first
//    }
//}
//
//extension UserInfo {
//    /// Initializes the UserInfo with the response data
//    convenience init(response: [String : Any]) {
//        var uKeys: [Key] = [Key]()
//        if let user_keys = response["Keys"] as? [[String : Any]] {
//            for key_res in user_keys {
//                uKeys.append(Key(
//                    key_id: key_res["ID"] as? String,
//                    private_key: key_res["PrivateKey"] as? String,
//                    token: key_res["Token"] as? String,
//                    signature: key_res["Signature"] as? String,
//                    activation: key_res["Activation"] as? String,
//                    isupdated: false))
//            }
//        }
//        let userId = response["ID"] as? String
//        let usedS = response["UsedSpace"] as? NSNumber
//        let maxS = response["MaxSpace"] as? NSNumber
//        let credit = response["Credit"] as? NSNumber
//        let currency = response["Currency"] as? String
//        self.init(
//            maxSpace: maxS?.int64Value,
//            usedSpace: usedS?.int64Value,
//            language : response["Language"] as? String,
//            maxUpload: response["MaxUpload"] as? Int64,
//            role : response["Role"] as? Int,
//            delinquent : response["Delinquent"] as? Int,
//            keys : uKeys,
//            userId: userId,
//            linkConfirmation: response["ConfirmLink"] as? Int,
//            credit: credit?.intValue,
//            currency: currency
//        )
//    }
//}
//
//// MARK: - NSCoding
//extension UserInfo: NSCoding {
//
//    fileprivate struct CoderKey {
//        static let displayName = "displayName"
//        static let maxSpace = "maxSpace"
//        static let notificationEmail = "notificationEmail"
//        static let signature = "signature"
//        static let usedSpace = "usedSpace"
//        static let userStatus = "userStatus"
//        static let userAddress = "userAddresses"
//
//        static let autoSaveContact = "autoSaveContact"
//        static let language = "language"
//        static let maxUpload = "maxUpload"
//        static let notify = "notify"
//        static let showImages = "showImages"
//
//        static let swipeLeft = "swipeLeft"
//        static let swipeRight = "swipeRight"
//
//        static let role = "role"
//
//        static let delinquent = "delinquent"
//
//        static let userKeys = "userKeys"
//        static let userId = "userId"
//
//        static let attachPublicKey = "attachPublicKey"
//        static let sign = "sign"
//
//        static let linkConfirmation = "linkConfirmation"
//
//        static let credit = "credit"
//        static let currency = "currency"
//
//        static let pwdMode = "passwordMode"
//        static let twoFA = "2faStatus"
//    }
//
//    func archive() -> Data {
//        return NSKeyedArchiver.archivedData(withRootObject: self)
//    }
//
//    static func unarchive(_ data: Data?) -> UserInfo? {
//        guard let data = data else { return nil }
//        return NSKeyedUnarchiver.unarchiveObject(with: data) as? UserInfo
//    }
//
//    convenience init(coder aDecoder: NSCoder) {
//        self.init(
//            displayName: aDecoder.decodeStringForKey(CoderKey.displayName),
//            maxSpace: aDecoder.decodeInt64(forKey: CoderKey.maxSpace),
//            notificationEmail: aDecoder.decodeStringForKey(CoderKey.notificationEmail),
//            signature: aDecoder.decodeStringForKey(CoderKey.signature),
//            usedSpace: aDecoder.decodeInt64(forKey: CoderKey.usedSpace),
//            userAddresses: aDecoder.decodeObject(forKey: CoderKey.userAddress) as? [Address],
//
//            autoSC:aDecoder.decodeInteger(forKey: CoderKey.autoSaveContact),
//            language:aDecoder.decodeStringForKey(CoderKey.language),
//            maxUpload:aDecoder.decodeInt64(forKey: CoderKey.maxUpload),
//            notify:aDecoder.decodeInteger(forKey: CoderKey.notify),
//            showImage:aDecoder.decodeInteger(forKey: CoderKey.showImages),
//
//            swipeL:aDecoder.decodeInteger(forKey: CoderKey.swipeLeft),
//            swipeR:aDecoder.decodeInteger(forKey: CoderKey.swipeRight),
//
//            role : aDecoder.decodeInteger(forKey: CoderKey.role),
//
//            delinquent : aDecoder.decodeInteger(forKey: CoderKey.delinquent),
//
//            keys: aDecoder.decodeObject(forKey: CoderKey.userKeys) as? [Key],
//            userId: aDecoder.decodeStringForKey(CoderKey.userId),
//            sign: aDecoder.decodeInteger(forKey: CoderKey.sign),
//            attachPublicKey: aDecoder.decodeInteger(forKey: CoderKey.attachPublicKey),
//
//            linkConfirmation: aDecoder.decodeStringForKey(CoderKey.linkConfirmation),
//
//            credit: aDecoder.decodeInteger(forKey: CoderKey.credit),
//            currency: aDecoder.decodeStringForKey(CoderKey.currency),
//
//            pwdMode: aDecoder.decodeInteger(forKey: CoderKey.pwdMode),
//            twoFA: aDecoder.decodeInteger(forKey: CoderKey.twoFA)
//        )
//    }
//
//    func encode(with aCoder: NSCoder) {
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
//
//        aCoder.encode(passwordMode, forKey: CoderKey.pwdMode)
//        aCoder.encode(twoFactor, forKey: CoderKey.twoFA)
//    }
//}
//
//


extension UserInfo {
    
    var swipeLeftAction: MessageSwipeAction! {
        return MessageSwipeAction(rawValue: self.swipeLeft)
    }
    var swipeRightAction: MessageSwipeAction! {
        return MessageSwipeAction(rawValue: self.swipeRight)
    }
    
    var addressPrivateKeys : Data {
        var out = Data()
        var error : NSError?
        for addr in userAddresses {
            for key in addr.keys {
                if let privK = ArmorUnarmor(key.private_key, &error) {
                    out.append(privK)
                }
            }
        }
        return out
    }
    
    var addressPrivateKeysArray: [Data] {
        var out: [Data] = []
        var error: NSError?
        for addr in userAddresses {
            for key in addr.keys {
                if let privK = ArmorUnarmor(key.private_key, &error) {
                    out.append(privK)
                }
            }
        }
        return out
    }
}
