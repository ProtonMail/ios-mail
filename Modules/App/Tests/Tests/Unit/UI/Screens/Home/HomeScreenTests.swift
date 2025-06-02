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
import AccountLogin
import InboxCore
import InboxCoreUI
import InboxKeychain
import InboxTesting
import proton_app_uniffi
import SwiftUI
import ViewInspector
import XCTest

class HomeScreenTests: BaseTestCase {

    private var sut: HomeScreen!
    private var userDefaults: UserDefaults!

    private let appUIStateStore = AppUIStateStore()
    private let toastStateStore = ToastStateStore(initialState: .initial)

    override func setUp() async throws {
        try await super.setUp()
        userDefaults = .clearedTestInstance()
        sut = HomeScreen(
            appContext: .shared,
            userSession: try await .testInstance(),
            toastStateStore: toastStateStore
        )
    }

    override func tearDown() {
        userDefaults = nil
        sut = nil
        super.tearDown()
    }

    // FIXME: Enable and adjust `MailUserSession` creation when Rust fixes following issue: ET-1248
    func x_testLogout_WhenNoDataInUserDefaults_ItCleansUpUserDefaults() throws {
        arrange { inspectSUT in
            let mailboxScreen = try self.mailboxScreenWithEnvironmentObjects(inspectSUT: inspectSUT)
            let sidebarScreen = try self.sidebarScreenWithEnvironmentObjects(inspectSUT: inspectSUT)

            try mailboxScreen.simulateTapOnHamburgerMenu()
            try sidebarScreen.simulateTapOnLogout()

            XCTAssertNil(self.storedValue())
        }
    }

    // FIXME: Enable and adjust `MailUserSession` creation when Rust fixes following issue: ET-1248
    func x_testLogout_WhenThereIsDataInUserDefaults_ItCleansUpUserDefaults() throws {
        store(value: true)

        arrange { inspectSUT in
            let mailboxScreen = try self.mailboxScreenWithEnvironmentObjects(inspectSUT: inspectSUT)
            let sidebarScreen = try self.sidebarScreenWithEnvironmentObjects(inspectSUT: inspectSUT)

            try mailboxScreen.simulateTapOnHamburgerMenu()
            try sidebarScreen.simulateTapOnLogout()

            XCTAssertNil(self.storedValue())
        }
    }

    // MARK: - Private

    private let key = UserDefaultsKey.showAlphaV1Onboarding

    private func store(value: Bool) {
        userDefaults[key] = value
    }

    private func storedValue() -> Any? {
        userDefaults[key]
    }

    private func arrange(
        function: String = #function,
        file: StaticString = #file,
        line: UInt = #line,
        perform: @escaping (InspectableView<ViewType.View<HomeScreen>>) throws -> Void
    ) {
        let expectation = sut.on(
            \.didAppear,
            function: function,
            file: file,
            line: line,
            perform: perform
        )

        ViewHosting.host(
            view:
                sut
                .environmentObject(appUIStateStore)
                .environmentObject(toastStateStore)
        )

        wait(for: [expectation], timeout: 0.01)
    }

    private func mailboxScreenWithEnvironmentObjects(
        inspectSUT: InspectableView<ViewType.View<HomeScreen>>
    ) throws -> InspectableView<ViewType.ClassifiedView> {
        try inspectSUT
            .mailboxScreenWithInjectedEnvironmentObjects(appUIStateStore, toastStateStore)
            .inspect()
    }

    private func sidebarScreenWithEnvironmentObjects(
        inspectSUT: InspectableView<ViewType.View<HomeScreen>>
    ) throws -> InspectableView<ViewType.ClassifiedView> {
        try inspectSUT
            .sidebarScreenWithInjectedEnvironmentObjects(appUIStateStore, toastStateStore)
            .inspect()
    }

}

private extension InspectableView where View == ViewType.View<HomeScreen> {

    func mailboxScreenWithInjectedEnvironmentObjects(
        _ appUIStateStore: AppUIStateStore,
        _ toastStateStore: ToastStateStore
    ) throws -> any SwiftUI.View {
        let mailboxScreen = try find(MailboxScreen.self)
        let mailboxScreenView =
            try mailboxScreen
            .actualView()
            .environmentObject(appUIStateStore)
            .environmentObject(toastStateStore)

        return mailboxScreenView
    }

    func sidebarScreenWithInjectedEnvironmentObjects(
        _ appUIStateStore: AppUIStateStore,
        _ toastStateStore: ToastStateStore
    ) throws -> any SwiftUI.View {
        let sidebarScreen = try find(SidebarScreen.self)
        let sidebarScreenView =
            try sidebarScreen
            .actualView()
            .environmentObject(appUIStateStore)
            .environmentObject(toastStateStore)

        return sidebarScreenView
    }

}

private extension InspectableView where View == ViewType.ClassifiedView {

    func simulateTapOnHamburgerMenu() throws {
        let hamburgerAnyView = try find(viewWithAccessibilityIdentifier: "main.toolbar.hamburgerButton")
        let hamburgerButton = try hamburgerAnyView.button()

        try hamburgerButton.tap()
    }

    func simulateTapOnLogout() throws {
        let logoutButton = try find(button: "Sign Out")

        try logoutButton.tap()
    }

}

private extension MailUserSession {

    static func testInstance() async throws -> MailUserSession {
        let appContext = AppContext.shared

        guard let userSession = appContext.sessionState.userSession else {
            return try await newUserSession()
        }

        return userSession
    }

    private static func newUserSession() async throws -> MailUserSession {
        let applicationSupportFolder = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first
            .unsafelyUnwrapped
        let cacheFolder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first.unsafelyUnwrapped
        let apiConfig = ApiConfig(envId: .custom("http://localhost:8000"))

        let applicationSupportPath = applicationSupportFolder.path()
        let cachePath = cacheFolder.path()

        let params = MailSessionParams(
            sessionDir: applicationSupportPath,
            userDir: applicationSupportPath,
            mailCacheDir: cachePath,
            mailCacheSize: 1_000_000,
            logDir: cachePath,
            logDebug: true,
            apiEnvConfig: apiConfig
        )

        let mailSession = try createMailSession(
            params: params,
            keyChain: KeychainSDKWrapper(),
            hvNotifier: nil
        ).get()

        let authCoordinator = AccountAuthCoordinator(productName: "mail", appContext: mailSession)

        let storedSession = authCoordinator.primaryAccountSignedInSession().unsafelyUnwrapped

        switch await mailSession.userContextFromSession(session: storedSession) {
        case .ok(let mailUserSession):
            return mailUserSession
        case .error(let error):
            throw error
        }
    }

}
