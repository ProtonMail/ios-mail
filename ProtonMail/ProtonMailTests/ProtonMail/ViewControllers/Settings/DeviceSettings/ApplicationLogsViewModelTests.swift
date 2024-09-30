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

import Combine
@testable import ProtonMail
import XCTest

final class ApplicationLogsViewModelTests: XCTestCase {
    private var sut: ApplicationLogsViewModel!
    private var fileManager: FileManager!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        fileManager = FileManager()
        sut = ApplicationLogsViewModel(dependencies: .init(fileManager: fileManager))
        cancellables = []
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        fileManager = nil
        cancellables = nil
    }

    /// This test assumes the app will write at least one log message when launched
    func testInput_viewWillAppear_itShouldPublishLogsContent() throws {
        let expectation = expectation(description: "Awaiting value")
        sut.output.content.first().sink { contentValue in
            XCTAssertNotNil(contentValue)
            expectation.fulfill()
        }.store(in: &cancellables)
        sut.viewDidAppear()
        wait(for: [expectation], timeout: 2.0)
    }

    func testInput_didTapShare_itShouldPublishTheFileToExport() throws {
        let expectation = expectation(description: "Awaiting value")
        sut.output.fileToShare.sink { url in
            XCTAssertEqual(url.lastPathComponent, "proton-mail-debug.log")
            expectation.fulfill()
        }.store(in: &cancellables)
        sut.didTapShare()
        wait(for: [expectation], timeout: 2.0)
    }
}
