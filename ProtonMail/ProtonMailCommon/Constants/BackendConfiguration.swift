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

protocol BackendEnvironment {
    var appDomain: String { get }
    var apiDomain: String { get }
    var apiPath: String { get }
}

struct ProductionEnvironment: BackendEnvironment {
    let appDomain = "protonmail.com"
    let apiDomain = "api.protonmail.ch"
    let apiPath = ""
}

struct AtlasEnvironment: BackendEnvironment {
    let appDomain = "proton.black"
    let apiDomain = "proton.black"
    let apiPath = "/api"
}

struct CustomEnvironment: BackendEnvironment {
    private static let API_DOMAIN_KEY = "MAIL_APP_API_DOMAIN"
    private static let API_PATH_KEY = "MAIL_APP_API_PATH"

    let appDomain = "protonmail.com"
    let apiDomain: String
    let apiPath: String

    init(environmentVariables: [String: String]) {
        guard
            let domain = CustomEnvironment.getValue(from: environmentVariables, key: CustomEnvironment.API_DOMAIN_KEY),
            let path = CustomEnvironment.getValue(from: environmentVariables, key: CustomEnvironment.API_PATH_KEY)
        else {
            let fallback = ProductionEnvironment()
            self.apiDomain = fallback.apiDomain
            self.apiPath = fallback.apiPath
            SystemLogger.log(message: "fallback to production env", category: .tests, isError: true)
            return
        }
        self.apiDomain = domain
        self.apiPath = path
    }

    private static func getValue(from envVariables: [String: String], key: String) -> String? {
        guard let value = envVariables[key] else {
            SystemLogger.log(
                message: "\(key) env variable not found",
                category: .tests,
                isError: true
            )
            return nil
        }
        return value
    }
}

struct BackendConfiguration {
    static let shared = BackendConfiguration()

    enum Arguments {
        static let UITests = "-uiTests"
    }

    private let launchArguments: [String]
    private let environmentVariables: [String: String]

    private(set) var environment: BackendEnvironment

    init(
        launchArguments: [String] = ProcessInfo.processInfo.arguments,
        environmentVariables: [String: String] = ProcessInfo.processInfo.environment
    ) {
        self.launchArguments = launchArguments
        self.environmentVariables = environmentVariables

        if launchArguments.contains(Arguments.UITests) {
            self.environment = CustomEnvironment(environmentVariables: environmentVariables)
            let message = "Custom api configuration - domain: \(environment.apiDomain), path: \(environment.apiPath)"
            SystemLogger.log(message: message, category: .appLifeCycle)
        } else {

            // Production Environment
            self.environment = ProductionEnvironment()
        }
    }
}
