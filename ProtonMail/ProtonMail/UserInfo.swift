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
import Pm

@objc(UserInfo)
// TODO:: this is not very good need refactor
final class UserInfo : NSObject {
    var displayName: String
    let maxSpace: Int64
    var notificationEmail: String
    var signature: String
    let usedSpace: Int64
    let userStatus: Int
    var userAddresses: [Address]
    var userKeys: [Key]
    
    // new values v1.0.8
    let autoSaveContact : Int
    let language : String
    let maxUpload: Int64
    var notify: Int
    var showImages : Int  //1 is auto 0 is manual
    
    // new valuse v1.1.4
    var swipeLeft : Int
    var swipeRight : Int
    
    let role : Int
    
    let delinquent : Int
    
    required init(
        displayName: String?, maxSpace: Int64?, notificationEmail: String?, signature: String?,
        usedSpace: Int64?, userStatus: Int?, userAddresses: [Address]?,
        autoSC:Int?, language:String?, maxUpload:Int64?, notify:Int?, showImage:Int?,  //v1.0.8
        swipeL:Int?, swipeR:Int?,  //v1.1.4
        role:Int?,
        delinquent : Int?,
        keys : [Key]?)
    {
        self.displayName = displayName ?? ""
        self.maxSpace = maxSpace ?? 0
        self.notificationEmail = notificationEmail ?? ""
        self.signature = signature ?? ""
        self.usedSpace = usedSpace ?? 0
        self.userStatus = userStatus ?? 0
        self.userAddresses = userAddresses ?? [Address]()
        self.autoSaveContact  = autoSC ?? 0
        self.language = language ?? "en_US"
        self.maxUpload = maxUpload ?? 0
        self.notify = notify ?? 0
        self.showImages = showImage ?? 0
        
        self.swipeLeft = swipeL ?? 3
        self.swipeRight = swipeR ?? 0
        
        self.role = role ?? 0
        
        self.delinquent = delinquent ?? 0
        
        self.userKeys = keys ?? [Key]()
    }
    
    func setAddresses(addresses : [Address]) {
        self.userAddresses = addresses
    }
    
    func firstUserKey() -> Key? {
        if self.userKeys.count > 0 {
            return self.userKeys[0]
        }
        return nil
    }
}

final class Address: NSObject {
    let address_id: String
    let email: String   //email address name
    let status : Int    // 0 is disabled, 1 is enabled, can be set by user
    let type : Int      //1 is original PM, 2 is PM alias, 3 is custom domain address
    let receive: Int    // 1 is active address (Status =1 and has key), 0 is inactive (cannot send or receive)
    var order: Int      // address order replace send //1.6.7
    var send: Int       // v<1.6.7 address order  v>=1.6.7 not in use
    let keys: [Key]
    
    let mailbox: Int   //Not inuse
    var display_name: String  //not inuse
    var signature: String //not inuse
    
    required init(addressid: String?,
                  email: String?,
                  order: Int?,
                  receive: Int?,
                  mailbox: Int?,
                  display_name: String?,
                  signature: String?,
                  keys: [Key]?,
                  status: Int?,
                  type:Int?,
                  send: Int?) {
        self.address_id = addressid ?? ""
        self.email = email ?? ""
        self.receive = receive ?? 0
        self.mailbox = mailbox ?? 0
        self.display_name = display_name ?? ""
        self.signature = signature ?? ""
        self.keys = keys ?? [Key]()
        
        self.status = status ?? 0
        self.type = type ?? 0
        
        self.send = send ?? 0
        self.order = order ?? 0
    }
}

final class Key : NSObject {
    let key_id: String
    var private_key : String
    var fingerprint : String
    var is_updated : Bool = false
    var keyflags : Int = 0
    
    required init(key_id: String?, private_key: String?, fingerprint : String?, isupdated: Bool) {
        self.key_id = key_id ?? ""
        self.private_key = private_key ?? ""
        self.fingerprint = fingerprint ?? ""
        self.is_updated = isupdated
    }
    
    var publicKey : String {
        return PmPublicKey(self.private_key, nil)
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
        
        var addresses: [Address] = [Address]()
        if let address_response = response["Addresses"] as? [[String : Any]] {
            for res in address_response
            {
                var keys: [Key] = [Key]()
                if let address_keys = res["Keys"] as? [[String : Any]] {
                    for key_res in address_keys {
                        keys.append(Key(
                            key_id: key_res["ID"] as? String,
                            private_key: key_res["PrivateKey"] as? String,
                            fingerprint: key_res["Fingerprint"] as? String,
                            isupdated: false))
                    }
                }
                
                addresses.append(Address(
                    addressid: res["ID"] as? String,
                    email:res["Email"] as? String,
                    order: res["Order"] as? Int,
                    receive: res["Receive"] as? Int,
                    mailbox: res["Mailbox"] as? Int,
                    display_name: res["DisplayName"] as? String,
                    signature: res["Signature"] as? String,
                    keys : keys,
                    status: res["Status"] as? Int,
                    type: res["Type"] as? Int,
                    send: res["Send"] as? Int
                ))
            }
        }
        let usedS = response["UsedSpace"] as? NSNumber
        let maxS = response["MaxSpace"] as? NSNumber
        self.init(
            displayName: response["DisplayName"] as? String,
            maxSpace: maxS?.int64Value,
            notificationEmail: response["NotificationEmail"] as? String,
            signature: response["Signature"] as? String,
            usedSpace: usedS?.int64Value,
            userStatus: response["UserStatus"] as? Int,
            userAddresses: addresses,
            
            autoSC : response["AutoSaveContacts"] as? Int,
            language : response["Language"] as? String,
            maxUpload: response["MaxUpload"] as? Int64,
            notify: response["Notify"] as? Int,
            showImage : response["ShowImages"] as? Int,
            
            swipeL: response["SwipeLeft"] as? Int,
            swipeR: response["SwipeRight"] as? Int,
            
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
            userStatus: aDecoder.decodeInteger(forKey: CoderKey.userStatus),
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
        aCoder.encode(displayName, forKey: CoderKey.displayName)
        aCoder.encode(maxSpace, forKey: CoderKey.maxSpace)
        aCoder.encode(notificationEmail, forKey: CoderKey.notificationEmail)
        aCoder.encode(signature, forKey: CoderKey.signature)
        aCoder.encode(usedSpace, forKey: CoderKey.usedSpace)
        aCoder.encode(userStatus, forKey: CoderKey.userStatus)
        aCoder.encode(userAddresses, forKey: CoderKey.userAddress)
        
        aCoder.encode(autoSaveContact, forKey: CoderKey.autoSaveContact)
        aCoder.encode(language, forKey: CoderKey.language)
        aCoder.encode(maxUpload, forKey: CoderKey.maxUpload)
        aCoder.encode(notify, forKey: CoderKey.notify)
        aCoder.encode(showImages, forKey: CoderKey.showImages)
        
        aCoder.encode(swipeLeft, forKey: CoderKey.swipeLeft)
        aCoder.encode(swipeRight, forKey: CoderKey.swipeRight)
        
        aCoder.encode(role, forKey: CoderKey.role)
        
        aCoder.encode(delinquent, forKey: CoderKey.delinquent)
        
        aCoder.encode(userKeys, forKey: CoderKey.userKeys)
    }
}

extension Address: NSCoding {
    
