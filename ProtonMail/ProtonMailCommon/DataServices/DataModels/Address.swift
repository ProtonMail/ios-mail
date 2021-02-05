//
//  Addresses.swift
//  ProtonMail - Created on 8/1/18.
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

//
//@objc(Address)
//final class Address: NSObject {
//    let address_id: String
//    let email: String   // email address name
//    let status : Int    // 0 is disabled, 1 is enabled, can be set by user
//    let type : Int      // 1 is original PM, 2 is PM alias, 3 is custom domain address
//    let receive: Int    // 1 is active address (Status =1 and has key), 0 is inactive (cannot send or receive)
//    var order: Int      // address order
//    // 0 means you can’t send with it 1 means you can pm.me addresses have Send 0 for free users, for instance so do addresses without keys
//    var send: Int
//    let keys: [Key]
//    var display_name: String
//    var signature: String
//    
//    required init(addressid: String?,
//                  email: String?,
//                  order: Int?,
//                  receive: Int?,
//                  display_name: String?,
//                  signature: String?,
//                  keys: [Key]?,
//                  status: Int?,
//                  type:Int?,
//                  send: Int?) {
//        self.address_id = addressid ?? ""
//        self.email = email ?? ""
//        self.receive = receive ?? 0
//        self.display_name = display_name ?? ""
//        self.signature = signature ?? ""
//        self.keys = keys ?? [Key]()
//        
//        self.status = status ?? 0
//        self.type = type ?? 0
//        
//        self.send = send ?? 0
//        self.order = order ?? 0
//    }
//   
//}
//
//// MARK: - TODO:: we'd better move to Codable or at least NSSecureCoding when will happen to refactor this part of app from Anatoly
//extension Address: NSCoding {
//    func archive() -> Data {
//        return NSKeyedArchiver.archivedData(withRootObject: self)
//    }
//    
//    static func unarchive(_ data: Data?) -> Address? {
//        guard let data = data else { return nil }
//        return NSKeyedUnarchiver.unarchiveObject(with: data) as? Address
//    }
//    
//    //the keys all messed up but it works ( don't copy paste there looks really bad)
//    fileprivate struct CoderKey {
//        static let addressID    = "displayName"
//        static let email        = "maxSpace"
//        static let order        = "notificationEmail"
//        static let receive      = "privateKey"
//        static let mailbox      = "publicKey"
//        static let display_name = "signature"
//        static let signature    = "usedSpace"
//        static let keys         = "userKeys"
//        
//        static let addressStatus = "addressStatus"
//        static let addressType   = "addressType"
//        static let addressSend   = "addressSendStatus"
//    }
//    
//    convenience init(coder aDecoder: NSCoder) {
//        self.init(
//            addressid: aDecoder.decodeStringForKey(CoderKey.addressID),
//            email: aDecoder.decodeStringForKey(CoderKey.email),
//            order: aDecoder.decodeInteger(forKey: CoderKey.order),
//            receive: aDecoder.decodeInteger(forKey: CoderKey.receive),
//            display_name: aDecoder.decodeStringForKey(CoderKey.display_name),
//            signature: aDecoder.decodeStringForKey(CoderKey.signature),
//            keys: aDecoder.decodeObject(forKey: CoderKey.keys) as?  [Key],
//            
//            status : aDecoder.decodeInteger(forKey: CoderKey.addressStatus),
//            type:aDecoder.decodeInteger(forKey: CoderKey.addressType),
//            send: aDecoder.decodeInteger(forKey: CoderKey.addressSend)
//        )
//    }
//    
//    func encode(with aCoder: NSCoder) {
//        aCoder.encode(address_id, forKey: CoderKey.addressID)
//        aCoder.encode(email, forKey: CoderKey.email)
//        aCoder.encode(order, forKey: CoderKey.order)
//        aCoder.encode(receive, forKey: CoderKey.receive)
//        aCoder.encode(display_name, forKey: CoderKey.display_name)
//        aCoder.encode(signature, forKey: CoderKey.signature)
//        aCoder.encode(keys, forKey: CoderKey.keys)
//        
//        aCoder.encode(status, forKey: CoderKey.addressStatus)
//        aCoder.encode(type, forKey: CoderKey.addressType)
//        
//        aCoder.encode(send, forKey: CoderKey.addressSend)
//    }
//}
//
//extension Array where Element : Address {
//    func defaultAddress() -> Address? {
//        for addr in self {
//            if addr.status == 1 && addr.receive == 1 {
//                return addr
//            }
//        }
//        return nil
//    }
//    
//    func defaultSendAddress() -> Address? {
//        for addr in self {
//            if addr.status == 1 && addr.receive == 1 && addr.send == 1{
//                return addr
//            }
//        }
//        return nil
//    }
//    
//    func indexOfAddress(_ addressid : String) -> Address? {
//        for addr in self {
//            if addr.status == 1 && addr.receive == 1 && addr.address_id == addressid {
//                return addr
//            }
//        }
//        return nil
//    }
//    
//    func getAddressOrder() -> [String] {
//        let ids = self.map { $0.address_id }
//        return ids
//    }
//    
//    func getAddressNewOrder() -> [Int] {
//        let ids = self.map { $0.order }
//        return ids
//    }
//    
//    func toKeys() -> [Key] {
//        var out_array = [Key]()
//        for i in 0 ..< self.count {
//            let addr = self[i]
//            for k in addr.keys {
//                out_array.append(k)
//            }
//        }
//        return out_array
//    }
//}
