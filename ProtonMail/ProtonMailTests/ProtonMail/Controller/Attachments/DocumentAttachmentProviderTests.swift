// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import PromiseKit
import XCTest

@testable import ProtonMail

class DocumentAttachmentProviderTests: XCTestCase {
    private var controller: AttachmentControllerStub!
    private var coordinator: FileCoordinationProviderStub!
    private var testDataURL: URL!
    private var sut: DocumentAttachmentProvider!

    override func setUpWithError() throws {
        try super.setUpWithError()

        controller = AttachmentControllerStub()

        coordinator = FileCoordinationProviderStub()

        testDataURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.dat")

        sut = DocumentAttachmentProvider(for: controller, coordinator: coordinator)

        try Data("foo".utf8).write(to: testDataURL)
    }

    override func tearDownWithError() throws {
        sut = nil
        controller = nil
        coordinator = nil

        try? FileManager.default.removeItem(at: testDataURL)
        testDataURL = nil

        try super.tearDownWithError()
    }

    func testThrowsErrorIfDataCannotBeReadFromURL() throws {
        let expectation = self.expectation(description: "Should prompt expectation")

        let faultyURL = URL(string: "definitely-not-a-proper-file-url")!

        sut.process(fileAt: faultyURL) {
            XCTAssertEqual(self.controller.errorsReceived.count, 1)
            XCTAssertFalse(self.controller.fileSuccessfullyImportedCalled)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testThrowsErrorIfFileCoordinatorFails() throws {
        let expectation = self.expectation(description: "Should prompt expectation")

        coordinator.stubbedError = NSError(domain: "", code: -1)

        sut.process(fileAt: testDataURL) {
            XCTAssertEqual(self.controller.errorsReceived.count, 1)
            XCTAssertFalse(self.controller.fileSuccessfullyImportedCalled)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testThrowsErrorIfControllerFails() throws {
        let expectation = self.expectation(description: "Should prompt expectation")

        controller.fileSuccessfullyImportedStubbedError = NSError(domain: "", code: -1)

        sut.process(fileAt: testDataURL) {
            XCTAssertEqual(self.controller.errorsReceived.count, 1)
            XCTAssert(self.controller.fileSuccessfullyImportedCalled)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testReportsSuccessToControllerIfDataCanBeRead() throws {
        let expectation = self.expectation(description: "Should prompt expectation")

        sut.process(fileAt: testDataURL) {
            XCTAssertEqual(self.controller.errorsReceived.count, 0)
            XCTAssert(self.controller.fileSuccessfullyImportedCalled)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}

private class AttachmentControllerStub: AttachmentController {
    var fileSuccessfullyImportedStubbedError: NSError?

    private (set) var errorsReceived: [String] = []
    private (set) var fileSuccessfullyImportedCalled = false

    func present(_ controller: UIViewController, animated: Bool, completion: (() -> Void)?) {
        fatalError("not implemented")
    }

    func error(_ description: String) {
        errorsReceived.append(description)
    }

    func error(title: String, description: String) {
        fatalError("not implemented")
    }

    func fileSuccessfullyImported(as fileData: FileData) -> Promise<Void> {
        fileSuccessfullyImportedCalled = true

        if let error = fileSuccessfullyImportedStubbedError {
            return Promise(error: error)
        } else {
            return Promise()
        }
    }

    var barItem: UIBarButtonItem? {
        fatalError("not implemented")
    }
}

private class FileCoordinationProviderStub: FileCoordinationProvider {
    var stubbedError: NSError?

    func coordinate(readingItemAt url: URL, options: NSFileCoordinator.ReadingOptions, error: NSErrorPointer, byAccessor: (URL) -> Void) {
        if let stubbedError = stubbedError {
            error!.pointee = stubbedError
        } else {
            NSFileCoordinator(filePresenter: nil).coordinate(readingItemAt: url, options: options, error: error, byAccessor: byAccessor)
        }
    }
}