    //the keys all messed up but it works ( don't copy paste there looks really bad)
    fileprivate struct CoderKey {
        static let addressID    = "displayName"
        static let email        = "maxSpace"
        static let order        = "notificationEmail"
        static let receive      = "privateKey"
        static let mailbox      = "publicKey"
        static let display_name = "signature"
        static let signature    = "usedSpace"
        static let keys         = "userKeys"
        
        static let addressStatus = "addressStatus"
        static let addressType   = "addressType"
        static let addressSend   = "addressSendStatus"
    }
    
    convenience init(coder aDecoder: NSCoder) {
        self.init(
            addressid: aDecoder.decodeStringForKey(CoderKey.addressID),
            email: aDecoder.decodeStringForKey(CoderKey.email),
            order: aDecoder.decodeInteger(forKey: CoderKey.order),
            receive: aDecoder.decodeInteger(forKey: CoderKey.receive),
            mailbox: aDecoder.decodeInteger(forKey: CoderKey.mailbox),
            display_name: aDecoder.decodeStringForKey(CoderKey.display_name),
            signature: aDecoder.decodeStringForKey(CoderKey.signature),
            keys: aDecoder.decodeObject(forKey: CoderKey.keys) as?  [Key],
            
            status : aDecoder.decodeInteger(forKey: CoderKey.addressStatus),
            type:aDecoder.decodeInteger(forKey: CoderKey.addressType),
            send: aDecoder.decodeInteger(forKey: CoderKey.addressSend)
        )
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(address_id, forKey: CoderKey.addressID)
        aCoder.encode(email, forKey: CoderKey.email)
        aCoder.encode(order, forKey: CoderKey.order)
        aCoder.encode(receive, forKey: CoderKey.receive)
        aCoder.encode(mailbox, forKey: CoderKey.mailbox)
        aCoder.encode(display_name, forKey: CoderKey.display_name)
        aCoder.encode(signature, forKey: CoderKey.signature)
        aCoder.encode(keys, forKey: CoderKey.keys)
        
        aCoder.encode(status, forKey: CoderKey.addressStatus)
        aCoder.encode(type, forKey: CoderKey.addressType)
        
        aCoder.encode(send, forKey: CoderKey.addressSend)
    }
}

extension Key: NSCoding {
    
    fileprivate struct CoderKey {
        static let keyID          = "keyID"
        static let privateKey     = "privateKey"
        static let fingerprintKey = "fingerprintKey"
    }
    
    convenience init(coder aDecoder: NSCoder) {
        self.init(
            key_id: aDecoder.decodeStringForKey(CoderKey.keyID),
            private_key: aDecoder.decodeStringForKey(CoderKey.privateKey),
            fingerprint: aDecoder.decodeStringForKey(CoderKey.fingerprintKey),
            isupdated: false)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(key_id, forKey: CoderKey.keyID)
        aCoder.encode(private_key, forKey: CoderKey.privateKey)
        aCoder.encode(fingerprint, forKey: CoderKey.fingerprintKey)
    }
}


extension Array where Element : Address {
    func defaultAddress() -> Address? {
        for addr in self {
            if addr.status == 1 && addr.receive == 1 {
                return addr
            }
        }
        return nil
    }
    
    func defaultSendAddress() -> Address? {
        for addr in self {
            if addr.status == 1 && addr.receive == 1 && addr.send == 1{
                return addr
            }
        }
        return nil
    }
    
    func indexOfAddress(_ addressid : String) -> Address? {
        for addr in self {
            if addr.status == 1 && addr.receive == 1 && addr.address_id == addressid {
                return addr
            }
        }
        return nil
    }
    
    func getAddressOrder() -> [String] {
        let ids = self.map { $0.address_id }
        return ids
    }
    
    func getAddressNewOrder() -> [Int] {
        let ids = self.map { $0.order }
        return ids
    }
    
    func toKeys() -> [Key] {
        var out_array = [Key]()
        for i in 0 ..< self.count {
            let addr = self[i]
            for k in addr.keys {
                out_array.append(k)
            }
        }
        return out_array
    }
}

