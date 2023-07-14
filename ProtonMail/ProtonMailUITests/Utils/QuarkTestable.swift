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
import os.log
import ProtonCore_QuarkCommands
import RegexBuilder
import XCTest

struct QuarkError: Error, LocalizedError {
    let url: URL
    let message: String
    
    var errorDescription: String? {
        """
        url: \(url.absoluteString)
        message: \(message)
        """
    }
}

final class UITest: LogObject {
    static var osLog: OSLog = OSLog(subsystem: "UITests", category: "Quark")
}

@available(iOS 16.0, *)
protocol QuarkTestable {
}


@available(iOS 16.0, *)
extension QuarkTestable where Self: XCTestCase {
    
    private func record(_ attachement: XCTAttachment) {
        self.add(attachement)
    }
    
    func createUserWithiOSFixturesLoad(domain: String, plan: UserPlan, scenario: MailScenario, isEnableEarlyAccess: Bool) throws -> User {
        
        let request = try URLRequest(domain: domain, quark: "raw::qa:fixtures:load?definition-paths[]=api://apps/Mail/resources/qa/ios/\(scenario.name)&--output-format=json", timeoutWorkaround: true)
        
        ConsoleLogger.shared?.log("🕸 URL: \(request.url!)", osLogType: UITest.self)
        
        let createData = try performRequest(with: request)
        
        guard let response = String(data: createData, encoding: .utf8) else {
            throw QuarkError(url: request.url!, message: "Failed parse response 👼")
        }
        
        ConsoleLogger.shared?.log("\n🚧🚧🚧🚧🚧🚧🚧🚧🚧🚧\n\(NSString(string: response))🚧🚧🚧🚧🚧🚧🚧🚧🚧🚧", osLogType: UITest.self)
        
        let html = XCTAttachment(data: createData, uniformTypeIdentifier: "public.json")
        html.name = "Quark user creation json response"
        // Keep the HTML attachment even when the test succeeds.
        html.lifetime = .keepAlways
        record(html)
        
        let jsonData = Data(response.utf8)
        
        let usersResponse = try JSONDecoder().decode(QuarkUserResponse.self, from: jsonData)
        let currentUser = usersResponse.users.first!
        
        let user = User(id: currentUser.ID.raw, name: currentUser.name, email: "\(currentUser.name)@\(dynamicDomain)", password: currentUser.password, userPlan: plan, mailboxPassword: "", twoFASecurityKey: "", twoFARecoveryCodes: [""], numberOfImportedMails: 0, quarkURL: request.url!)
        
        plan != UserPlan.free ? try enableSubscription(for: user, domain: domain, plan: plan.rawValue) : ()
        isEnableEarlyAccess ? try enableEarlyAccess(for: user, domain: domain) : ()
        
        return user
    }
    
