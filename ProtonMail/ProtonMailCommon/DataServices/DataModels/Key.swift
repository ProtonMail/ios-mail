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
        return KeyPublicKey(self.private_key, nil)
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
