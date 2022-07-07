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

import Foundation

enum PublicKeysResponseTestData {
    static func successTestResponse(
        flags: Int,
        publicKey: String
    ) -> [String: Any] {
        let json = """
        {
          "Code": 1000,
          "RecipientType": 1,
          "MIMEType": "text/html",
          "Keys": [
            {
              "Flags": \(flags),
              "PublicKey": "\(publicKey)"
            }
          ],
          "SignedKeyList": {
            "MinEpochID": 1,
            "MaxEpochID": 437,
            "ExpectedMinEpochID": null,
            "Signature": "dummy string"
          },
          "Warnings": []
        }
        """
        let data = Data(json.utf8)
        return try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
    }
}
