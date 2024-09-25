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
            customLabelModel: CustomLabelModel(),
            mailSettingsLiveQuery: MailSettingsLiveQueryPreviewDummy(),
            appRoute: AppRouteState(route: .mailbox(selectedMailbox: .inbox))
        )
    }

    override func tearDown() {
        userDefaults = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Onboarding sheet

    func testShowOnboarding_WhenNoDataInUserDefaults_ItPresentsSheet() throws {
        arrange { inspectSUT in
            let onboarding = try? inspectSUT.onboardingScreen()

            XCTAssertNotNil(onboarding)
        }
    }

    func testOnboardingSheet_WhenShouldShowAlphaV1Onboarding_ItPresentsSheet() throws {
        arrangeStorage(showAlphaV1Onboarding: true)

        arrange { inspectSUT in
            let onboarding = try? inspectSUT.onboardingScreen()

            XCTAssertNotNil(onboarding)
        }
    }

    func testOnboardingSheet_WhenShouldNotShowAlphaV1Onboarding_ItDoesNotPresentSheet() throws {
        arrangeStorage(showAlphaV1Onboarding: false)

        arrange { inspectSUT in
            let onboarding = try? inspectSUT.onboardingScreen()

            XCTAssertNil(onboarding)
        }
    }

    private func arrangeStorage(showAlphaV1Onboarding: Bool) {
        userDefaults.setValue(showAlphaV1Onboarding, forKey: UserDefaultsKey.showAlphaV1Onboarding.rawValue)
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
        let userSettings = UserSettings(mailboxActions: .init())

        ViewHosting.host(
            view: sut
                .environmentObject(appUIStateStore)
                .environmentObject(toastStateStore)
                .environmentObject(userSettings)
                .defaultAppStorage(userDefaults)
        )

        wait(for: [expectation], timeout: 0.01)
    }

}

private extension InspectableView where View == ViewType.View<MailboxScreen> {

    func onboardingScreen() throws -> InspectableView<ViewType.View<OnboardingScreen>> {
        try find(OnboardingScreen.self)
    }

}

private extension UserDefaults {

    static func testInstance(inFile fileName: StaticString = #file) -> UserDefaults {
        .init(suiteName: suiteName(inFile: fileName)).unsafelyUnwrapped
    }

    static func clearedTestInstance(inFile fileName: StaticString = #file) -> UserDefaults {
        let defaults = testInstance(inFile: fileName)
        defaults.removePersistentDomain(forName: suiteName(inFile: fileName))
        return defaults
    }

}

private func suiteName(inFile fileName: StaticString = #file) -> String {
    let className = "\(fileName)".split(separator: ".")[0]
    return "com.proton.mail.test.\(className)"
}

extension InspectableSheet: PopupPresenter {}
