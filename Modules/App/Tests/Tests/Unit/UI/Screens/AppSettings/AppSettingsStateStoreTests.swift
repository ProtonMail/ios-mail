// Copyright (c) 2025 Proton Technologies AG
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
import Testing

@MainActor
class AppSettingsStateStoreTests {

    var sut: AppSettingsStateStore!
    var notificationCenterSpy: UserNotificationCenterSpy!
    var urlOpenerSpy: URLOpenerSpy!
    var bundleSpy: BundleSpy!

    init() {
        notificationCenterSpy = .init()
        urlOpenerSpy = .init()
        bundleSpy = .init()
        sut = AppSettingsStateStore(
            state: .initial,
            notificationCenter: notificationCenterSpy,
            urlOpener: urlOpenerSpy,
            mainBundle: bundleSpy
        )

        bundleSpy.preferredLocalizationsStub = ["en"]
    }

    deinit {
        notificationCenterSpy = nil
        urlOpenerSpy = nil
        bundleSpy = nil
        sut = nil
    }

    @Test
    func whenNotificationsButtonIsTapped_ItAskForNotificationsPermissions() async {
        notificationCenterSpy.stubbedAuthorizationStatus = .notDetermined

        await sut.handle(action: .notificationButtonTapped)

        #expect(notificationCenterSpy.requestAuthorizationInvocations == [[.alert, .badge, .sound]])
        #expect(urlOpenerSpy.openURLInvocations.isEmpty)
    }

    @Test
    func whenNotificationsButtonIsTapped_ItOpensNativeSettings() async {
        notificationCenterSpy.stubbedAuthorizationStatus = .authorized

        await sut.handle(action: .notificationButtonTapped)

        #expect(notificationCenterSpy.requestAuthorizationInvocations.isEmpty)
        #expect(urlOpenerSpy.openURLInvocations == [.settings])
    }

    @Test
    func whenViewAppear_ItRefreshesNotificationsStatusAndLangauge() async {
        notificationCenterSpy.stubbedAuthorizationStatus = .authorized
        bundleSpy.preferredLocalizationsStub = ["pl"]

        await sut.handle(action: .onAppear)

        #expect(sut.state.areNotificationsEnabled)
        #expect(sut.state.appLanguage == "Polish")
    }

}
