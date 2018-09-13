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

struct ShowImages : OptionSet {
    let rawValue: Int
    // 0 for none, 1 for remote, 2 for embedded, 3 for remote and embedded (
    static let none     = ShowImages(rawValue: 0)
    static let remote   = ShowImages(rawValue: 1 << 0) // auto load remote images
    static let embedded = ShowImages(rawValue: 1 << 1) // auto load embedded images
}

@objc(UserInfo)
final class UserInfo : NSObject {
    
    //1.9.0 phone local cache
    var language : String
    
    //1.9.1 user object
    var delinquent : Int
    var role : Int
    var maxSpace: Int64
    var usedSpace: Int64
    var maxUpload: Int64
    
    var userKeys: [Key] //user key
    //"VPN": { //TODO::handle this in the future
    //    "Status": 1,
    //    "ExpirationTime": 0,
    //    "PlanName": "visionary",
    //    "MaxConnect": 10,
    //    "MaxTier": 2
    //}
//    "Name": "jason",
//    "Currency": "USD",
//    "Credit": 0,
//    "Private": 1,
//    "Subscribed": 1,
//    "Services": 1,

    //1.9.1 mail settings
    var displayName: String = ""
    var defaultSignature: String = ""
    var autoSaveContact : Int = 0
    var showImages : ShowImages = .none
    var autoShowRemote : Bool {
        get {
            return self.showImages.contains(.remote)
        }
    }
    var swipeLeft : Int = 3
    var swipeRight : Int = 0
    
    
    //1.9.1 user settings
    var notificationEmail: String = ""
    var notify: Int = 0
 
    //1.9.0 get from addresses route
    var userAddresses: [Address] = [Address]()
    
    // init from cache
    required init(
        displayName: String?, maxSpace: Int64?, notificationEmail: String?, signature: String?,
        usedSpace: Int64?, userAddresses: [Address]?,
        autoSC:Int?, language:String?, maxUpload:Int64?, notify:Int?, showImage:Int?,  //v1.0.8
        swipeL:Int?, swipeR:Int?,  //v1.1.4
        role:Int?,
        delinquent : Int?,
        keys : [Key]?)
    {
        self.maxSpace = maxSpace ?? 0
        self.usedSpace = usedSpace ?? 0
        self.language = language ?? "en_US"
        self.maxUpload = maxUpload ?? 0
        self.role = role ?? 0
        self.delinquent = delinquent ?? 0
        self.userKeys = keys ?? [Key]()
        
        // get from user settings
        self.notificationEmail = notificationEmail ?? ""
        self.notify = notify ?? 0
        
        // get from mail settings
        self.displayName = displayName ?? ""
        self.defaultSignature = signature ?? ""
        self.autoSaveContact  = autoSC ?? 0
        self.showImages = ShowImages(rawValue: showImage ?? 0)
        self.swipeLeft = swipeL ?? 3
        self.swipeRight = swipeR ?? 0
        
        // addresses
        self.userAddresses = userAddresses ?? [Address]()
    }

    // init from api
    required init(maxSpace: Int64?, usedSpace: Int64?,
                  language:String?, maxUpload:Int64?,
                  role:Int?,
                  delinquent : Int?,
                  keys : [Key]?) {
        self.maxSpace = maxSpace ?? 0
        self.usedSpace = usedSpace ?? 0
        self.language = language ?? "en_US"
        self.maxUpload = maxUpload ?? 0
        self.role = role ?? 0
        self.delinquent = delinquent ?? 0
        
        self.userKeys = keys ?? [Key]()
    }
    
    /// Update user addresses
    ///
    /// - Parameter addresses: new addresses
    func set(addresses : [Address]) {
        self.userAddresses = addresses
    }

    /// set User, copy the data from input user object
    ///
    /// - Parameter userinfo: New user info
    func set(userinfo : UserInfo) {
        self.maxSpace = userinfo.maxSpace
        self.usedSpace = userinfo.usedSpace
        self.language = userinfo.language
        self.maxUpload = userinfo.maxUpload
        self.role = userinfo.role
        self.delinquent = userinfo.delinquent
        
        self.userKeys = userinfo.userKeys
    }
    
