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
import InboxCoreUI
import InboxTesting
import Nimble
import SwiftUI
import XCTest

final class SceneDelegateTests: BaseTestCase {

    private var sut: SceneDelegate!

    override func setUp() {
        super.setUp()
        sut = .init()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testWindowScene_WhenConnectingToSceneSession_ConfiguresWindowSceneCorrectly() throws {
        let scene = try scene()

        sut.scene(scene, willConnectTo: scene.session, options: try connectionOptions())

        expect(self.sut.windowScene) === scene
    }

    func testOverlayWindow_WhenSetToastStateStore_IsConfiguredCorrectly() throws {
        let scene = try scene()

        sut.scene(scene, willConnectTo: scene.session, options: try connectionOptions())
        sut.toastStateStore = ToastStateStore(initialState: .initial)

        let overlayWindow = try XCTUnwrap(sut.overlayWindow)

        expect(overlayWindow).to(beAKindOf(PassThroughWindow.self))
        expect(overlayWindow.rootViewController).to(beAKindOf(
            UIHostingController<ModifiedContent<ToastSceneView, _EnvironmentKeyWritingModifier<Optional<ToastStateStore>>>>.self
        ))
        expect(overlayWindow.rootViewController?.view.backgroundColor) == .clear
        expect(overlayWindow.isHidden) == false
    }

    // MARK: - Private

    private func scene() throws -> UIWindowScene {
        let session = try InstanceHelper.create(UISceneSession.self)
        let scene = try InstanceHelper.create(UIWindowScene.self, properties: [
            "session": session
        ])
        return scene
    }

    private func connectionOptions() throws -> UIScene.ConnectionOptions {
        try InstanceHelper.create(UIScene.ConnectionOptions.self)
    }

}
