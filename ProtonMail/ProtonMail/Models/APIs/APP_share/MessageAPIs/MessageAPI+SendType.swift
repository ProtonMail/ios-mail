//
//  MessageAPI+SendType.swift
//  Proton Mail - Created on 4/12/18.
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
import ProtonCore_Networking

struct SendType: OptionSet {
    let rawValue: Int

    static let proton    = SendType(rawValue: 1 << 0)
    static let encryptedToOutside      = SendType(rawValue: 1 << 1)
    static let cleartextInline   = SendType(rawValue: 1 << 2)
    static let pgpInline = SendType(rawValue: 1 << 3)
    static let pgpMIME = SendType(rawValue: 1 << 4)
    static let cleartextMIME   = SendType(rawValue: 1 << 5)
}
