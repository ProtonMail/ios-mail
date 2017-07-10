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

// TODO:: this is not very good need refactor
final public class UserInfo : NSObject {
    public var displayName: String
    public let maxSpace: Int64
    public var notificationEmail: String
    public var privateKey: String
    public let publicKey: String
    public var signature: String
    public let usedSpace: Int64
    public let userStatus: Int
    public var userAddresses: Array<Address>
    public var userKeys: Array<Key>
    
    // new values v1.0.8
    public let autoSaveContact : Int
    public let language : String
    public let maxUpload: Int64
    public var notify: Int
    public var showImages : Int  //1 is auto 0 is manual
    
    // new valuse v1.1.4
    public var swipeLeft : Int
    public var swipeRight : Int
    
    public let role : Int
    
    public let delinquent : Int
    
    required public init(
        displayName: String?, maxSpace: Int64?, notificationEmail: String?,
        privateKey: String?, publicKey: String?, signature: String?,
        usedSpace: Int64?, userStatus: Int?, userAddresses: Array<Address>?,
        autoSC:Int?, language:String?, maxUpload:Int64?, notify:Int?, showImage:Int?,  //v1.0.8
        swipeL:Int?, swipeR:Int?,  //v1.1.4
        role:Int?,
        delinquent : Int?,
        keys : Array<Key>?)
    {
        self.displayName = displayName ?? ""
        self.maxSpace = maxSpace ?? 0
        self.notificationEmail = notificationEmail ?? ""
        self.privateKey = privateKey ?? ""
        self.publicKey = publicKey ?? ""
        self.signature = signature ?? ""
        self.usedSpace = usedSpace ?? 0
        self.userStatus = userStatus ?? 0
        self.userAddresses = userAddresses ?? Array<Address>()
        self.autoSaveContact  = autoSC ?? 0
        self.language = language ?? "en_US"
        self.maxUpload = maxUpload ?? 0
        self.notify = notify ?? 0
        self.showImages = showImage ?? 0
        
        self.swipeLeft = swipeL ?? 3
        self.swipeRight = swipeR ?? 0
        
        self.role = role ?? 0
        
        self.delinquent = delinquent ?? 0
        
        self.userKeys = keys ?? Array<Key>()
    }
}

final public class Address: NSObject {
    public let address_id: String
    public var send: Int    // address order
    public let email: String  //email address name
    public let status : Int   // 0 is disabled, 1 is enabled, can be set by user
    public let type : Int  //1 is original PM, 2 is PM alias, 3 is custom domain address
    public let receive: Int // 1 is active address (Status=1 and has key), 0 is inactive (cannot send or receive)
    
    public let keys: Array<Key>
    
    public let mailbox: Int   //Not inuse
    public var display_name: String  //not inuse
    public var signature: String //not inuse
    
    required public init(addressid: String?, email: String?, send: Int?, receive: Int?, mailbox: Int?, display_name: String?, signature: String?, keys: Array<Key>?, status: Int?, type:Int?) {
        self.address_id = addressid ?? ""
        self.email = email ?? ""
        self.send = send ?? 0
        self.receive = receive ?? 0
        self.mailbox = mailbox ?? 0
        self.display_name = display_name ?? ""
        self.signature = signature ?? ""
        self.keys = keys ?? Array<Key>()
        
        self.status = status ?? 0
        self.type = type ?? 0
    }
}

final public class Key : NSObject {
    public let key_id: String
    public let public_key: String
    public var private_key : String
    public var fingerprint : String
    public var is_updated : Bool = false
    
    required public init(key_id: String?, public_key: String?, private_key: String?, fingerprint : String?, isupdated: Bool) {
        self.key_id = key_id ?? ""
        self.public_key = public_key ?? ""
        self.private_key = private_key ?? ""
        self.fingerprint = fingerprint ?? ""
        self.is_updated = isupdated
    }
}


