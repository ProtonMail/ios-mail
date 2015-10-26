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
    
    required init(addressid: String?, email: String?, send: Int?, receive: Int?, mailbox: Int?, display_name: String?, signature: String?) {
        self.address_id = addressid ?? ""
        self.email = email ?? ""
        self.send = send ?? 0
        self.receive = receive ?? 0
        self.mailbox = mailbox ?? 0
        self.display_name = display_name ?? ""
        self.signature = signature ?? ""
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
    }
    
    convenience init(coder aDecoder: NSCoder) {
        self.init(
            addressid: aDecoder.decodeStringForKey(CoderKey.displayName),
            email: aDecoder.decodeStringForKey(CoderKey.maxSpace),
            send: aDecoder.decodeIntegerForKey(CoderKey.notificationEmail),
            receive: aDecoder.decodeIntegerForKey(CoderKey.privateKey),
            mailbox: aDecoder.decodeIntegerForKey(CoderKey.publicKey),
            display_name: aDecoder.decodeStringForKey(CoderKey.signature),
            signature: aDecoder.decodeStringForKey(CoderKey.usedSpace))
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(address_id, forKey: CoderKey.displayName)
        aCoder.encodeObject(email, forKey: CoderKey.maxSpace)
        aCoder.encodeInteger(send, forKey: CoderKey.notificationEmail)
        aCoder.encodeInteger(receive, forKey: CoderKey.privateKey)
        aCoder.encodeInteger(mailbox, forKey: CoderKey.publicKey)
        aCoder.encodeObject(display_name, forKey: CoderKey.signature)
        aCoder.encodeObject(signature, forKey: CoderKey.usedSpace)
    }
}