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

/// Internal Address Builder for building the packages
class InternalAddressBuilder: PackageBuilder {
    /// message body session key
    let session: Data
    let algo: Algorithm
    let preAttachments: [PreAttachment]

    init(
        type: PGPScheme,
        email: String,
        sendPreferences: SendPreferences,
        session: Data,
        algo: Algorithm,
        atts: [PreAttachment]
    ) {
        self.session = session
        self.algo = algo
        self.preAttachments = atts
        super.init(type: type, email: email, sendPreferences: sendPreferences)
    }

    override func build() -> Promise<AddressPackageBase> {
        return async {
            var attPackages = [AttachmentPackage]()
            for attachment in self.preAttachments {
                if let publicKey = self.sendPreferences.publicKeys {
                    let newKeyPack = try attachment.session.getKeyPackage(publicKey: publicKey.getPublicKey(), algo: attachment.algo.rawValue)?
                        .base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
                    let attPacket = AttachmentPackage(attachmentID: attachment.attachmentId, attachmentKey: newKeyPack)
                    attPackages.append(attPacket)
                }
            }

            if let publicKey = self.sendPreferences.publicKeys {
                let newKeypacket = try self.session.getKeyPackage(publicKey: publicKey.getPublicKey(), algo: self.algo.rawValue)
                let newEncodedKey = newKeypacket?
                    .base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
                let addr = AddressPackage(email: self.email,
                                          bodyKeyPacket: newEncodedKey,
                                          scheme: self.sendType,
                                          plainText: self.sendPreferences.mimeType == .plainText,
                                          attachmentPackages: attPackages)
                return addr
            } else {
                let newKeypacket = try self.session.getKeyPackage(
                    publicKey: .empty,
                    algo: self.algo.rawValue
                )
                let newEncodedKey = newKeypacket?
                    .base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
                let addr = AddressPackage(email: self.email,
                                          bodyKeyPacket: newEncodedKey,
                                          scheme: self.sendType,
                                          plainText: self.sendPreferences.mimeType == .plainText,
                                          attachmentPackages: attPackages)
                return addr
            }
        }
    }
}