extension UserInfo {
    /// Initializes the UserInfo with the response data
    convenience init(response: Dictionary<String, Any>) {
        var uKeys: Array<Key> = Array<Key>()
        if let user_keys = response["Keys"] as? Array<Dictionary<String, Any>> {
            for key_res in user_keys {
                uKeys.append(Key(
                    key_id: key_res["ID"] as? String,
                    public_key: key_res["PublicKey"] as? String,
                    private_key: key_res["PrivateKey"] as? String,
                    fingerprint: key_res["Fingerprint"] as? String,
                    isupdated: false))
            }
        }
        
        var addresses: [Address] = Array<Address>()
        if let address_response = response["Addresses"] as? Array<Dictionary<String, Any>> {
            for res in address_response
            {
                var keys: [Key] = Array<Key>()
                if let address_keys = res["Keys"] as? Array<Dictionary<String, Any>> {
                    for key_res in address_keys {
                        keys.append(Key(
                            key_id: key_res["ID"] as? String,
                            public_key: key_res["PublicKey"] as? String,
                            private_key: key_res["PrivateKey"] as? String,
                            fingerprint: key_res["Fingerprint"] as? String,
                            isupdated: false))
                    }
                }
                
                addresses.append(Address(
                    addressid: res["ID"] as? String,
                    email:res["Email"] as? String,
                    send: res["Send"] as? Int,
                    receive: res["Receive"] as? Int,
                    mailbox: res["Mailbox"] as? Int,
                    display_name: res["DisplayName"] as? String,
                    signature: res["Signature"] as? String,
                    keys : keys,
                    status: res["Status"] as? Int,
                    type: res["Type"] as? Int
                    ))
            }
        }
        let usedS = response["UsedSpace"] as? NSNumber
        let maxS = response["MaxSpace"] as? NSNumber
        self.init(
            displayName: response["DisplayName"] as? String,
            maxSpace: maxS?.int64Value,
            notificationEmail: response["NotificationEmail"] as? String,
            privateKey: "",
            publicKey: "",
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
        static let privateKey = "privateKey"
        static let publicKey = "publicKey"
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
    
    convenience public init(coder aDecoder: NSCoder) {
        self.init(
            displayName: aDecoder.decodeStringForKey(CoderKey.displayName),
            maxSpace: aDecoder.decodeInt64(forKey: CoderKey.maxSpace),
            notificationEmail: aDecoder.decodeStringForKey(CoderKey.notificationEmail),
            privateKey: "",
            publicKey: "",
            signature: aDecoder.decodeStringForKey(CoderKey.signature),
            usedSpace: aDecoder.decodeInt64(forKey: CoderKey.usedSpace),
            userStatus: aDecoder.decodeInteger(forKey: CoderKey.userStatus),
            userAddresses: aDecoder.decodeObject(forKey: CoderKey.userAddress) as? Array<Address>,
            
            autoSC:aDecoder.decodeInteger(forKey: CoderKey.autoSaveContact),
            language:aDecoder.decodeStringForKey(CoderKey.language),
            maxUpload:aDecoder.decodeInt64(forKey: CoderKey.maxUpload),
            notify:aDecoder.decodeInteger(forKey: CoderKey.notify),
            showImage:aDecoder.decodeInteger(forKey: CoderKey.showImages),
            
            swipeL:aDecoder.decodeInteger(forKey: CoderKey.swipeLeft),
            swipeR:aDecoder.decodeInteger(forKey: CoderKey.swipeRight),
            
            role : aDecoder.decodeInteger(forKey: CoderKey.role),
            
            delinquent : aDecoder.decodeInteger(forKey: CoderKey.delinquent),
            
            keys: aDecoder.decodeObject(forKey: CoderKey.userKeys) as? Array<Key>
        )
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(displayName, forKey: CoderKey.displayName)
        aCoder.encode(maxSpace, forKey: CoderKey.maxSpace)
        aCoder.encode(notificationEmail, forKey: CoderKey.notificationEmail)
        aCoder.encode(privateKey, forKey: CoderKey.privateKey)
        aCoder.encode(publicKey, forKey: CoderKey.publicKey)
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
    
    fileprivate struct CoderKey { //the keys all messed up but it works
        static let displayName = "displayName"
        static let maxSpace = "maxSpace"
        static let notificationEmail = "notificationEmail"
        static let privateKey = "privateKey"
        static let publicKey = "publicKey"
        static let signature = "signature"
        static let usedSpace = "usedSpace"
        static let userKeys = "userKeys"
        
        static let addressStatus = "addressStatus"
        static let addressType = "addressType"
    }
    
    convenience public init(coder aDecoder: NSCoder) {
        self.init(
            addressid: aDecoder.decodeStringForKey(CoderKey.displayName),
            email: aDecoder.decodeStringForKey(CoderKey.maxSpace),
            send: aDecoder.decodeInteger(forKey: CoderKey.notificationEmail),
            receive: aDecoder.decodeInteger(forKey: CoderKey.privateKey),
            mailbox: aDecoder.decodeInteger(forKey: CoderKey.publicKey),
            display_name: aDecoder.decodeStringForKey(CoderKey.signature),
            signature: aDecoder.decodeStringForKey(CoderKey.usedSpace),
            keys: aDecoder.decodeObject(forKey: CoderKey.userKeys) as?  Array<Key>,
            
            status : aDecoder.decodeInteger(forKey: CoderKey.addressStatus),
            type:aDecoder.decodeInteger(forKey: CoderKey.addressType)
        )
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(address_id, forKey: CoderKey.displayName)
        aCoder.encode(email, forKey: CoderKey.maxSpace)
        aCoder.encode(send, forKey: CoderKey.notificationEmail)
        aCoder.encode(receive, forKey: CoderKey.privateKey)
        aCoder.encode(mailbox, forKey: CoderKey.publicKey)
        aCoder.encode(display_name, forKey: CoderKey.signature)
        aCoder.encode(signature, forKey: CoderKey.usedSpace)
        aCoder.encode(keys, forKey: CoderKey.userKeys)
        
        aCoder.encode(status, forKey: CoderKey.addressStatus)
        aCoder.encode(type, forKey: CoderKey.addressType)
    }
}

extension Key: NSCoding {
    
    fileprivate struct CoderKey {
        static let keyID = "keyID"
        static let publicKey = "publicKey"
        static let privateKey = "privateKey"
        static let fingerprintKey = "fingerprintKey"
    }
    
    convenience public init(coder aDecoder: NSCoder) {
        self.init(
            key_id: aDecoder.decodeStringForKey(CoderKey.keyID),
            public_key: aDecoder.decodeStringForKey(CoderKey.publicKey),
            private_key: aDecoder.decodeStringForKey(CoderKey.privateKey),
            fingerprint: aDecoder.decodeStringForKey(CoderKey.fingerprintKey),
            isupdated: false)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(key_id, forKey: CoderKey.keyID)
        aCoder.encode(public_key, forKey: CoderKey.publicKey)
        aCoder.encode(private_key, forKey: CoderKey.privateKey)
        aCoder.encode(fingerprint, forKey: CoderKey.fingerprintKey)
    }
}

extension Address {
    public func toPMNAddress() -> PMNAddress! {
        return PMNAddress(addressId: self.address_id, addressName: self.email, keys: self.keys.toPMNPgpKeys())
    }
}

extension Key {
    public func toPMNPgpKey<T : PMNOpenPgpKey>() -> T {
        return T(keyId: key_id, publicKey: public_key, privateKey: private_key, fingerPrint: fingerprint, isUpdated: is_updated)
    }
}

extension PMNOpenPgpKey {
    public func toKey<T : Key>() -> T {
        return T(key_id: keyId, public_key: publicKey, private_key: privateKey, fingerprint : fingerPrint, isupdated: isUpdated)
    }
}

extension Array where Element : Key {
    public func toPMNPgpKeys() -> [PMNOpenPgpKey] {
        var out_array = Array<PMNOpenPgpKey>()
        for i in 0 ..< self.count {
            let addr = self[i]
            out_array.append(addr.toPMNPgpKey())
        }
        return out_array;
    }
}

extension Array where Element : PMNOpenPgpKey {
    public func toKeys() -> [Key] {
        var out_array = Array<Key>()
        for i in 0 ..< self.count {
            let addr = self[i]
            out_array.append(addr.toKey())
        }
        return out_array;
    }
}

extension Array where Element : Address {

    public func toPMNAddresses() -> Array<PMNAddress> {
        var out_array = Array<PMNAddress>()
        for i in 0 ..< self.count {
            let addr = self[i]
            out_array.append(addr.toPMNAddress())
        }
        return out_array;
    }
    
    public func getDefaultAddress () -> Address? {
        for addr in self {
            if addr.status == 1 && addr.receive == 1 {
                return addr;
            }
        }
        return nil;
    }
    
    public func indexOfAddress(_ addressid : String) -> Address? {
        for addr in self {
            if addr.status == 1 && addr.receive == 1 && addr.address_id == addressid {
                return addr;
            }
        }
        return nil;
    }
    
    public func getAddressOrder() -> Array<String> {
        let ids = self.map { $0.address_id }
        return ids;
    }
    
    public func getAddressNewOrder() -> Array<Int> {
        let ids = self.map { $0.send }
        return ids;
    }
    
    public func toKeys() -> Array<Key> {
        var out_array = Array<Key>()
        for i in 0 ..< self.count {
            let addr = self[i]
            for k in addr.keys {
                out_array.append(k)
            }
        }
        return out_array
    }
}

