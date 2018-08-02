//
//  Addresses.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/1/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation



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
