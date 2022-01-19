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
import OpenPGP
import PromiseKit
import ProtonCore_APIClient
import ProtonCore_Services

/// Encrypt outside address builder
class EOAddressBuilder: PackageBuilder {
    let password: String
    let hit: String?
    let session: Data
    let algo: String

    /// prepared attachment list
    let preAttachments: [PreAttachment]

    init(type: SendType,
         addr: PreAddress,
         session: Data,
         algo: String,
         password: String,
         atts: [PreAttachment],
         hit: String?) {
        self.session = session
        self.algo = algo
        self.password = password
        self.preAttachments = atts
        self.hit = hit
        super.init(type: type, addr: addr)
    }

    override func build() -> Promise<AddressPackageBase> {
        return async {
            let encodedKeyPackage = try self.session.getSymmetricPacket(withPwd: self.password, algo: self.algo)?
                .base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
            // create outside encrypt packet
            let token = String.randomString(32) as String
            let based64Token = token.encodeBase64() as String
            let encryptedToken = try based64Token.encrypt(withPwd: self.password) ?? ""

            // start build auth package
            let authModuls: AuthModulusResponse = try `await`(
                PMAPIService.shared.run(route: AuthAPI.Router.modulus)
            )
            guard let modulsId = authModuls.ModulusID else {
                throw UpdatePasswordError.invalidModulusID.error
            }
            guard let newModuls = authModuls.Modulus else {
                throw UpdatePasswordError.invalidModulus.error
            }

            // generat new verifier
            let newSaltForLoginPwd: Data = PMNOpenPgp.randomBits(80) // for the login password needs to set 80 bits

            guard let auth = try SrpAuthForVerifier(self.password, newModuls, newSaltForLoginPwd) else {
                throw UpdatePasswordError.cantHashPassword.error
            }

            let verifier = try auth.generateVerifier(2_048)
            let authPacket = PasswordAuth(modulus_id: modulsId,
                                          salt: newSaltForLoginPwd.encodeBase64(),
                                          verifer: verifier.encodeBase64())

            var attPack: [AttachmentPackage] = []
            for att in self.preAttachments {
                let newKeyPack = try att.session.getSymmetricPacket(withPwd: self.password, algo: att.algo)?
                    .base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
                let attPacket = AttachmentPackage(attID: att.attachmentId, attKey: newKeyPack)
                attPack.append(attPacket)
            }

            let package = EOAddressPackage(token: based64Token,
                                           encToken: encryptedToken,
                                           auth: authPacket,
                                           pwdHit: self.hit,
                                           email: self.preAddress.email,
                                           bodyKeyPacket: encodedKeyPackage,
                                           plainText: self.preAddress.plainText,
                                           attPackets: attPack,
                                           type: self.sendType)
            return package
        }
    }
}
