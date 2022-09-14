// Copyright (c) 2021 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import PromiseKit
import ProtonCore_Crypto

/// Address Builder for building the packages
class PGPMimeAddressBuilder: PackageBuilder {
    /// message body session key
    let session: Data
    let algo: Algorithm

    init(
        type: PGPScheme,
        email: String,
        sendPreferences: SendPreferences,
        session: Data,
        algo: Algorithm
    ) {
        self.session = session
        self.algo = algo
        super.init(type: type, email: email, sendPreferences: sendPreferences)
    }

    override func build() -> Promise<AddressPackageBase> {
        return async {
            guard let publicKey = self.sendPreferences.publicKeys else {
                fatalError("Missing PGP key")
            }
            let newKeypacket = try self.session.getKeyPackage(publicKey: publicKey.getPublicKey(), algo: self.algo.rawValue)
            let newEncodedKey = newKeypacket?
                .base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""

            let package = MimeAddressPackage(email: self.email,
                                             bodyKeyPacket: newEncodedKey,
                                             scheme: self.sendType,
                                             plainText: self.sendPreferences.mimeType == .plainText)
            return package
        }
    }
}
