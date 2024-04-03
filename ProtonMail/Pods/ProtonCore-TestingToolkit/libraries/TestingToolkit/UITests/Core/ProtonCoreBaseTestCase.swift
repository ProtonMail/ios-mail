//
//  ProtonCoreBaseTestCase.swift
//  ProtonCore-TestingToolkit-UITests-Core - Created on 18.10.21.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

#if canImport(fusion)

import fusion
import XCTest
import ProtonCoreLog

open class ProtonCoreBaseTestCase: CoreTestCase {

    public let app = XCUIApplication()
    public var bundleIdentifier: String = "ch.protontech.core.ios.testing-toolkit.uitests"
    public var launchArguments: [String] = []
    public var launchEnvironment: [String: String] = [:]

    public var uiTestBundle: Bundle? {
        Bundle.allBundles.first(where: { $0.bundleIdentifier == bundleIdentifier })
    }

    public var dynamicDomain: String? {
        uiTestBundle?.object(forInfoDictionaryKey: "DYNAMIC_DOMAIN").flatMap { domain in
            guard let dynamicDomain = domain as? String, !dynamicDomain.isEmpty
            else { return nil }
            return dynamicDomain
        }
    }

    public var dynamicDomainAvailable: Bool { dynamicDomain != nil }

    open var host: String? { dynamicDomain.map { "https://\($0)" } }

    public func beforeSetUp(bundleIdentifier: String? = nil,
                            launchArguments: [String]? = nil,
                            launchEnvironment: [String: String]? = nil) {
        self.bundleIdentifier = bundleIdentifier ?? self.bundleIdentifier
        self.launchArguments = launchArguments ?? self.launchArguments
        self.launchEnvironment = launchEnvironment ?? self.launchEnvironment
    }

    override open func setUp() {
        super.setUp()
        PMLog.info("UI TEST START")
        launchArguments.append("RunningInUITests")
        launchEnvironment["UITestsLogsDirectory"] = PMLog.logsDirectory!.absoluteString
        if let dynamicDomain = dynamicDomain {
            launchEnvironment["DYNAMIC_DOMAIN"] = dynamicDomain
        }
        app.launchArguments = launchArguments
        app.launchEnvironment = launchEnvironment
        app.launch()
    }

    override open func tearDown() {
        super.tearDown()
        guard let log = PMLog.logFile else { return }
        PMLog.info("UI TEST ENDED")
        let logsAttachment = XCTAttachment(contentsOfFile: log)
        logsAttachment.lifetime = .keepAlways
        add(logsAttachment)
        try? FileManager.default.removeItem(at: log)
    }
}

public extension ProtonCoreBaseTestCase {
    var randomName: String {
        StringUtils.randomAlphanumericString(length: 8)
    }

    var randomPassword: String {
        StringUtils.randomAlphanumericString(length: 8)
    }

    var randomEmail: String {
        let username = StringUtils.randomAlphanumericString(length: 8)
        // Randomly generated domain doesn't pass login form email validation.
        let domain = "example"
        let tld = "com"
        return "\(username)@\(domain).\(tld)"
    }
}

#endif
