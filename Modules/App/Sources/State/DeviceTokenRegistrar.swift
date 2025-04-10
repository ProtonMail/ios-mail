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

import InboxCore
import proton_app_uniffi

actor DeviceTokenRegistrar {
    private let getMailSession: () -> MailSessionProtocol

    private var deviceRegistrationHandle: RegisterDeviceTaskHandle?

    init(getMailSession: @escaping () -> MailSessionProtocol = { AppContext.shared.mailSession }) {
        self.getMailSession = getMailSession
    }

    func onDeviceTokenReceived(_ deviceToken: any Collection<UInt8>) throws(ActionError) {
        let stringToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        AppLogger.log(message: "APNS token: \(stringToken)", category: .notifications)

        if deviceRegistrationHandle == nil {
            deviceRegistrationHandle = try getMailSession().registerDeviceTask().get()
        }

        let deviceRegistrationRequest = prepareDeviceRegistrationRequest(deviceToken: stringToken)
        try deviceRegistrationHandle!.updateDevice(device: deviceRegistrationRequest).get()
    }

    private func prepareDeviceRegistrationRequest(deviceToken: String) -> RegisteredDevice {
        let environment: DeviceEnvironment

#if DEBUG
        environment = .appleDevEt
#else
        environment = .appleProdEt
#endif

        return RegisteredDevice(
            deviceToken: deviceToken,
            environment: environment,
            pingNotificationStatus: nil,
            pushNotificationStatus: nil
        )
    }
}
