//
//  EncryptTypes.swift
//  Proton Mail - Created on 3/26/15.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

extension Message {

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
