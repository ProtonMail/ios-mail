//
//  UserInfo.swift
//  ProtonMail
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
import ProtonCore_DataModel

extension UserInfo {
    static let viewMode = "viewMode"
    enum ViewMode: Int {
        case conversation = 0
        case singleMessage = 1
    }
    
    var viewMode: ViewMode {
        // Rebase TODO: viewmode related things
        // Archive(), unarchive() ... etc
        return .singleMessage
    }
    
    var addressPrivateKeys : Data {
        var out = Data()
        var error : NSError?
        for addr in userAddresses {
            for key in addr.keys {
                if let privK = ArmorUnarmor(key.privateKey, &error) {
                    out.append(privK)
                }
            }
        }
        return out
    }
    
    var addressPrivateKeysArray: [Data] {
        var out: [Data] = []
        var error: NSError?
        for addr in userAddresses {
            for key in addr.keys {
                if let privK = ArmorUnarmor(key.privateKey, &error) {
                    out.append(privK)
                }
            }
        }
        return out
    }
}
