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

@testable import ProtonMail
import XCTest

final class PassThroughWindowTests: XCTestCase {

    var sut: PassThroughWindow!

    override func setUp() {
        super.setUp()
        sut = .init(frame: UIScreen.main.bounds)
        sut.rootViewController = UIViewController()
        sut.makeKeyAndVisible()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testHitTest_WhenHitViewIsRootViewControllerView_ReturnsNil() throws {
        let rootController = try XCTUnwrap(sut.rootViewController)

        let hitView = sut.hitTest(rootController.view.center, with: nil)

        XCTAssertNil(hitView)
    }

    func testHitTest_WhenHitViewIsOutOfBoundsOfRootViewControllerView_ReturnsNil() throws {
        let rootController = try XCTUnwrap(sut.rootViewController)

        let subview = UIView(frame: .init(x: 50, y: 50, width: 100, height: 100))
        rootController.view.addSubview(subview)
        rootController.view.layoutIfNeeded()

        let hitView = sut.hitTest(.init(x: 0, y: 1000), with: nil)

        XCTAssertNil(hitView)
    }

    func testHitTest_WhenHitViewIsNotRootViewControllerView_ReturnsHitView() throws {
        let rootController = try XCTUnwrap(sut.rootViewController)

        let subview = UIView(frame: .init(x: 50, y: 50, width: 100, height: 100))
        rootController.view.addSubview(subview)
        rootController.view.layoutIfNeeded()

        let hitView = sut.hitTest(CGPoint(x: 100, y: 100), with: nil)

        XCTAssertEqual(hitView, subview)
    }

}
