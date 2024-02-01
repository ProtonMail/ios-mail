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

import ProtonCoreDataModel
#if canImport(ProtonCoreTestingToolkitUnitTestsCore)
import ProtonCoreTestingToolkitUnitTestsCore
#endif

public extension User {

    static var dummy: User {
        User(ID: .empty,
             name: nil,
             usedSpace: .zero,
             usedBaseSpace: .zero,
             usedDriveSpace: .zero,
             currency: .empty,
             credit: .zero,
             createTime: nil,
             maxSpace: .zero,
             maxBaseSpace: .zero,
             maxDriveSpace: .zero,
             maxUpload: .zero,
             role: .zero,
             private: 1,
             subscribed: [],
             services: .zero,
             delinquent: .zero,
             orgPrivateKey: nil,
             email: nil,
             displayName: nil,
             keys: .empty,
             accountRecovery: nil)
    }

    func updated(ID: String? = nil,
                 name: String? = nil,
                 usedSpace: Int64? = nil,
                 usedBaseSpace: Int64? = nil,
                 usedDriveSpace: Int64? = nil,
                 currency: String? = nil,
                 credit: Int? = nil,
                 maxSpace: Int64? = nil,
                 maxBaseSpace: Int64? = nil,
                 maxDriveSpace: Int64? = nil,
                 maxUpload: Int64? = nil,
                 role: Int? = nil,
                 private: Int? = nil,
                 subscribed: User.Subscribed? = nil,
                 services: Int? = nil,
                 delinquent: Int? = nil,
                 orgPrivateKey: String? = nil,
                 email: String? = nil,
                 displayName: String? = nil,
                 keys: [Key]? = nil) -> User {
        User(ID: ID ?? self.ID,
             name: name ?? self.name,
             usedSpace: usedSpace ?? self.usedSpace,
             usedBaseSpace: usedBaseSpace ?? self.usedBaseSpace,
             usedDriveSpace: usedDriveSpace ?? self.usedDriveSpace,
             currency: currency ?? self.currency,
             credit: credit ?? self.credit,
             createTime: createTime ?? self.createTime,
             maxSpace: maxSpace ?? self.maxSpace,
             maxBaseSpace: maxBaseSpace ?? self.maxBaseSpace,
             maxDriveSpace: maxDriveSpace ?? self.maxDriveSpace,
             maxUpload: maxUpload ?? self.maxUpload,
             role: role ?? self.role,
             private: `private` ?? self.private,
             subscribed: subscribed ?? self.subscribed,
             services: services ?? self.services,
             delinquent: delinquent ?? self.delinquent,
             orgPrivateKey: orgPrivateKey ?? self.orgPrivateKey,
             email: email ?? self.email,
             displayName: displayName ?? self.displayName,
             keys: keys ?? self.keys,
             accountRecovery: nil)
    }
}
