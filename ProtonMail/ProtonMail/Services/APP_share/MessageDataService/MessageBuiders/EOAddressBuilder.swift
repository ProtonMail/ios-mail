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

import OpenPGP
import PromiseKit
import ProtonCore_APIClient
import ProtonCore_Services

/// Encrypt outside address builder
class EOAddressBuilder: PackageBuilder {
    let password: String
    let passwordHint: String?
    let session: Data
    let algo: String

    /// prepared attachment list
    let preAttachments: [PreAttachment]

    init(type: PGPScheme,
         email: String,
         sendPreferences: SendPreferences,
         session: Data,
         algo: String,
         password: String,
         atts: [PreAttachment],
         passwordHint: String?) {
        self.session = session
        self.algo = algo
        self.password = password
        self.preAttachments = atts
        self.passwordHint = passwordHint
        super.init(type: type, email: email, sendPreferences: sendPreferences)
    }

    override func build() -> Promise<AddressPackageBase> {
        return async {
            let encodedKeyPackage = try self.session.getSymmetricPacket(withPwd: self.password, algo: self.algo)?
                .base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
            // create outside encrypt packet
            let token = String.randomString(32) as String
            let based64Token = token.encodeBase64() as String
            let encryptedToken = try based64Token.encryptNonOptional(password: self.password)

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
                let attPacket = AttachmentPackage(attachmentID: att.attachmentId, attachmentKey: newKeyPack)
                attPack.append(attPacket)
            }

            let package = EOAddressPackage(token: based64Token,
                                           encToken: encryptedToken,
                                           auth: authPacket,
                                           passwordHint: self.passwordHint,
                                           email: self.email,
                                           bodyKeyPacket: encodedKeyPackage,
                                           plainText: self.sendPreferences.mimeType == .plainText,
                                           attachmentPackages: attPack,
                                           scheme: self.sendType)
            return package
        }
    }
}
