//
//  EncryptTypes.swift
//  ProtonMail - Created on 3/26/15.
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

    // TODO:: reneame
    enum EncryptType: Int, CustomStringConvertible {
        // case plain = 0          //Plain text
        case inner = 1       // ProtonMail encrypted emails
        case external = 2       // Encrypted from outside
        case outEnc = 3         // Encrypted for outside
        case outPlain = 4       // Send plain but stored enc
        case draftStoreEnc = 5  // Draft
        case outEncReply = 6    // Encrypted for outside reply

        case outPGPInline = 7    // out side pgp inline
        case outPGPMime = 8    // out pgp mime
        case outSignedPGPMime = 9 // PGP/MIME signed message

        // didn't in localizable string because no place show this yet
        var description: String {
            switch self {
            case .inner:
                return LocalString._general_enc_pm_emails
            case .external:
                return LocalString._general_enc_from_outside
            case .outEnc:
                return LocalString._general_enc_for_outside
            case .outPlain:
                return LocalString._general_send_plain_but_stored_enc
            case .draftStoreEnc:
                return LocalString._general_draft_action
            case .outEncReply:
                return LocalString._general_encrypted_for_outside_reply
            case .outPGPInline:
                return LocalString._general_enc_from_outside_pgp_inline
            case .outPGPMime:
                return LocalString._general_enc_from_outside_pgp_mime
            case .outSignedPGPMime:
                return LocalString._general_enc_from_outside_signed_pgp_mime
            }
        }
    }

    /// received and from protonmail internal
    var isInternal: Bool {
        get {
            return self.flag.contains(.internal) && self.flag.contains(.received)
        }
    }

    // signed mime also external message
    var isExternal: Bool {
        get {
            return !self.flag.contains(.internal) && self.flag.contains(.received)
        }
    }

    // 7  & 8
    var isE2E: Bool {
        get {
            return self.flag.contains(.e2e)
        }
    }

    // case outPGPInline = 7
    var isPgpInline: Bool {
        get {
            if isE2E, !isPgpMime {
                return true
            }
            return false
        }
    }

    // case outPGPMime = 8       // out pgp mime
    var isPgpMime: Bool {
        get {
            if let mt = self.mimeType, mt.lowercased() == MimeType.mutipartMixed, isExternal, isE2E {
                return true
            }
            return false
        }
    }

    // case outSignedPGPMime = 9 //PGP/MIME signed message
    var isSignedMime: Bool {
        get {
            if let mt = self.mimeType, mt.lowercased() == MimeType.mutipartMixed, isExternal, !isE2E {
                return true
            }
            return false
        }
    }

}
