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

import proton_app_uniffi
import Testing

@testable import ProtonMail

final class DeviceTokenRegistrarTests {
    private let mailSession = MailSessionSpy()

    private lazy var sut = DeviceTokenRegistrar { [unowned self] in
        mailSession
    }

    @Test
    func whenTokenIsUpdatedSeveralTimes_registersOnlyOnce() async throws {
        var lastCreatedHandle: RegisterDeviceTaskHandleSpy?

        mailSession.stubbedRegisterDeviceTaskHandleFactory = {
            let newHandle = RegisterDeviceTaskHandleSpy(noPointer: .init())
            lastCreatedHandle = newHandle
            return newHandle
        }

        for token in ["foo", "bar", "xyz"] {
            try await sut.onDeviceTokenReceived(token.utf8)
        }

        #expect(mailSession.registerDeviceCallCount == 1)

        let registerDeviceTaskHandle = try #require(lastCreatedHandle)
        #expect(registerDeviceTaskHandle.updateDeviceCalls.map(\.deviceToken) == ["666f6f", "626172", "78797a"])
    }
}

private final class RegisterDeviceTaskHandleSpy: RegisterDeviceTaskHandle, @unchecked Sendable {
    private(set) var updateDeviceCalls: [RegisteredDevice] = []

    override func updateDevice(device: RegisteredDevice) -> VoidActionResult {
        updateDeviceCalls.append(device)
        return .ok
    }
}
