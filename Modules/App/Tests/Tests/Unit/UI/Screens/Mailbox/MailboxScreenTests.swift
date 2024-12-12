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

class MailboxScreenTests: BaseTestCase {

    private var sut: MailboxScreen!
    private var userDefaults: UserDefaults!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        userDefaults = .clearedTestInstance()
        sut = MailboxScreen(
            mailSettingsLiveQuery: MailSettingsLiveQueryPreviewDummy(),
            appRoute: AppRouteState(route: .mailbox(selectedMailbox: .inbox)),
            userDefaults: userDefaults
        )
    }

    override func tearDown() {
        userDefaults = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Onboarding sheet

    func testOnboarding_WhenNoDataInUserDefaults_ItPresentsSheet() throws {
        arrange { inspectSUT in
            let onboarding = try? inspectSUT.onboardingScreen()

            XCTAssertNotNil(onboarding)
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
            XCTAssertNotNil(try? inspectSUT.onboardingScreen())
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
        let userSettings = UserSettings()

        ViewHosting.host(
            view: sut
                .environmentObject(appUIStateStore)
                .environmentObject(toastStateStore)
                .environmentObject(userSettings)
        )

        wait(for: [expectation], timeout: 0.01)
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