    func createUserWithFixturesLoad(domain: String, plan: UserPlan, scenario: MailScenario, isEnableEarlyAccess: Bool) throws -> User {
        let request = try URLRequest(domain: domain, quark: "doctrine:fixtures:load?--append=1&--group[]=\(scenario.name)")
        
        ConsoleLogger.shared?.log("🕸 URL: \(request.url!)", osLogType: UITest.self)
        
        let createData = try performRequest(with: request)
        
        guard let htmlResponse = String(data: createData, encoding: .utf8) else {
            throw QuarkError(url: request.url!, message: "Failed parse response 👼")
        }
        
        ConsoleLogger.shared?.log("\n🚧🚧🚧🚧🚧🚧🚧🚧🚧🚧\n\(NSString(string: htmlResponse))🚧🚧🚧🚧🚧🚧🚧🚧🚧🚧", osLogType: UITest.self)
        
        let html = XCTAttachment(data: createData, uniformTypeIdentifier: "public.html")
        html.name = "Quark user creation HTML response"
        // Keep the HTML attachment even when the test succeeds.
        html.lifetime = .keepAlways
        record(html)
        
        
        var id = 0 // Declare id outside the if statement with a default value
        
        let idRegex = Regex {
            "ID (decrypt): "
            TryCapture {
                OneOrMore(.digit)
            } transform: { match in
                Int(match)
            }
        }
        
        if let match = htmlResponse.firstMatch(of: idRegex) {
            id = match.1
        } else {
            throw QuarkError(url: request.url!, message: "Failed creation of user 👼")
        }
        
        var name = ""
        
        let nameRegex = Regex {
            "Name: "
            Capture {
                OneOrMore(.anyNonNewline)
            } transform: { match in
                String(match)
            }
        }
        
        if let match = htmlResponse.firstMatch(of: nameRegex) {
            name = match.1
        } else {
            throw QuarkError(url: request.url!, message: "Failed creation of user 👼")
        }
        
        var email = ""
        
        let emailRegex = Regex {
            "Email: "
            TryCapture {
                OneOrMore(.anyNonNewline)
            } transform: { match in
                String(match)
            }
        }
        
        if let match = htmlResponse.firstMatch(of: emailRegex) {
            email = match.1
        } else {
            throw QuarkError(url: request.url!, message: "Failed creation of user 👼")
        }
        
        var password = ""
        
        let passwordRegex = Regex {
            "Password: "
            TryCapture {
                OneOrMore(.anyNonNewline)
            } transform: { match in
                String(match)
            }
        }
        
        if let match = htmlResponse.firstMatch(of: passwordRegex) {
            password = match.1
        } else {
            throw QuarkError(url: request.url!, message: "Failed creation of user 👼")
        }
        
        var numberOfImportedMails = 0
        
        let numberOfImportedMailsRegex = /Number of emails imported from[^:]*([0-9]+)/
        
        if let match = htmlResponse.firstMatch(of: numberOfImportedMailsRegex) {
            numberOfImportedMails = Int(match.1)!
        } else {
            throw QuarkError(url: request.url!, message: "Failed creation of user 👼")
        }
        
        let user = User(id: id, name: name, email: email, password: password, userPlan: plan, mailboxPassword: "", twoFASecurityKey: "", twoFARecoveryCodes: [""], numberOfImportedMails: numberOfImportedMails, quarkURL: request.url!)
        
        plan != UserPlan.free ? try enableSubscription(for: user, domain: domain, plan: plan.rawValue) : ()
        isEnableEarlyAccess ? try enableEarlyAccess(for: user, domain: domain) : ()
        
        return user
    }
    
    func deleteUser(domain: String, _ user: User?) throws {
        guard let user = user else { throw NSError(domain: "User does no exist 👻", code: 0) }
        let request = try URLRequest(domain: domain, quark: "user:delete?-u=\(user.id!)&-s")
        try performRequest(with: request)
        ConsoleLogger.shared?.log("🪦 \(user.name) deleted", osLogType: UITest.self)
    }
    
    private func enableSubscription(for user: User, domain: String, plan: String) throws {
        let request = try URLRequest(domain: domain, quark: "user:create:subscription?userID=\(user.id!)&--planID=\(plan)")
        try performRequest(with: request)
        ConsoleLogger.shared?.log("💸🧾 \(user.name) enabled subscription", osLogType: UITest.self)
    }
    
    private func enableEarlyAccess(for user: User, domain: String) throws {
        let request = try URLRequest(domain: domain, quark: "core:user:settings:update?--user=\(user.name)&--EarlyAccess=1")
        try performRequest(with: request)
        ConsoleLogger.shared?.log("💸👶 \(user.name) enabled early access", osLogType: UITest.self)
    }
    
    @discardableResult
    private func performRequest(with request: URLRequest) throws -> Data {
        var responseData: Data?
        var response: URLResponse?
        var responseError: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: request) { (data, urlResponse, error) in
            if let error = error {
                responseError = error
            } else {
                responseData = data
                response = urlResponse
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        
        if let error = responseError {
            throw error
        }
        
        guard let data = responseData else {
            throw QuarkError(url: request.url!, message: "Failed to create user 👼")
        }
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard statusCode == 200 else {
            throw QuarkError(url: request.url!, message: "Failed creation of user: \(name) 🌐, code: \(statusCode)")
        }
        
        return data
    }
}

// MARK: - Helpers
private extension URLRequest {
    typealias Endpoint = String

    init(domain: String, quark: Endpoint, timeoutWorkaround: Bool = false) throws {
        var urlString: String

        if timeoutWorkaround {
            urlString = "https://\(domain)/internal-api/quark/\(quark)"
        } else {
            urlString = "https://\(domain)/api/internal/quark/\(quark)"
        }

        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Could not generate proper URL, domain: \(urlString)", code: 10)
        }
        self.init(url: url)
    }
}
