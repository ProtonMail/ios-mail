//
//  Address+Extensions.swift
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

extension Array where Element: Address {
    
    /// find the default address.  status is enable and receive is active
    /// - Returns: address | nil
    public func defaultAddress() -> Address? {
        for addr in self {
            if addr.status == .enabled && addr.receive == .active {
                return addr
            }
        }
        return nil
    }
    
    /// find the default send address. status is enable, receive is acitve, send is active
    /// - Returns: address | nil
    public func defaultSendAddress() -> Address? {
        for addr in self {
            if addr.status == .enabled && addr.receive == .active && addr.send == .active {
                return addr
            }
        }
        return nil
    }
    
    /// lookup the first active address
    /// - Parameter addressID: address id
    /// - Returns: address | nil
    public func address(byID addressID: String) -> Address? {
        for addr in self {
            if addr.status == .enabled && addr.receive == .active && addr.addressID == addressID {
                return addr
            }
        }
        return nil
    }
    
    @available(*, deprecated, renamed: "address(byID:)")
    public func indexOfAddress(_ addressid: String) -> Address? {
        for addr in self {
            if addr.status == .enabled && addr.receive == .active && addr.addressID == addressid {
                return addr
            }
        }
        return nil
    }
    
    public func getAddressOrder() -> [String] {
        let ids = self.map { $0.addressID }
        return ids
    }
    
    /// forgot what is this and when will use this
    /// - Returns: description
    func getAddressNewOrder() -> [Int] {
        let ids = self.map { $0.order }
        return ids
    }
    
    /// collect all keys in all addresses
    /// - Returns: [Key]
    public func toKeys() -> [Key] {
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
