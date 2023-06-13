// Copyright (c) 2023 Proton Technologies AG
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

import Foundation
import ProtonCore_Services

typealias RegisterDeviceUseCase = NewUseCase<Void, RegisterDevice.Params>

final class RegisterDevice: RegisterDeviceUseCase {
    private let dependencies: Dependencies

    private var apnEnvironment: DeviceAPI.APNEnvironment {
        let result: DeviceAPI.APNEnvironment
        if UIApplication.isEnterprise {
            result = UIApplication.isDebug ? .enterpriseDev : .enterpriseProd
        } else {
            result = UIApplication.isDebug ? .development : .production
        }
        return result
    }

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    override func executionBlock(params: Params, callback: @escaping Callback) {
        guard let user = dependencies.usersManager.getUser(by: params.uid) else {
            SystemLogger.log(message: "register device: user not found for uid=\(params.uid.redacted)", isError: true)
            callback(.failure(RegisterDeviceError.userManagerNotFound))
            return
        }

        let deviceName = dependencies.uiDevice.name.isEmpty ? "defaultName" : dependencies.uiDevice.name
        let request = DeviceRegistrationRequest(
            deviceToken: params.deviceToken,
            deviceName: deviceName,
            deviceModel: dependencies.uiDevice.model,
            deviceVersion: dependencies.uiDevice.systemVersion,
            appVersion: dependencies.appVersion,
            apnEnvironment: apnEnvironment,
            publicEncryptionKey: params.publicEncryptionKey
        )

        user.apiService.perform(request: request) { _, result in
            switch result {
            case .success:
                callback(.success(()))
            case .failure(let error):
                callback(.failure(error))
            }
        }
    }
}

extension RegisterDevice {

    struct Params {
        let uid: String
        let deviceToken: String
        let publicEncryptionKey: String
    }

    struct Dependencies {
        let uiDevice: UIDevice
        let appVersion: String
        let usersManager: UsersManager

        init(
            uiDevice: UIDevice = UIDevice.current,
            appVersion: String = Bundle.main.bundleShortVersion,
            usersManager: UsersManager
        ) {
            self.uiDevice = uiDevice
            self.appVersion = appVersion
            self.usersManager = usersManager
        }
    }
}

enum RegisterDeviceError: Error {
    case userManagerNotFound
}
