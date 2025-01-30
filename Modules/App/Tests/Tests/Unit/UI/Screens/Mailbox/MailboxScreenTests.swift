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
import ViewInspector
import XCTest

@MainActor
class MailboxScreenTests: BaseTestCase {

    private var sut: MailboxScreen!
    private var userDefaults: UserDefaults!

    override func setUp() async throws {
        try await super.setUp()
        userDefaults = .clearedTestInstance()
        sut = MailboxScreen(
            mailSettingsLiveQuery: MailSettingsLiveQueryPreviewDummy(),
            appRoute: AppRouteState(route: .mailbox(selectedMailbox: .inbox)),
            userSession: .dummy,
            userDefaults: userDefaults,
            draftPresenter: .dummy,
            sendResultPresenter: .init(undoSendProvider: .mockInstance, draftPresenter: .dummy)
        )

        // the tests are disabled until we can determine why they're failing after upgrading to Xcode 16
        // we have already taken the AnyView wrapping into account, and apparently that's not it
        // perhaps the library will be fixed by its maintainers, or eventually we might decide to remove these tests
        try XCTSkipIf(true)
    }

    override func tearDown() async throws {
        userDefaults = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Onboarding sheet

    func testOnboarding_WhenNoDataInUserDefaults_ItPresentsSheet() throws {
        arrange { inspectSUT in
            _ = try inspectSUT.onboardingScreen()
            XCTAssertEqual(self.storedShowOnboarding, nil)
        }
    }

    func testOnboarding_WhenNoDataInUserDefaultsAndDismiss_ItDismissesAndUpdatesStorages() throws {
        arrange { inspectSUT in
            let sheet = try inspectSUT.onboardingSheet()
            try sheet.dismiss()

            XCTAssertNil(try? inspectSUT.onboardingScreen())
            XCTAssertEqual(self.storedShowOnboarding, false)
        }
    }

    func testOnboarding_WhenShouldShowAlphaV1Onboarding_ItPresentsSheet() throws {
        arrangeStorage(showAlphaV1Onboarding: true)

        arrange { inspectSUT in
            _ = try inspectSUT.onboardingScreen()
            XCTAssertEqual(self.storedShowOnboarding, true)
        }
    }

    func testOnboarding_WhenShouldShowAlphaV1OnboardingAndDismiss_ItDismissesAndUpdatesStorages() throws {
        arrangeStorage(showAlphaV1Onboarding: true)

        arrange { inspectSUT in
            let sheet = try inspectSUT.onboardingSheet()
            try sheet.dismiss()

            XCTAssertNil(try? inspectSUT.onboardingScreen())
            XCTAssertEqual(self.storedShowOnboarding, false)
        }
    }

    func testOnboarding_WhenShouldNotShowAlphaV1Onboarding_ItDoesNotPresentSheet() throws {
        arrangeStorage(showAlphaV1Onboarding: false)

        arrange { inspectSUT in
            let onboarding = try? inspectSUT.onboardingScreen()

            XCTAssertNil(onboarding)
            XCTAssertEqual(self.storedShowOnboarding, false)
        }
    }

    // MARK: - Private

    private func arrangeStorage(showAlphaV1Onboarding: Bool) {
        userDefaults.setValue(showAlphaV1Onboarding, forKey: UserDefaultsKey.showAlphaV1Onboarding.rawValue)
    }

    private var storedShowOnboarding: Bool? {
        userDefaults.value(forKey: UserDefaultsKey.showAlphaV1Onboarding.rawValue) as? Bool
    }

    private func arrange(
        function: String = #function,
        file: StaticString = #file,
        line: UInt = #line,
        perform: @escaping (InspectableView<ViewType.View<MailboxScreen>>) throws -> Void
    ) {
        let expectation = sut.on(
            \.didAppear,
             function: function,
             file: file,
             line: line,
             perform: perform
        )

        let appUIStateStore = AppUIStateStore()
        let toastStateStore = ToastStateStore(initialState: .initial)

        ViewHosting.host(
            view: sut
                .environmentObject(appUIStateStore)
                .environmentObject(toastStateStore)
        )

        wait(for: [expectation], timeout: 0.1)
    }

}

private extension InspectableView where View == ViewType.View<MailboxScreen> {

    func onboardingScreen() throws -> InspectableView<ViewType.View<OnboardingScreen>> {
        try find(OnboardingScreen.self)
    }

    func onboardingSheet() throws -> InspectableView<ViewType.Sheet> {
        try navigationStack().zStack().sheet()
    }

}
