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

import proton_app_uniffi
import Testing

@MainActor
final class MobileSignatureStateStoreTests {
    private let customSettings = CustomSettingsSpy(stubbedMobileSignature: .init(body: "Foo bar", status: .enabled))

    private lazy var sut = MobileSignatureStateStore(customSettings: customSettings, clock: AlmostImmediateClock())

    @Test
    func onLoadLoadsMobileSignature() async {
        #expect(sut.state == .initial)

        await sut.handle(action: .onLoad)

        #expect(sut.state.mobileSignature == .init(body: "Foo bar", status: .enabled))
    }

    @Test
    func showsAnErrorIfFailedToLoad() async {
        let error = ProtonError.unexpected(.crypto)
        customSettings.stubbedMobileSignatureError = error

        await sut.handle(action: .onLoad)

        #expect(sut.state.toast == .error(message: error.localizedDescription))
    }

    @Test
    func setIsEnabledBothSetsStateAndStoresSetting() async {
        await sut.handle(action: .setIsEnabled(false))
        #expect(sut.state.mobileSignature.status == .disabled)
        #expect(customSettings.setMobileSignatureEnabledCalls == [false])

        await sut.handle(action: .setIsEnabled(true))
        #expect(sut.state.mobileSignature.status == .enabled)
        #expect(customSettings.setMobileSignatureEnabledCalls == [false, true])
    }

    @Test
    func saveContent_debouncesQuickUpdatesWithoutError() async {
        let updates: [String] = [
            "f",
            "fo",
            "foo",
        ]

        var tasks: [Task<Void, Never>] = []

        for update in updates {
            sut.state.mobileSignature.body = update

            let task = Task {
                await sut.handle(action: .saveContent)
            }

            tasks.append(task)
        }

        for task in tasks {
            _ = await task.result
        }

        #expect(customSettings.setMobileSignatureCalls == ["foo"])
        #expect(sut.state.toast == nil)
    }
}

private struct AlmostImmediateClock: Clock {
    private let wrappedClock = ContinuousClock()

    var now: ContinuousClock.Instant {
        wrappedClock.now
    }

    var minimumResolution: ContinuousClock.Duration {
        wrappedClock.minimumResolution
    }

    func sleep(until deadline: Instant, tolerance: Duration?) async throws {
        try await wrappedClock.sleep(for: .milliseconds(100))
    }
}
