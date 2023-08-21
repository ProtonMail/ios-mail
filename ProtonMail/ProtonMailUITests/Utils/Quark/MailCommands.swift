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
import RegexBuilder
import XCTest

private let qaFixturesLoad = "raw::qa:fixtures:load"
private let doctrineFixturesLoad = "raw::doctrine:fixtures:load"
private let makeDelinquent = "payments:make-delinquent"
private let createSeedSubscriber = "payments:seed-subscriber"

extension Quark {
    
    enum DelinquentState: Int {
        case paid = 0
        /// unpaid invoice available for 7 days or less
        case availableLessThan7Days
        /// unpaid invoice with payment overdue for more than 7 days
        case overdueMoreThan7Days
        /// unpaid invoice with payment overdue for more than 14 days, the user is considered Delinquent
        case overdueMoreThan14Days
        /// unpaid invoice with payment not received for more than 30 days, the user is considered Delinquent
        case overdueMoreThan30Days
    }

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
    
    func createSeedSubscribeUser(username: String, password: String, state: DelinquentState) throws -> User {
        let args = [
            "username=\(username)&password=\(password)&state=\(state)"
        ]
        
        let request = try route(createSeedSubscriber)
            .args(args)
            .build()
        
        do {
            let (textData, urlResponse) = try executeQuarkRequest(request)
            let jsonData = try? makeQuarkCommandTextToJson(data: textData)
            guard let responseHTML = String(data: textData, encoding: .utf8) else {
                throw QuarkError(urlResponse: urlResponse, message: "Update delinquent state failed")
            }
            
            var createdUser = User()
            createdUser.name = username
            createdUser.password = password
            let idRef = Reference(Int.self)
            let regex = Regex {
                "User `\(username)` (ID "
                
                TryCapture(as: idRef) {
                    OneOrMore(.digit)
                } transform: { match in
                    Int(match)
                }
            }
            if let result = responseHTML.firstMatch(of: regex) {
                let id = result[idRef]
                createdUser.id = id
            } else {
                throw NSError(domain: "proton.test", code: -1)
            }
            return createdUser
        } catch {
            throw error
        }
    }
    
    func updateDelinquentState(state: DelinquentState, for username: String) throws {
        let args = [
            "username=\(username)&&--delinquentState=\(state.rawValue)"
        ]
        
        let request = try route(makeDelinquent)
            .args(args)
            .build()
        
        do {
            let (textData, urlResponse) = try executeQuarkRequest(request)
            guard
                let responseHTML = String(data: textData, encoding: .utf8),
                responseHTML.contains("Done")
            else {
                throw QuarkError(urlResponse: urlResponse, message: "Update delinquent state failed")
            }
        } catch {
            throw error
        }
    }
}
