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

/// Address Builder for building the packages
class PGPAddressBuilder: PackageBuilder {
    /// message body session key
    let session: Data
    let algo: String

    /// prepared attachment list
    let preAttachments: [PreAttachment]

    /// Initial
    ///
    /// - Parameters:
    ///   - type: SendType sending message type for address
    ///   - addr: message send to
    ///   - session: message encrypted body session key
    ///   - atts: prepared attachments
    init(type: SendType, addr: PreAddress, session: Data, algo: String, atts: [PreAttachment]) {
        self.session = session
        self.algo = algo
        self.preAttachments = atts
        super.init(type: type, addr: addr)
    }

    override func build() -> Promise<AddressPackageBase> {
        return async {
            var attPackages = [AttachmentPackage]()
            guard let publicKey = self.preAddress.pgpKey else {
                fatalError("Missing PGP key")
            }
            for att in self.preAttachments {
                let newKeyPack = try att.session.getKeyPackage(publicKey: publicKey, algo: att.algo)?
                    .base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
                let attPacket = AttachmentPackage(attID: att.attachmentId, attKey: newKeyPack)
                attPackages.append(attPacket)
            }

            let newKeypacket = try self.session.getKeyPackage(publicKey: publicKey, algo: self.algo)
            let newEncodedKey = newKeypacket?
                .base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
            let package = AddressPackage(email: self.preAddress.email,
                                         bodyKeyPacket: newEncodedKey,
                                         type: self.sendType,
                                         plainText: self.preAddress.plainText,
                                         attPackets: attPackages)
            return package
        }
    }
}
