//
//  Key.swift
//  ProtonMail - Created on 8/1/18.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation
import Crypto

@objc(Key)
final class Key : NSObject {
    let key_id: String
    var private_key : String
    var is_updated : Bool = false
    var keyflags : Int = 0
    
    //key migration step 1 08/01/2019
    var token : String?
    var signature : String?
    
    //old activetion flow
    var activation : String? // armed pgp msg, token encrypted by user's public key and
    
    required init(key_id: String?, private_key: String?,
                  token: String?, signature: String?, activation: String?,
                  isupdated: Bool) {
        self.key_id = key_id ?? ""
        self.private_key = private_key ?? ""
        self.is_updated = isupdated
        
        self.token = token
        self.signature = signature
        
        self.activation = activation
    }
    
    var publicKey : String {
        return KeyPublicKey(self.private_key, nil)
    }
    
    var fingerprint : String {
        return KeyGetFingerprint(self.private_key, nil)
    }
    
    var newSchema : Bool {
        return signature != nil
    }
}


extension Key: NSCoding {
    
    private struct CoderKey {
        static let keyID          = "keyID"
        static let privateKey     = "privateKey"
        static let fingerprintKey = "fingerprintKey"
        
        static let Token     = "Key.Token"
        static let Signature = "Key.Signature"
        //
        static let Activation = "Key.Activation"
    }
    
    static func unarchive(_ data: Data?) -> [Key]? {
        guard let data = data else { return nil }
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? [Key]
    }
    
    
    convenience init(coder aDecoder: NSCoder) {
        self.init(
            key_id: aDecoder.decodeStringForKey(CoderKey.keyID),
            private_key: aDecoder.decodeStringForKey(CoderKey.privateKey),
            token: aDecoder.decodeStringForKey(CoderKey.Token),
            signature: aDecoder.decodeStringForKey(CoderKey.Signature),
            activation: aDecoder.decodeStringForKey(CoderKey.Activation),
            isupdated: false)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(key_id, forKey: CoderKey.keyID)
        aCoder.encode(private_key, forKey: CoderKey.privateKey)
        
        //new added
        aCoder.encode(token, forKey: CoderKey.Token)
        aCoder.encode(signature, forKey: CoderKey.Signature)
        
        //
        aCoder.encode(activation, forKey: CoderKey.Activation)
        
        //TODO:: fingerprintKey is deprecated, need to "remove and clean"
        aCoder.encode("", forKey: CoderKey.fingerprintKey)
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
    
    
    var newSchema : Bool {
        for key in self {
            if key.newSchema {
                return true
            }
        }
        return false
    }

}
