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

enum ConversationLabelResponseTestData {
    static func successTestResponse() -> [String: Any] {
        let json = """
        {
          "Code": 1001,
          "Responses": [
            {
              "ID": "EULki1s_TdGX6IUsyBWA1NWDdJPEIDNTIHZPrLkdP1bcqrnS1jccRa1iuTlQNLKI3xNu6Hi61ZVigAhddC9mmA==",
              "Response": {
                "Code": 1000
              }
            }
          ],
          "UndoToken": {
            "Token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL3Byb3Rvbm1haWwuY29tIiwiYXVkIjoiaHR0cHM6Ly9wcm90b25tYWlsLmNvbSIsImlhdCI6MTY1OTQ0OTA3MC42Mjk5NDUsImV4cCI6MTY1OTQ0OTEzMCwiRGF0YSI6IjFkNXBKT1AzSFFnbEg0dFpWbWdwaWNLcXd5d2RYeEZZVkRUYU95NnFDalZQamFhVkZzV3VLX25DVmdzWnMxODJmdWRPZHVRQmJVVzJoaVNkdnhIaVpoY2FKdkgtbEFvNHVnc3d5dG5CV2t6eU9QbmdNa3JKSkZqZmZwN2VsQUFBRlV1WWVDOUhoa0J5SjhlUDlpbTFkUTcyN1ZsZURXMTlLWFlzbTVRYVh2TS1JV19KbUE0bTBIQjVGeHVZODE3Z09UcG1NYTFJM1FRTGRFR1llaEtKN2ZDdzgwU2kyMTRnQW9YZ2RNM2tVN05ac0pZek40ME1tcHN3YnozUTFCVGhGenB6alVSOVZwYWl0OEZHbXJIMUtnPT0ifQ.Zlw_-zHM72eRzGc6PTpMS0O8EDcSeW-3L-EZjeTCrgs",
            "ValidUntil": 1659449130
          }
        }
        """
        let data = Data(json.utf8)
        return try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
    }
}
