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
    let maxSpace: Int64
    let notificationEmail: String
    let privateKey: String
    let publicKey: String
    let signature: String
    let usedSpace: Int64
    let userStatus: Int
    let userAddresses: Array<Address>
    
    // new values v1.0.8
    let autoSaveContact : Int
    let language : String
    let maxUpload: Int64
    let notify: Int
    let showImages : Int
    
    // new valuse v1.1.4
    let swipeLeft : Int
    let swipeRight : Int
    
    required init(
        displayName: String?, maxSpace: Int64?, notificationEmail: String?,
        privateKey: String?, publicKey: String?, signature: String?,
        usedSpace: Int64?, userStatus: Int?, userAddresses: Array<Address>?,
        autoSC:Int?, language:String?, maxUpload:Int64?, notify:Int?, showImage:Int?,  //v1.0.8
        swipeL:Int?, swipeR:Int? ) //v1.1.4
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
    }
}

final class Address: NSObject {
    let address_id: String
    let email: String
    var send: Int
    let receive: Int
    let mailbox: Int
    let display_name: String
    let signature: String
    let keys: Array<Key>
    
    required init(addressid: String?, email: String?, send: Int?, receive: Int?, mailbox: Int?, display_name: String?, signature: String?, keys: Array<Key>?) {
        self.address_id = addressid ?? ""
        self.email = email ?? ""
        self.send = send ?? 0
        self.receive = receive ?? 0
        self.mailbox = mailbox ?? 0
        self.display_name = display_name ?? ""
        self.signature = signature ?? ""
        self.keys = keys ?? Array<Key>()
    }
}

final class Key: NSObject {
    let key_id: String
    let public_key: String
    var private_key : String
    
    required init(key_id: String?, public_key: String?, private_key: String?) {
        self.key_id = key_id ?? ""
        self.public_key = public_key ?? ""
        self.private_key = private_key ?? ""
    }
}


extension UserInfo {
    /// Initializes the UserInfo with the response data
    convenience init(
        response: Dictionary<String, AnyObject>,
        displayNameResponseKey: String,
        maxSpaceResponseKey: String,
        notificationEmailResponseKey: String,
        privateKeyResponseKey: String,
        publicKeyResponseKey: String,
        signatureResponseKey: String,
        usedSpaceResponseKey: String,
        userStatusResponseKey:String,
        userAddressResponseKey:String,
        
        autoSaveContactResponseKey : String,
        languageResponseKey : String,
        maxUploadResponseKey: String,
        notifyResponseKey: String,
        showImagesResponseKey : String,
        
        swipeLeftResponseKey : String,
        swipeRightResponseKey : String
        ) {
            var addresses: [Address] = Array<Address>()
            let address_response = response[userAddressResponseKey] as! Array<Dictionary<String, AnyObject>>
            for res in address_response
            {
                var keys: [Key] = Array<Key>()
                let address_keys = res["Keys"] as! Array<Dictionary<String, AnyObject>>
                for key_res in address_keys {
                    keys.append(Key(
                        key_id: key_res["ID"] as? String,
                        public_key: key_res["PublicKey"] as? String,
                        private_key: key_res["PrivateKey"] as? String))
                }
                
                addresses.append(Address(
                    addressid: res["ID"] as? String,
                    email:res["Email"] as? String,
                    send: res["Send"] as? Int,
                    receive: res["Receive"] as? Int,
                    mailbox: res["Mailbox"] as? Int,
                    display_name: res["DisplayName"] as? String,
                    signature: res["Signature"] as? String,
                    keys : keys ))
            }
            let usedS = response[usedSpaceResponseKey] as? NSNumber
            let maxS = response[maxSpaceResponseKey] as? NSNumber
            self.init(
                displayName: response[displayNameResponseKey] as? String,
                maxSpace: maxS?.longLongValue,
                notificationEmail: response[notificationEmailResponseKey] as? String,
                privateKey: response[privateKeyResponseKey] as? String,
                publicKey: response[publicKeyResponseKey] as? String,
                signature: response[signatureResponseKey] as? String,
                usedSpace: usedS?.longLongValue,
                userStatus: response[userStatusResponseKey] as? Int,
                userAddresses: addresses,
                
                autoSC : response[autoSaveContactResponseKey] as? Int,
                language : response[languageResponseKey] as? String,
                maxUpload: response[maxUploadResponseKey] as? Int64,
                notify: response[notifyResponseKey] as? Int,
                showImage : response[showImagesResponseKey] as? Int,
                
                swipeL: response[swipeLeftResponseKey] as? Int,
                swipeR: response[swipeRightResponseKey] as? Int
                
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
    }
    
    convenience init(coder aDecoder: NSCoder) {
        self.init(
            displayName: aDecoder.decodeStringForKey(CoderKey.displayName),
            maxSpace: aDecoder.decodeInt64ForKey(CoderKey.maxSpace),
            notificationEmail: aDecoder.decodeStringForKey(CoderKey.notificationEmail),
            privateKey: aDecoder.decodeStringForKey(CoderKey.privateKey),
            publicKey: aDecoder.decodeStringForKey(CoderKey.publicKey),
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
            swipeR:aDecoder.decodeIntegerForKey(CoderKey.swipeRight)
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
    }
}

extension Address: NSCoding {
    
    private struct CoderKey {
        static let displayName = "displayName"
        static let maxSpace = "maxSpace"
        static let notificationEmail = "notificationEmail"
        static let privateKey = "privateKey"
        static let publicKey = "publicKey"
        static let signature = "signature"
        static let usedSpace = "usedSpace"
        static let userStatus = "userStatus"
        static let userKeys = "userKeys"
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
            keys: aDecoder.decodeObjectForKey(CoderKey.userKeys) as?  Array<Key>
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
    }
}

extension Key: NSCoding {
    
    private struct CoderKey {
        static let keyID = "keyID"
        static let publicKey = "publicKey"
        static let privateKey = "privateKey"
    }
    
    convenience init(coder aDecoder: NSCoder) {
        self.init(
            key_id: aDecoder.decodeStringForKey(CoderKey.keyID),
            public_key: aDecoder.decodeStringForKey(CoderKey.publicKey),
            private_key: aDecoder.decodeStringForKey(CoderKey.privateKey))
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(key_id, forKey: CoderKey.keyID)
        aCoder.encodeObject(public_key, forKey: CoderKey.publicKey)
        aCoder.encodeObject(private_key, forKey: CoderKey.privateKey)
    }
}

extension Address {
    func toPMNAddress() -> PMNAddress! {
        return PMNAddress(addressId: self.address_id, addressName: self.email, keys: self.keys.toPMNPgpKeys())
    }
}

extension Key {
    func toPMNPgpKey() -> PMNOpenPgpKey {
        return PMNOpenPgpKey(publicKey: public_key, privateKey: private_key)
    }
}

extension Array {
    func toPMNPgpKeys <T: Key>() -> Array<PMNOpenPgpKey> {
        var out_array = Array<PMNOpenPgpKey>()
        for var i = 0; i < self.count; ++i {
            var addr = (self[i] as! Key)
            out_array.append(addr.toPMNPgpKey())
        }
        return out_array;
    }
    
    func toPMNAddresses <T: Address>() -> Array<PMNAddress> {
        var out_array = Array<PMNAddress>()
        for var i = 0; i < self.count; ++i {
            var addr = (self[i] as! Address)
            out_array.append(addr.toPMNAddress())
        }
        return out_array;
    }
}



