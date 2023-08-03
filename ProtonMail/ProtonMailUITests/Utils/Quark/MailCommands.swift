// Copyright (c) 2023. Proton Technologies AG
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
import XCTest

private let qaFixturesLoad = "raw::qa:fixtures:load"
private let doctrineFixturesLoad = "raw::doctrine:fixtures:load"

extension Quark {

    func createUserWithiOSFixturesLoad(name: String) throws ->  MailQuarkResponse? {

        let definitionPath = "api://apps/Mail/resources/qa/ios/\(name)"
        let outputFormat = "json"

        let args = [
            "definition-paths[]=\(definitionPath)",
            "--output-format=\(outputFormat)"
        ]

        let request = try route(qaFixturesLoad)
            .args(args)
            .build()

        let (data, _) = try executeQuarkRequest(request)

        return try parseQuarkCommandJsonResponse(jsonData: data, type: MailQuarkResponse.self)
    }


    func createUserWithFixturesLoad(name: String) throws -> MailWebFixtureQuarkResponse? {

        let args = [
            "--append=1&--group[]=\(name)",
        ]

        let request = try route(doctrineFixturesLoad)
            .args(args)
            .build()


        do {
            let (textData, urlResposne) = try executeQuarkRequest(request)
            guard let jsonData = try? makeQuarkCommandTextToJson(data: textData) else {
                throw QuarkError(urlResponse: urlResposne, message: "Failed to convert text data to JSON.")
            }

            guard let response = try? parseQuarkCommandJsonResponse(jsonData: jsonData, type: MailWebFixtureQuarkResponse.self) else {
                throw QuarkError(urlResponse: urlResposne, message: "Failed to parse JSON response.")
            }

            return response
        } catch {
            throw error
        }
    }
}
