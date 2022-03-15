//
//  Message+Header.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

extension Message {

    // case plain = 0            //Plain text
    // case inner = 1            // ProtonMail encrypted emails
    // case external = 2         // Encrypted from outside
    // case outEnc = 3           // Encrypted for outside
    // case outPlain = 4         // Send plain but stored enc
    // case draftStoreEnc = 5    // Draft
    // case outEncReply = 6      // Encrypted for outside reply
    //
    // case outPGPInline = 7     // out side pgp inline
    // case outPGPMime = 8       // out pgp mime
    // case outSignedPGPMime = 9 //PGP/MIME signed message

    func getInboxType(email: String, signature: SignStatus) -> PGPType {
        guard self.isDetailDownloaded else {
            return .none
        }

        if self.isInternal {
            return .internal_normal
        }

        if isE2E { // outPGPInline, outPGPMime
            return .pgp_encrypted
        }

        if isSignedMime { // outSignedPGPMime
            return .zero_access_store
        }

        if self.isExternal {
            return .zero_access_store
        }

        return .none
    }

    func getSentLockType(email: String) -> PGPType {
        guard self.isDetailDownloaded  else {
            return .none
        }

        guard let header = self.header, let raw = header.data(using: .utf8), let mainPart = Part(header: raw) else {
            return .none
        }

        let autoReply = mainPart.headers.first { (left) -> Bool in
            return left.name == "X-Autoreply"
        }

        if self.senderContactVO.email == email {
            // TODO:: use flags to check auto reply
            var autoreply = false
            if let body = autoReply?.body, body == "yes" {
                autoreply = true
            }
            if autoreply {
                return .sent_sender_server
            }

            if !self.unencrypt_outside {
                let encryption = mainPart.headers.first { (left) -> Bool in
                    return left.name == "X-Pm-Recipient-Encryption"
                }
                if let enc = encryption {
                    for (_, enctype) in enc.headerKeyValues {
                        if enctype == "none" {
                            self.unencrypt_outside = true
                            break
                        }
                    }
                }
            }

            if self.unencrypt_outside {
                return .sent_sender_out_side
            }
            return .sent_sender_encrypted
        }

        let authentication = mainPart.headers.first { (left) -> Bool in
            return left.name == "X-Pm-Recipient-Authentication"
        }

        let encryption = mainPart.headers.first { (left) -> Bool in
            return left.name == "X-Pm-Recipient-Encryption"
        }

        guard let auth = authentication, let enc = encryption else {
            return .none
        }

        guard let authtype = auth.headerKeyValues[email], let enctype = enc.headerKeyValues[email] else {
            return .none
        }

        if enctype == "none" {
            self.unencrypt_outside = true
        }

        if authtype == "pgp-inline" {
            if enctype == "pgp-inline-pinned" {
                return .pgp_encrypt_trusted_key
            } else if enctype == "none" {
                return .pgp_signed
            }
            return .pgp_encrypted
        }

        if authtype == "pgp-pm" {
            if enctype == "pgp-pm-pinned" {
                return .internal_trusted_key
            }
            return .internal_normal
        }

        if authtype == "pgp-mime" {
            if enctype == "pgp-mime-pinned" {
                return .pgp_encrypt_trusted_key
            } else if enctype == "none" {
                return .pgp_signed
            }
            return .pgp_encrypted
        }

        if authtype == "pgp-eo" {
            return .eo
        }

        if authtype == "none" {
            if enctype == "pgp-pm" {
                return .internal_normal
            }
            if enctype == "pgp-mime" || enctype == "pgp-inline" {
                return .pgp_encrypted
            }
            if enctype == "pgp-mime-pinned" || enctype == "pgp-inline-pinned" {
                return .pgp_encrypt_trusted_key
            }
            if enctype == "pgp-pm-pinned" {
                return .internal_trusted_key
            }

            return .none
        }

        return .none

    }

}
