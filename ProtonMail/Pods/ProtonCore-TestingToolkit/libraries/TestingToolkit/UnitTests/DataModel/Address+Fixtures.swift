//
//  Address+Fixtures.swift
//  ProtonCore-TestingToolkit-a7641708
//
//  Created by Krzysztof Siejkowski on 28/05/2021.
//

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
