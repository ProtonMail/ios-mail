//
//  Address+Fixtures.swift
//  ProtonCore-TestingToolkit - Created on 28.05.2021.
//
//  Copyright (c) 2021 Proton Technologies AG
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

public extension Address {

    static var dummy: Address {
        Address(addressID: .empty,
                domainID: nil,
                email: .empty,
                send: .inactive,
                receive: .inactive,
                status: .disabled,
                type: .protonDomain,
                order: .zero,
                displayName: .empty,
                signature: .empty,
                hasKeys: .zero,
                keys: .empty)
    }

    func updated(addressID: String? = nil,
                 domainID: String? = nil,
                 email: String? = nil,
                 send: AddressSendReceive? = nil,
                 receive: AddressSendReceive? = nil,
                 status: AddressStatus? = nil,
                 type: AddressType? = nil,
                 order: Int? = nil,
                 displayName: String? = nil,
                 signature: String? = nil,
                 hasKeys: Int? = nil,
                 keys: [Key]? = nil) -> Address {
        Address(addressID: addressID ?? self.addressID,
                domainID: domainID ?? self.domainID,
                email: email ?? self.email,
                send: send ?? self.send,
                receive: receive ?? self.receive,
                status: status ?? self.status,
                type: type ?? self.type,
                order: order ?? self.order,
                displayName: displayName ?? self.displayName,
                signature: signature ?? self.signature,
                hasKeys: hasKeys ?? self.hasKeys,
                keys: keys ?? self.keys)

    }

}
