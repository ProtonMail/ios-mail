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

enum ContactResponseTestData {
    static func jsonResponse() -> [String: Any] {
        let json = """
        {
          "Code": 1000,
          "Contact": {
            "ID": "79dLmGyv8zj7xHBTuM268h4EZ0VieANmHdf4RQuDzD8CsVncAerd573Kgti1NcT6z7ncZNUetabNe00DsqoeJw==",
            "Name": "made-up@proton.me",
            "UID": "proton-autosave-95ccfbab-f858-447d-8527-8a051c6beed2",
            "Size": 0,
            "CreateTime": 1646124784,
            "ModifyTime": 1646124784,
            "Cards": [
              {
                "Type": 0,
                "Data": "",
                "Signature": null
              }
            ],
            "ContactEmails": [
              {
                "ID": "jChqyiDF965ct1m25JjYowUa913Gk3mnyZ6kqy67ocyy8ccp0s0YGIP-hBoOq-I8ACFRVcKICjWm7rOVz4Kveg==",
                "Name": "made-up@proton.me",
                "Email": "made-up@proton.me",
                "Type": [],
                "Defaults": 1,
                "Order": 1,
                "LastUsedTime": 1646124784,
                "ContactID": "99dLmGyv8zj7xHBTuM268h4EZ0VieANmddf4RQuDzD8CsVncAerd573Kgti1NcT6z7ncZNUetabNe00DsqoeJw==",
                "LabelIDs": []
              }
            ],
            "LabelIDs": []
          }
        }
        """
        let data = Data(json.utf8)
        return try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
    }
}
