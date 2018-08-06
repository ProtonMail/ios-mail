//
//  Key.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/1/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import Pm

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
