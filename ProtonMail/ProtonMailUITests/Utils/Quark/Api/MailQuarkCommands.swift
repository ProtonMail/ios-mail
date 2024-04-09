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

import ProtonCoreQuarkCommands

private let qaFixturesLoad = "quark/raw::qa:fixtures:load"
private let doctrineFixturesLoad = "quark/raw::doctrine:fixtures:load"

public extension Quark {

    func createUserWithiOSFixturesLoad(name: String) throws -> [User]  {

        var userList = [User]()
        let definitionPath = "nexus://Mail/ios/ios.\(name)"
        let outputFormat = "json"

        let args = [
            "definition-paths[]=\(definitionPath)",
            "--source[]=nexus:nexus:https://nexus.protontech.ch?repository=TestData",
            "--output-format=\(outputFormat)"
        ]

        let request = try route(qaFixturesLoad)
            .args(args)
            .build()

        let (data, _) = try executeQuarkRequest(request)

        let usersResponse = try parseQuarkCommandJsonResponse(jsonData: data, type: MailQuarkiOSResponse.self)

        if let users = usersResponse?.users {
            for quarkUser in users {
                let user = User(from: quarkUser)
                userList.append(user)
            }
        }

        return userList
    }


    func createUserWithFixturesLoad(name: String) throws -> User {

        let args = [
            "--append=1",
            "--group[]=\(name)"
        ]

        let request = try route(doctrineFixturesLoad)
            .args(args)
            .build()

        let (textData, _) = try executeQuarkRequest(request)
        let userData = try makeQuarkCommandTextToJson(data: textData)

        let quarkResponse = try parseQuarkCommandJsonResponse(jsonData: userData!, type: MailWebFixtureQuarkResponse.self)

        return User(from: quarkResponse!)
    }
}
