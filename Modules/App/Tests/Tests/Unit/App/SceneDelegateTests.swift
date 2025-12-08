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

import InboxCoreUI
import InboxTesting
import ProtonUIFoundations
import SwiftUI
import XCTest

@testable import ProtonMail

@MainActor
final class SceneDelegateTests: BaseTestCase {
    private var sut: SceneDelegate!
    var mailSessionSpy: MailSessionSpy!
    var shouldAutoLockStub: Bool = true

    override func setUp() async throws {
        try await super.setUp()

        sut = .init()
        mailSessionSpy = .init()
        sut.appProtectionStore = .init(mailSession: { self.mailSessionSpy })
        sut.mailSessionFactory = { .init(noPointer: .init()) }
        sut.checkAutoLockSetting = { completion in completion(self.shouldAutoLockStub) }
        sut.transitionAnimation = { _, _, _, animation, completion in
            animation?()
            completion?(true)
        }
    }

    override func tearDown() async throws {
        sut = nil
        mailSessionSpy = nil

        try await super.tearDown()
    }

    func testWindowScene_WhenConnectingToSceneSession_ConfiguresWindowSceneCorrectly() throws {
        let scene = try scene()

        sut.scene(scene, willConnectTo: scene.session, options: try connectionOptions())

        XCTAssert(sut.windowScene === scene)
    }

    func testOverlayWindow_WhenSetToastStateStore_IsConfiguredCorrectly() throws {
        let scene = try scene()

        sut.scene(scene, willConnectTo: scene.session, options: try connectionOptions())
        sut.toastStateStore = ToastStateStore(initialState: .initial)

        let overlayWindow = try XCTUnwrap(sut.overlayWindow)

        XCTAssert(overlayWindow is PassThroughWindow)
        XCTAssert(overlayWindow.rootViewController is UIHostingController<ModifiedContent<ToastSceneView, _EnvironmentKeyWritingModifier<Optional<ToastStateStore>>>>)
        XCTAssertEqual(overlayWindow.rootViewController?.view.backgroundColor, .clear)
        XCTAssertFalse(overlayWindow.isHidden)
    }

    func testWindowScene_WhenAppProtectionIsSet_WhenUserEntersForegroundTwoTimes_ItUnlockAndLockTheApp() throws {
        mailSessionSpy.appProtectionStub = .biometrics
        shouldAutoLockStub = true

        let scene = try scene()

        sut.scene(scene, willConnectTo: scene.session, options: try connectionOptions())
        sut.sceneWillEnterForeground(scene)

        let appProtectionWindow = try XCTUnwrap(sut.appProtectionWindow)

        XCTAssertFalse(appProtectionWindow.isHidden)
        XCTAssertNotNil(appProtectionWindow.rootViewController)

        sut.appProtectionStore.dismissLock()

        XCTAssertTrue(appProtectionWindow.isHidden)
        XCTAssertNil(appProtectionWindow.rootViewController)

        sut.sceneWillEnterForeground(scene)

        XCTAssertFalse(appProtectionWindow.isHidden)
        XCTAssertNotNil(appProtectionWindow.rootViewController)
    }

    func testWindowScene_WhenUserEntersBackground_ItCoversAppContent() throws {
        let scene = try scene()

        sut.scene(scene, willConnectTo: scene.session, options: try connectionOptions())
        sut.sceneWillEnterForeground(scene)
        sut.sceneDidEnterBackground(scene)

        let appProtectionWindow = try XCTUnwrap(sut.appProtectionWindow)

        XCTAssertFalse(appProtectionWindow.isHidden)
        XCTAssertNotNil(appProtectionWindow.rootViewController)
        XCTAssert(appProtectionWindow.rootViewController is UIHostingController<BlurredCoverView>)
    }

    // MARK: - Private

    private func scene() throws -> UIWindowScene {
        let session = try InstanceHelper.create(UISceneSession.self)
        let scene = try InstanceHelper.create(
            UIWindowScene.self,
            properties: [
                "session": session
            ])
        return scene
    }

    private func connectionOptions() throws -> UIScene.ConnectionOptions {
        try InstanceHelper.create(UIScene.ConnectionOptions.self)
    }
}
