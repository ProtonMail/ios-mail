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

import Testing
import UIKit

@testable import ProtonMail

@MainActor
final class PassThroughWindowTests {

    private let sut: PassThroughWindow

    init() {
        sut = .init(frame: UIScreen.main.bounds)
        sut.rootViewController = UIViewController()
        sut.makeKeyAndVisible()
    }

    @Test
    func testHitTest_WhenHitViewIsRootViewControllerView_ReturnsNil() throws {
        let rootController = try #require(sut.rootViewController)

        let hitView = sut.hitTest(rootController.view.center, with: nil)

        #expect(hitView == nil)
    }

    @Test
    func testHitTest_WhenHitViewIsOutOfBoundsOfRootViewControllerView_ReturnsNil() throws {
        let rootController = try #require(sut.rootViewController)

        let subview = UIView(frame: .init(x: 50, y: 50, width: 100, height: 100))
        rootController.view.addSubview(subview)
        rootController.view.layoutIfNeeded()

        let hitView = sut.hitTest(.init(x: 0, y: 1000), with: nil)

        #expect(hitView == nil)
    }

    @Test
    func testHitTest_WhenHitViewIsNotRootViewControllerView_ReturnsHitView() throws {
        let rootController = try #require(sut.rootViewController)

        let subview = UIView(frame: .init(x: 50, y: 50, width: 100, height: 100))
        rootController.view.addSubview(subview)
        rootController.view.layoutIfNeeded()

        let hitView = sut.hitTest(CGPoint(x: 100, y: 100), with: nil)

        #expect(hitView == subview)
    }

}
