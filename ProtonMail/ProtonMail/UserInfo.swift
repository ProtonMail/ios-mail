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
final class UserInfo: NSObject {
    var displayName: String
    let maxSpace: Int64
    var notificationEmail: String
    var privateKey: String
    let publicKey: String
    var signature: String
    let usedSpace: Int64
    let userStatus: Int
    var userAddresses: Array<Address>
    var userKeys: Array<Key>
    
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
        PMLog.D("\(userAddresses)")
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

final class Address: NSObject {
    let address_id: String
    var send: Int    // address order
    let email: String  //email address name
    let status : Int   // 0 is disabled, 1 is enabled, can be set by user
    let type : Int  //1 is original PM, 2 is PM alias, 3 is custom domain address
    let receive: Int // 1 is active address (Status=1 and has key), 0 is inactive (cannot send or receive)
    
    let keys: Array<Key>
    
    let mailbox: Int   //Not inuse
    var display_name: String  //not inuse
    var signature: String //not inuse
    
    required init(addressid: String?, email: String?, send: Int?, receive: Int?, mailbox: Int?, display_name: String?, signature: String?, keys: Array<Key>?, status: Int?, type:Int?) {
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

final class Key : NSObject {
    let key_id: String
    let public_key: String
    var private_key : String
    var fingerprint : String
    
    required init(key_id: String?, public_key: String?, private_key: String?, fingerprint : String?) {
        self.key_id = key_id ?? ""
        self.public_key = public_key ?? ""
        self.private_key = private_key ?? ""
        self.fingerprint = fingerprint ?? ""
    }
}


extension UserInfo {
    /// Initializes the UserInfo with the response data
    convenience init(response: Dictionary<String, AnyObject>) {
        //        privateKeyResponseKey: "EncPrivateKey",
        //        publicKeyResponseKey: "PublicKey",
        var uKeys: Array<Key> = Array<Key>()
        if let user_keys = response["Keys"] as? Array<Dictionary<String, AnyObject>> {
            for key_res in user_keys {
                uKeys.append(Key(
                    key_id: key_res["ID"] as? String,
                    public_key: key_res["PublicKey"] as? String,
                    private_key: key_res["PrivateKey"] as? String,
                    fingerprint: key_res["Fingerprint"] as? String))
            }
        }
        
        var addresses: [Address] = Array<Address>()
        if let address_response = response["Addresses"] as? Array<Dictionary<String, AnyObject>> {
            for res in address_response
            {
                var keys: [Key] = Array<Key>()
                if let address_keys = res["Keys"] as? Array<Dictionary<String, AnyObject>> {
                    for key_res in address_keys {
                        keys.append(Key(
                            key_id: key_res["ID"] as? String,
                            public_key: key_res["PublicKey"] as? String,
                            private_key: key_res["PrivateKey"] as? String,
                            fingerprint: key_res["Fingerprint"] as? String))
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
            maxSpace: maxS?.longLongValue,
            notificationEmail: response["NotificationEmail"] as? String,
            privateKey: "", //response[privateKeyResponseKey] as? String,
            publicKey: "", //response[publicKeyResponseKey] as? String,
            signature: response["Signature"] as? String,
            usedSpace: usedS?.longLongValue,
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
    
    private struct CoderKey {
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
    
    convenience init(coder aDecoder: NSCoder) {
        self.init(
            displayName: aDecoder.decodeStringForKey(CoderKey.displayName),
            maxSpace: aDecoder.decodeInt64ForKey(CoderKey.maxSpace),
            notificationEmail: aDecoder.decodeStringForKey(CoderKey.notificationEmail),
            privateKey: "", //aDecoder.decodeStringForKey(CoderKey.privateKey),
            publicKey: "", //aDecoder.decodeStringForKey(CoderKey.publicKey),
            signature: aDecoder.decodeStringForKey(CoderKey.signature),
            usedSpace: aDecoder.decodeInt64ForKey(CoderKey.usedSpace),
            userStatus: aDecoder.decodeIntegerForKey(CoderKey.userStatus),
            userAddresses: aDecoder.decodeObjectForKey(CoderKey.userAddress) as? Array<Address>,
            
            autoSC:aDecoder.decodeIntegerForKey(CoderKey.autoSaveContact),
            language:aDecoder.decodeStringForKey(CoderKey.language),
            maxUpload:aDecoder.decodeInt64ForKey(CoderKey.maxUpload),
            notify:aDecoder.decodeIntegerForKey(CoderKey.notify),
            showImage:aDecoder.decodeIntegerForKey(CoderKey.showImages),
            
            swipeL:aDecoder.decodeIntegerForKey(CoderKey.swipeLeft),
            swipeR:aDecoder.decodeIntegerForKey(CoderKey.swipeRight),
            
            role : aDecoder.decodeIntegerForKey(CoderKey.role),
            
            delinquent : aDecoder.decodeIntegerForKey(CoderKey.delinquent),
            
            keys: aDecoder.decodeObjectForKey(CoderKey.userKeys) as? Array<Key>
        )
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(displayName, forKey: CoderKey.displayName)
        aCoder.encodeInt64(maxSpace, forKey: CoderKey.maxSpace)
        aCoder.encodeObject(notificationEmail, forKey: CoderKey.notificationEmail)
        aCoder.encodeObject(privateKey, forKey: CoderKey.privateKey)
        aCoder.encodeObject(publicKey, forKey: CoderKey.publicKey)
        aCoder.encodeObject(signature, forKey: CoderKey.signature)
        aCoder.encodeInt64(usedSpace, forKey: CoderKey.usedSpace)
        aCoder.encodeInteger(userStatus, forKey: CoderKey.userStatus)
        aCoder.encodeObject(userAddresses, forKey: CoderKey.userAddress)
        
        aCoder.encodeInteger(autoSaveContact, forKey: CoderKey.autoSaveContact)
        aCoder.encodeObject(language, forKey: CoderKey.language)
        aCoder.encodeInt64(maxUpload, forKey: CoderKey.maxUpload)
        aCoder.encodeInteger(notify, forKey: CoderKey.notify)
        aCoder.encodeInteger(showImages, forKey: CoderKey.showImages)
        
        aCoder.encodeInteger(swipeLeft, forKey: CoderKey.swipeLeft)
        aCoder.encodeInteger(swipeRight, forKey: CoderKey.swipeRight)
        
        aCoder.encodeInteger(role, forKey: CoderKey.role)
        
        aCoder.encodeInteger(delinquent, forKey: CoderKey.delinquent)
        
        aCoder.encodeObject(userKeys, forKey: CoderKey.userKeys)
    }
}

extension Address: NSCoding {
    
    private struct CoderKey { //the keys all messed up but it works
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
    
    convenience init(coder aDecoder: NSCoder) {
        self.init(
            addressid: aDecoder.decodeStringForKey(CoderKey.displayName),
            email: aDecoder.decodeStringForKey(CoderKey.maxSpace),
            send: aDecoder.decodeIntegerForKey(CoderKey.notificationEmail),
            receive: aDecoder.decodeIntegerForKey(CoderKey.privateKey),
            mailbox: aDecoder.decodeIntegerForKey(CoderKey.publicKey),
            display_name: aDecoder.decodeStringForKey(CoderKey.signature),
            signature: aDecoder.decodeStringForKey(CoderKey.usedSpace),
            keys: aDecoder.decodeObjectForKey(CoderKey.userKeys) as?  Array<Key>,
            
            status : aDecoder.decodeIntegerForKey(CoderKey.addressStatus),
            type:aDecoder.decodeIntegerForKey(CoderKey.addressType)
        )
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(address_id, forKey: CoderKey.displayName)
        aCoder.encodeObject(email, forKey: CoderKey.maxSpace)
        aCoder.encodeInteger(send, forKey: CoderKey.notificationEmail)
        aCoder.encodeInteger(receive, forKey: CoderKey.privateKey)
        aCoder.encodeInteger(mailbox, forKey: CoderKey.publicKey)
        aCoder.encodeObject(display_name, forKey: CoderKey.signature)
        aCoder.encodeObject(signature, forKey: CoderKey.usedSpace)
        aCoder.encodeObject(keys, forKey: CoderKey.userKeys)
        
        aCoder.encodeInteger(status, forKey: CoderKey.addressStatus)
        aCoder.encodeInteger(type, forKey: CoderKey.addressType)
    }
}

extension Key: NSCoding {
    
    private struct CoderKey {
        static let keyID = "keyID"
        static let publicKey = "publicKey"
        static let privateKey = "privateKey"
        static let fingerprintKey = "fingerprintKey"
    }
    
    convenience init(coder aDecoder: NSCoder) {
        self.init(
            key_id: aDecoder.decodeStringForKey(CoderKey.keyID),
            public_key: aDecoder.decodeStringForKey(CoderKey.publicKey),
            private_key: aDecoder.decodeStringForKey(CoderKey.privateKey),
            fingerprint: aDecoder.decodeStringForKey(CoderKey.fingerprintKey))
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(key_id, forKey: CoderKey.keyID)
        aCoder.encodeObject(public_key, forKey: CoderKey.publicKey)
        aCoder.encodeObject(private_key, forKey: CoderKey.privateKey)
        aCoder.encodeObject(fingerprint, forKey: CoderKey.fingerprintKey)
    }
}

extension Address {
    func toPMNAddress() -> PMNAddress! {
        return PMNAddress(addressId: self.address_id, addressName: self.email, keys: self.keys.toPMNPgpKeys())
    }
}

extension Key {
    func toPMNPgpKey<T : PMNOpenPgpKey>() -> T {
        return T(keyId: key_id, publicKey: public_key, privateKey: private_key, fingerPrint: fingerprint)
    }
}

extension PMNOpenPgpKey {
    func toKey<T : Key>() -> T {
        return T(key_id: keyId, public_key: publicKey, private_key: privateKey, fingerprint : fingerPrint)
    }
}

extension Array where Element : Key {
    func toPMNPgpKeys() -> [PMNOpenPgpKey] {
        var out_array = Array<PMNOpenPgpKey>()
        for i in 0 ..< self.count {
            let addr = self[i]
            out_array.append(addr.toPMNPgpKey())
        }
        return out_array;
    }
}

extension Array where Element : PMNOpenPgpKey {
    func toKeys() -> [Key] {
        var out_array = Array<Key>()
        for i in 0 ..< self.count {
            let addr = self[i]
            out_array.append(addr.toKey())
        }
        return out_array;
    }
}

extension Array where Element : Address {
    func toPMNAddresses() -> Array<PMNAddress> {
        var out_array = Array<PMNAddress>()
        for i in 0 ..< self.count {
            let addr = self[i]
            out_array.append(addr.toPMNAddress())
        }
        return out_array;
    }
    
    func getDefaultAddress () -> Address? {
        for addr in self {
            if addr.status == 1 && addr.receive == 1 {
                return addr;
            }
        }
        return nil;
    }
    
    func indexOfAddress(addressid : String) -> Address? {
        for addr in self {
            if addr.status == 1 && addr.receive == 1 && addr.address_id == addressid {
                return addr;
            }
        }
        return nil;
    }
    
    func getAddressOrder() -> Array<String> {
        let ids = self.map { $0.address_id }
        return ids;
    }
    
    func getAddressNewOrder() -> Array<Int> {
        let ids = self.map { $0.send }
        return ids;
    }
    
    func toKeys() -> Array<Key> {
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

