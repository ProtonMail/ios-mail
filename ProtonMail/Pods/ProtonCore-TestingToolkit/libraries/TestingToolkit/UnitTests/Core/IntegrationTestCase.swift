//
//  IntegrationTestCase.swift
//  ProtonCore-TestingToolkit - Created on 11/04/2023.
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import XCTest

open class IntegrationTestCase: XCTestCase {

    open var testBundle: Bundle? { nil }

    public var dynamicDomain: String? {
        #if SPM
        let domain = ProcessInfo().environment["DYNAMIC_DOMAIN"]
        #else
        let domain = testBundle?.object(forInfoDictionaryKey: "DYNAMIC_DOMAIN") as? String
        #endif
        return domain.flatMap { dynamicDomain in
            guard !dynamicDomain.isEmpty else { return nil }
            return dynamicDomain
        }
                                               }

    public var dynamicDomainAvailable: Bool { dynamicDomain != nil }

    open var host: String? { dynamicDomain.map { "https://\($0)" } }

    private func randomAlphanumericString(length: Int = 10) -> String {
        let allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return  randomString(allowedChars, length: length)
    }

    private func randomString(_ allowedChars: String, length: Int) -> String {
        return String((0..<length).map { _ in allowedChars.randomElement()! })
    }

    public var randomName: String {
        randomAlphanumericString(length: 12)
    }

    public var randomPassword: String {
        randomAlphanumericString(length: 8)
    }

    public var randomEmail: String {
        let username = randomAlphanumericString(length: 12)
        return "\(username)@proton.uitests"
    }
}
