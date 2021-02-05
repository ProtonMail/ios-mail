//
//  Key.swift
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
import Crypto
import PMCommon

//@objc(Key)
//final class Key : NSObject {
//    let key_id: String
//    var private_key : String
//    var is_updated : Bool = false
//    var keyflags : Int = 0
//    
//    //key migration step 1 08/01/2019
//    var token : String?
//    var signature : String?
//    
//    //old activetion flow
//    var activation : String? // armed pgp msg, token encrypted by user's public key and
//    
//    required init(key_id: String?, private_key: String?,
//                  token: String?, signature: String?, activation: String?,
//                  isupdated: Bool) {
//        self.key_id = key_id ?? ""
//        self.private_key = private_key ?? ""
//        self.is_updated = isupdated
//        
//        self.token = token
//        self.signature = signature
//        
//        self.activation = activation
//    }
//    
//    var publicKey : String {
//        return self.private_key.publicKey
//    }
//    
//    var fingerprint : String {
//        return self.private_key.fingerprint
//    }
//    
//    var shortFingerpritn : String {
//        let fignerprint = self.fingerprint
//        if fignerprint.count > 8 {
//            return String(fignerprint.prefix(8))
//        }
//        return fignerprint
//    }
//    
//    var newSchema : Bool {
//        return signature != nil
//    }
//}
//
//
//extension Key: NSCoding {
//    
//    private struct CoderKey {
//        static let keyID          = "keyID"
//        static let privateKey     = "privateKey"
//        static let fingerprintKey = "fingerprintKey"
//        
//        static let Token     = "Key.Token"
//        static let Signature = "Key.Signature"
//        //
//        static let Activation = "Key.Activation"
//    }
//    
//    static func unarchive(_ data: Data?) -> [Key]? {
//        guard let data = data else { return nil }
//        return NSKeyedUnarchiver.unarchiveObject(with: data) as? [Key]
//    }
//    
//    
//    convenience init(coder aDecoder: NSCoder) {
//        self.init(
//            key_id: aDecoder.decodeStringForKey(CoderKey.keyID),
//            private_key: aDecoder.decodeStringForKey(CoderKey.privateKey),
//            token: aDecoder.decodeStringForKey(CoderKey.Token),
//            signature: aDecoder.decodeStringForKey(CoderKey.Signature),
//            activation: aDecoder.decodeStringForKey(CoderKey.Activation),
//            isupdated: false)
//    }
//    
//    func encode(with aCoder: NSCoder) {
//        aCoder.encode(key_id, forKey: CoderKey.keyID)
//        aCoder.encode(private_key, forKey: CoderKey.privateKey)
//        
//        //new added
//        aCoder.encode(token, forKey: CoderKey.Token)
//        aCoder.encode(signature, forKey: CoderKey.Signature)
//        
//        //
//        aCoder.encode(activation, forKey: CoderKey.Activation)
//        
//        //TODO:: fingerprintKey is deprecated, need to "remove and clean"
//        aCoder.encode("", forKey: CoderKey.fingerprintKey)
//    }
//}




extension Key {

    var publicKey : String {
        return self.private_key.publicKey
    }
    
    var fingerprint : String {
        return self.private_key.fingerprint
    }

    var shortFingerpritn: String {
        let fignerprint = self.fingerprint
        if fignerprint.count > 8 {
            return String(fignerprint.prefix(8))
        }
        return fignerprint
    }
}

extension Array where Element : Key {
    func archive() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }
    
    var binPrivKeys : Data {
        var out = Data()
        var error : NSError?
        for key in self {
            if let privK = ArmorUnarmor(key.private_key, &error) {
                out.append(privK)
            }
        }
        return out
    }
    
    var binPrivKeysArray: [Data] {
        var out: [Data] = []
        var error: NSError?
        for key in self {
            if let privK = ArmorUnarmor(key.private_key, &error) {
                out.append(privK)
            }
        }
        return out
    }
    
    var newSchema : Bool {
        for key in self {
            if key.newSchema {
                return true
            }
        }
        return false
    }
    
}
