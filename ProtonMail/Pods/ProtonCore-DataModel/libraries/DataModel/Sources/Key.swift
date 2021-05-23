//
//  Key.swift
//  ProtonCore-DataModel - Created on 4/19/21.
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
//

import Foundation

@objc public final class Key: NSObject {

    public let keyID: String
    public var privateKey: String
    
    // TODO:: this is a bit set. need to refactor to a struct
    public var keyFlags: Int = 0
    
    // key migration step 1 08/01/2019
    public var token: String?
    public var signature: String?
    
    // old activetion flow
    public var activation: String? // armed pgp msg, token encrypted by user's public key and
    
    // unused
    public var active: Int = 0
    public var version: Int = 0
    
    // the other way: first key will be the primary
    public var primary: Int = 0
    
    // local var use when update the key password
    public var isUpdated: Bool = false
    
    public init(keyID: String, privateKey: String?, keyFlags: Int = 0,
                token: String? = nil, signature: String? = nil, activation: String? = nil,
                active: Int = 0, version: Int = 0, primary: Int = 0, isUpdated: Bool = false) {
        self.keyID = keyID
        self.privateKey = privateKey ?? ""
        self.keyFlags = keyFlags
        self.token = token
        self.signature = signature
        self.activation = activation
        self.active = active
        self.version = version
        self.primary = primary
        self.isUpdated = isUpdated
    }
}

extension Key {
    override public func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Key else {
            return false
        }
        return self.keyID == rhs.keyID &&
            self.privateKey == rhs.privateKey &&
            self.keyFlags == rhs.keyFlags &&
            self.token == rhs.token &&
            self.signature == rhs.signature &&
            self.activation == rhs.activation &&
            self.active == rhs.active &&
            self.version == rhs.version &&
            self.primary == rhs.primary &&
            self.isUpdated == rhs.isUpdated
    }
}

@available(*, deprecated, renamed: "Key")
public typealias AddressKey = Key

@available(*, deprecated, renamed: "Key")
public typealias UserKey = Key

// exposed interfaces
extension Key {
    
    @available(*, deprecated, renamed: "isKeyV2")
    public var newSchema: Bool {
        return signature != nil
    }
    
    public var isKeyV2: Bool {
        return signature != nil
    }
}
