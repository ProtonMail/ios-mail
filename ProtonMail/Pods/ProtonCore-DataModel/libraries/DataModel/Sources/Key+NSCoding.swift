//
//  Key+NSCoding.swift
//  ProtonCore-DataModel - Created on 4/19/21.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCore_Utilities

// This NSCoding is used for archive the object to data then encrypt it before save to keychain.
//   will need to redesign to save this to core data
extension Key: NSCoding {
    private struct CoderKey {
        static let keyID          = "keyID"
        static let privateKey     = "privateKey"
        
        //
        static let flags = "Key.Flags"
        
        //
        static let token     = "Key.Token"
        static let signature = "Key.Signature"
        
        //
        static let activation = "Key.Activation"
        
        //
        static let primary = "Key.Primary"
        static let active = "Key.Active"
        static let version = "Key.Version"
    }
    
    static func unarchive(_ data: Data?) -> [Key]? {
        guard let data = data else { return nil }
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? [Key]
    }
    
    public convenience init(coder aDecoder: NSCoder) {
        
        let keyID = aDecoder.string(forKey: CoderKey.keyID)
        let privateKey = aDecoder.string(forKey: CoderKey.privateKey)
        
        let flags = aDecoder.decodeInteger(forKey: CoderKey.flags)
        
        let token = aDecoder.string(forKey: CoderKey.token)
        let signature = aDecoder.string(forKey: CoderKey.signature)
        
        let activation = aDecoder.string(forKey: CoderKey.activation)
        
        let active = aDecoder.decodeInteger(forKey: CoderKey.active)
        let version = aDecoder.decodeInteger(forKey: CoderKey.version)
        
        let primary = aDecoder.decodeInteger(forKey: CoderKey.primary)
        
        self.init(keyID: keyID ?? "", privateKey: privateKey,
                  keyFlags: flags,
                  token: token, signature: signature, activation: activation,
                  active: active,
                  version: version,
                  primary: primary)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.keyID, forKey: CoderKey.keyID)
        aCoder.encode(self.privateKey, forKey: CoderKey.privateKey)
        
        aCoder.encode(self.keyFlags, forKey: CoderKey.flags)
        
        aCoder.encode(self.token, forKey: CoderKey.token)
        aCoder.encode(self.signature, forKey: CoderKey.signature)
        
        aCoder.encode(self.activation, forKey: CoderKey.activation)
        
        aCoder.encode(self.active, forKey: CoderKey.active)
        aCoder.encode(self.version, forKey: CoderKey.version)
        
        aCoder.encode(self.primary, forKey: CoderKey.primary)
    }
}
