//
//  KeysAPI.swift
//  ProtonMail - Created on 11/11/16.
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
import PromiseKit
import Crypto
import ProtonCore_Networking
import ProtonCore_DataModel

///MARK: This file is prepared for future key manager framwork

/// The key apis path
let path : String = "/keys"

/// Signed key list. package for SetupKeyRequest
final class SignedKeyList : Package {
    
    ///"Data": JSON.stringify([
    ///{
    ///  "SHA256Fingerprints": ["164ec63...53c93f7", "f767d...f53b0c"],
    ///  "Fingerprint": "c93f767df53b0ca8395cfde90483475164ec6353",
    ///  "Primary": 1,
    ///  "Flags": 3
    ///  }
    ///]),
    let data : String
    
    /// "-----BEGIN PGP SIGNATURE-----.*"
    let signature: String
    
    /// signed key list Init
    /// - Parameters:
    ///   - data: Keylist Raw array  [KeyListRaw] to json string
    ///   - signature: Detached signature of data
    init(data: String, signature: String) {
        self.data = data
        self.signature = signature
    }
    
    var parameters: [String : Any]? {
        return [
            "Data": self.data,
            "Signature": self.signature
        ]
    }
}
