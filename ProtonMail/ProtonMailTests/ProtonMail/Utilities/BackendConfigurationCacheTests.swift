// Copyright (c) 2023 Proton Technologies AG
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

@testable import ProtonMail
import ProtonCore_Environment
import XCTest

class BackendConfigurationCacheTests: XCTestCase {
    private var sut: BackendConfigurationCache!
    private var mockUserDefaults: UserDefaults!
    private let customDomain = "example.com"

    override func setUp() {
        super.setUp()
        mockUserDefaults = UserDefaults(suiteName: #fileID)
        sut = BackendConfigurationCache(userDefaults: mockUserDefaults)
    }

    override func tearDown() {
        super.tearDown()
        mockUserDefaults.removePersistentDomain(forName: #fileID)
        mockUserDefaults = nil
        sut = nil
    }

    func testReadEnvironment_whenNoDataInUserDefaults_returnNil() {
        XCTAssert(sut.readEnvironment() == nil)
    }

    func testReadEnvironment_whenDeclaredEnvInUserDefults_returnsTheEnv() {
        mockUserDefaults.set("black", forKey: "environment")
        XCTAssert(sut.readEnvironment() == .black)
    }

    func testReadEnvironment_whenCustomEnvInUserDefults_returnsThCustomEnv() {
        mockUserDefaults.set("custom", forKey: "environment")
        mockUserDefaults.set(customDomain, forKey: "environmentCustomDomain")
        XCTAssert(sut.readEnvironment() == .custom(customDomain))
    }

    func testReadEnvironment_whenCustomEnvInUserDefults_butNoCustomDomain_returnsNil() {
        mockUserDefaults.set("custom", forKey: "environment")
        XCTAssert(sut.readEnvironment() == nil)
    }

    func testWriteEnvironment_whenDeclaredEnvIsUsed_writesInUserDefaults() {
        sut.write(environment: .black)
        XCTAssert(mockUserDefaults.string(forKey: "environment") == "black")
    }

    func testWriteEnvironment_whenCustomEnvIsUsed_writesInUserDefaults() {
        sut.write(environment: .custom(customDomain))
        XCTAssert(mockUserDefaults.string(forKey: "environment") == "custom")
        XCTAssert(mockUserDefaults.string(forKey: "environmentCustomDomain") == customDomain)
    }
}
