//
//  User+Fixtures.swift
//  ProtonCore-TestingToolkit - Created on 03.06.2021.
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

import ProtonCore_DataModel

public extension User {

    static var dummy: User {
        User(ID: .empty,
             name: nil,
             usedSpace: .zero,
             currency: .empty,
             credit: .zero,
             maxSpace: .zero,
             maxUpload: .zero,
             role: .zero,
             private: 1,
             subscribed: .zero,
             services: .zero,
             delinquent: .zero,
             orgPrivateKey: nil,
             email: nil,
             displayName: nil,
             keys: .empty)
    }
    
    func updated(ID: String? = nil,
                 name: String? = nil,
                 usedSpace: Double? = nil,
                 currency: String? = nil,
                 credit: Int? = nil,
                 maxSpace: Double? = nil,
                 maxUpload: Double? = nil,
                 role: Int? = nil,
                 private: Int? = nil,
                 subscribed: Int? = nil,
                 services: Int? = nil,
                 delinquent: Int? = nil,
                 orgPrivateKey: String? = nil,
                 email: String? = nil,
                 displayName: String? = nil,
                 keys: [Key]? = nil) -> User {
        User(ID: ID ?? self.ID,
             name: name ?? self.name,
             usedSpace: usedSpace ?? self.usedSpace,
             currency: currency ?? self.currency,
             credit: credit ?? self.credit,
             maxSpace: maxSpace ?? self.maxSpace,
             maxUpload: maxUpload ?? self.maxUpload,
             role: role ?? self.role,
             private: `private` ?? self.private,
             subscribed: subscribed ?? self.subscribed,
             services: services ?? self.services,
             delinquent: delinquent ?? self.delinquent,
             orgPrivateKey: orgPrivateKey ?? self.orgPrivateKey,
             email: email ?? self.email,
             displayName: displayName ?? self.displayName,
             keys: keys ?? self.keys)
    }
}
