// Copyright (c) 2024 Proton Technologies AG
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
import NIO
import XCTest

public class PMUITestCase: XCTestCase {
    var mockServer: MockServer!
    private var mockServerSocketAddress: SocketAddress!

    public override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override public func setUp() {
        mockServer = MockServer(bundle: Bundle(for: type(of: self)))
        mockServerSocketAddress = mockServer.start()
    }

    override public func tearDown() {
        mockServer.stop()
    }

    @MainActor
    func launchApp() {
        let app = XCUIApplication()

        if let serverPort = mockServerSocketAddress?.port {
            app.launchArguments += ["-mockServerPort", "\(serverPort)"]
        }
        else {
            print("No mock server running, skipping custom launch arguments.")
        }

        app.launch()
    }
}
