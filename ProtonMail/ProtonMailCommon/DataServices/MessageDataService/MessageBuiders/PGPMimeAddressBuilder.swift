// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import AwaitKit
import PromiseKit

/// Address Builder for building the packages
class PGPMimeAddressBuilder: PackageBuilder {
    /// message body session key
    let session: Data
    let algo: String
    /// Initial
    ///
    /// - Parameters:
    ///   - type: SendType sending message type for address
    ///   - addr: message send to
    ///   - session: message encrypted body session key
    init(type: SendType, addr: PreAddress, session: Data, algo: String) {
        self.session = session
        self.algo = algo
        super.init(type: type, addr: addr)
    }

    override func build() -> Promise<AddressPackageBase> {
        return async {
            guard let publicKey = self.preAddress.pgpKey else {
                fatalError("Missing PGP key")
            }
            let newKeypacket = try self.session.getKeyPackage(publicKey: publicKey, algo: self.algo)
            let newEncodedKey = newKeypacket?
                .base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""

            let package = MimeAddressPackage(email: self.preAddress.email,
                                             bodyKeyPacket: newEncodedKey,
                                             type: self.sendType,
                                             plainText: self.preAddress.plainText)
            return package
        }
    }
}