    func parse(userSettings: [String : Any]?) {
        if let settings = userSettings {
            if let email = settings["Email"] as? [String : Any] {
                self.notificationEmail = email["Value"] as? String ?? ""
                self.notify = email["Notify"] as? Int ?? 0
            }
        }
    }
    
    func parse(mailSettings: [String : Any]?) {
        if let settings = mailSettings {
            self.displayName = settings["DisplayName"] as? String ?? "'"
            self.defaultSignature = settings["Signature"] as? String ?? ""
            self.autoSaveContact  = settings["AutoSaveContacts"] as? Int ?? 0
            self.showImages = ShowImages(rawValue: settings["ShowImages"] as? Int ?? 0)
            self.swipeLeft = settings["SwipeLeft"] as? Int ?? 3
            self.swipeRight = settings["SwipeRight"] as? Int ?? 0
        }
    }
    
    func firstUserKey() -> Key? {
        if self.userKeys.count > 0 {
            return self.userKeys[0]
        }
        return nil
    }
}

extension UserInfo {
    /// Initializes the UserInfo with the response data
    convenience init(response: [String : Any]) {
        var uKeys: [Key] = [Key]()
        if let user_keys = response["Keys"] as? [[String : Any]] {
            for key_res in user_keys {
                uKeys.append(Key(
                    key_id: key_res["ID"] as? String,
                    private_key: key_res["PrivateKey"] as? String,
                    fingerprint: key_res["Fingerprint"] as? String,
                    isupdated: false))
            }
        }
        
        let usedS = response["UsedSpace"] as? NSNumber
        let maxS = response["MaxSpace"] as? NSNumber
        self.init(
            maxSpace: maxS?.int64Value,
            usedSpace: usedS?.int64Value,
            language : response["Language"] as? String,
            maxUpload: response["MaxUpload"] as? Int64,
            role : response["Role"] as? Int,
            delinquent : response["Delinquent"] as? Int,
            keys : uKeys
        )
    }
}

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
    }
    
    convenience init(coder aDecoder: NSCoder) {
        self.init(
            displayName: aDecoder.decodeStringForKey(CoderKey.displayName),
            maxSpace: aDecoder.decodeInt64(forKey: CoderKey.maxSpace),
            notificationEmail: aDecoder.decodeStringForKey(CoderKey.notificationEmail),
            signature: aDecoder.decodeStringForKey(CoderKey.signature),
            usedSpace: aDecoder.decodeInt64(forKey: CoderKey.usedSpace),
            userAddresses: aDecoder.decodeObject(forKey: CoderKey.userAddress) as? [Address],
            
            autoSC:aDecoder.decodeInteger(forKey: CoderKey.autoSaveContact),
            language:aDecoder.decodeStringForKey(CoderKey.language),
            maxUpload:aDecoder.decodeInt64(forKey: CoderKey.maxUpload),
            notify:aDecoder.decodeInteger(forKey: CoderKey.notify),
            showImage:aDecoder.decodeInteger(forKey: CoderKey.showImages),
            
            swipeL:aDecoder.decodeInteger(forKey: CoderKey.swipeLeft),
            swipeR:aDecoder.decodeInteger(forKey: CoderKey.swipeRight),
            
            role : aDecoder.decodeInteger(forKey: CoderKey.role),
            
            delinquent : aDecoder.decodeInteger(forKey: CoderKey.delinquent),
            
            keys: aDecoder.decodeObject(forKey: CoderKey.userKeys) as? [Key]
        )
    }
    
    func encode(with aCoder: NSCoder) {
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
        
        //get from mail settings
        aCoder.encode(displayName, forKey: CoderKey.displayName)
        aCoder.encode(defaultSignature, forKey: CoderKey.signature)
        aCoder.encode(autoSaveContact, forKey: CoderKey.autoSaveContact)
        aCoder.encode(showImages.rawValue, forKey: CoderKey.showImages)
        aCoder.encode(swipeLeft, forKey: CoderKey.swipeLeft)
        aCoder.encode(swipeRight, forKey: CoderKey.swipeRight)
    }
}


