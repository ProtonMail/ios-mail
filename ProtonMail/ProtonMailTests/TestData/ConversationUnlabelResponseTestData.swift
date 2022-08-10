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

enum ConversationUnlabelResponseTestData {
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
            "Token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL3Byb3Rvbm1haWwuY29tIiwiYXVkIjoiaHR0cHM6Ly9wcm90b25tYWlsLmNvbSIsImlhdCI6MTY1OTQ0OTA4NC4wNDY0Mjg5LCJleHAiOjE2NTk0NDkxNDQsIkRhdGEiOiJyOE1BeTdOZTZhQkJ2N25pUDJudkRnVWhhWEVLSjFsYWFUal8wMG9VN1gzRjFzd190MXlMX2ptR2k1eFhadW82bG1fWXF0Sjh4VGxrcVR2dWxSYzlHODZHMldCdlVveW44M1hMdzFzNHF3MVE4RDZESDNkQlIyOVFLM3A5RWxqMk95d1FfT19CNUJkOE5PdEVaNFF3NWFpNUV5YmxIQURmUFF1SmJOWENBWmluOVAyNHJJZXphd1l1NEZvOFRtUXRPclhIMWJTNnllblVHY1JURHlmNHZNZlZqODRpZDN2cThsZDB5blRYVWJLVmZWNjFwcW9fTV91dWlFamRyNjFtIn0.qyM57dh7FUI5zc5bTEyBh43eVLsNy8uamEDVXdwv-Bc",
            "ValidUntil": 1659449144
          }
        }
        """
        let data = Data(json.utf8)
        return try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
    }
}
