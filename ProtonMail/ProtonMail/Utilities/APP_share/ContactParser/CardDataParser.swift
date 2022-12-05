// Copyright (c) 2022 Proton AG
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

import Crypto
import Foundation
import OpenPGP
import PromiseKit
import ProtonCore_DataModel
import ProtonCore_Log

#if !APP_EXTENSION
import LifetimeTracker
#endif

class CardDataParser {
    private let userKeys: [Key]

    init(userKeys: [Key]) {
        self.userKeys = userKeys

#if !APP_EXTENSION
        trackLifetime()
#endif
    }

    func verifyAndParseContact(with email: String, from cards: [CardData]) -> Promise<PreContact> {
        return Promise { seal in
            async {
                if let contact = self.verifyAndParseContact(with: email, from: cards) {
                    return seal.fulfill(contact)
                }
                // TODO::need to improve the error part
                seal.reject(NSError.badResponse())
            }
        }
    }

    // swiftlint:disable:next function_body_length
    func verifyAndParseContact(with email: String, from cards: [CardData]) -> PreContact? {
        for card in cards {
            switch card.type {
            case .SignedOnly:
                guard self.verifySignature(of: card) else {
                    continue
                }

                if let vcard = PMNIEzvcard.parseFirst(card.data) {
                    let emails = vcard.getEmails()
                    for vcardEmail in emails where email == vcardEmail.getValue() {
                        let group = vcardEmail.getGroup()
                        let encrypt = vcard.getPMEncrypt(group)
                        let sign = vcard.getPMSign(group)
                        let isSign = sign?.getValue() ?? "false" == "true" ? true : false
                        let keys = vcard.getKeys(group)
                        let isEncrypt = encrypt?.getValue() ?? "false" == "true" ? true : false
                        let schemeType = vcard.getPMScheme(group)
                        let isMime = schemeType?.getValue() ?? "pgp-mime" == "pgp-mime" ? true : false
                        let mimeType = vcard.getPMMimeType(group)?.getValue()
                        let plainText = mimeType ?? "text/html" == "text/html" ? false : true

                        var firstKey: Data?
                        var pubKeys: [Data] = []
                        for key in keys {
                            let keyGroup = key.getGroup()
                            if keyGroup == group {
                                let keyPref = key.getPref()
                                let value = key.getBinary() // based 64 key
                                if let cryptoKey = CryptoKey(value), !cryptoKey.isExpired() {
                                    pubKeys.append(value)
                                    if keyPref == 1 || keyPref == Int32.min {
                                        firstKey = value
                                    }
                                }
                            }
                        }
                        let preContact = PreContact(
                            email: email,
                            pubKey: firstKey,
                            pubKeys: pubKeys,
                            sign: isSign,
                            encrypt: isEncrypt,
                            mime: isMime,
                            plainText: plainText,
                            isContactSignatureVerified: true,
                            scheme: schemeType?.getValue(),
                            mimeType: mimeType
                        )
                        return preContact
                    }
                }
            default:
                // see https://confluence.protontech.ch/display/MAILFE/Contact+vCard
                // for the explanation why we only look for .SignedOnly
                break
            }
        }
        return nil
    }

    private func verifySignature(of cardData: CardData) -> Bool {
        let binKeys = userKeys.compactMap { try? CryptoKey(fromArmored: $0.privateKey)?.getPublicKey() }

        do {
            return try MailCrypto().verifyDetached(
                signature: cardData.sign,
                plainText: cardData.data,
                binKeys: binKeys
            )
        } catch {
            PMLog.error(error)
            return false
        }
    }
}

#if !APP_EXTENSION
extension CardDataParser: LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }
}
#endif
