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
@testable import ProtonMail

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
extension QuarkCommands {

    func createUserWithFixturesLoad(dynamicDomain: String, plan: UserPlan, scenario: MailScenario, isEnableEarlyAccess: Bool = false) async throws -> User {
        let request = try URLRequest(domain: dynamicDomain, quark: "doctrine:fixtures:load?--append=1&--group[]=\(scenario.name)")


        ConsoleLogger.shared?.log("🕸 URL: \(request.url!)", osLogType: UITest.self)

        let (createData, response) = try await URLSession.shared.data(for: request)

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw QuarkError(url: request.url!, message: "Failed doctrine fixtures Load 🐣🐣🐣🐣🐣🐣🐣")
        }

        guard let htmlResponse = String(data: createData, encoding: .utf8) else {
            throw QuarkError(url: request.url!, message: "Failed parse response 👼")
        }

        ConsoleLogger.shared?.log("\n🚧🚧🚧🚧🚧🚧🚧🚧🚧🚧\n\(NSString(string: htmlResponse))🚧🚧🚧🚧🚧🚧🚧🚧🚧🚧", osLogType: UITest.self)


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

        let numberOfImportedMailsRegex = Regex {
            "Number of emails imported: "
            TryCapture {
                OneOrMore(.digit)
            } transform: { match in
                Int(match)
            }
        }

        if let match = htmlResponse.firstMatch(of: numberOfImportedMailsRegex) {
            numberOfImportedMails = match.1
        } else {
            throw QuarkError(url: request.url!, message: "Failed creation of user 👼")
        }


        let user = User(id: id, name: name, email: email, password: password, userPlan: UserPlan.free, mailboxPassword: "", twoFASecurityKey: "", twoFARecoveryCodes: [""], numberOfImportedMails: numberOfImportedMails, quarkURL: request.url!)

        async let subscription: Void = plan != UserPlan.free ? enableSubscription(for: user, domain: dynamicDomain, plan: plan.rawValue) : ()
        async let earlyAccess: Void = isEnableEarlyAccess ? enableEarlyAccess(for: user, domain: dynamicDomain) : ()

        let _ = await [try subscription, try earlyAccess]

        return user
    }

    private func enableSubscription(for user: User, domain: String, plan: String) async throws {
        let request = try URLRequest(domain: domain, quark: "user:create:subscription?userID=\(String(describing: user.id))&--planID=\(plan)")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw QuarkError(url: request.url!, message: "❌💸🧾 Failed enabling subscription to user: \(user.name)")
        }
        ConsoleLogger.shared?.log("💸🧾 \(user.name) enabled subscription", osLogType: UITest.self)
    }

    private func enableEarlyAccess(for user: User, domain: String) async throws {
        let request = try URLRequest(domain: domain, quark: "core:user:settings:update?--user=\(user.name)&--EarlyAccess=1")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw QuarkError(url: request.url!, message: "❌💸👶 Failed enabling early access to user: \(user.name)")
        }
        ConsoleLogger.shared?.log("💸👶 \(user.name) enabled early access", osLogType: UITest.self)
    }
}

// MARK: - Helpers
private extension URLRequest {
    typealias Endpoint = String

    init(domain: String, quark: Endpoint) throws {
        guard let url = URL(string: "https://\(domain)/api/internal/quark/\(quark)") else {
            throw NSError(domain: "Could not generate proper URL, domain: https://\(domain)/api/internal/quark/\(quark)", code: 10)
        }
        self.init(url: url)
    }
}
