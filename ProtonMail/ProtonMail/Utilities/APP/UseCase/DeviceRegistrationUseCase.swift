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

import ProtonCoreNetworking
import UIKit

// sourcery: mock
protocol DeviceRegistrationUseCase {
    func execute(sessionIDs: [String], deviceToken: String, publicKey: String) async -> [DeviceRegistrationResult]
}

struct DeviceRegistration: DeviceRegistrationUseCase {
    private let dependencies: Dependencies

    private var apnEnvironment: DeviceAPI.APNEnvironment {
        Application.isDebug ? .development : .production
    }

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func execute(sessionIDs: [String], deviceToken: String, publicKey: String) async -> [DeviceRegistrationResult] {
        guard !sessionIDs.isEmpty else {
            return sessionIDs.map { DeviceRegistrationResult(sessionID: $0, error: .noSessionIdFound(sessionId: $0)) }
        }
        var result = [DeviceRegistrationResult]()
        let users: [UserManager] = sessionIDs.compactMap {
            guard let user = dependencies.usersManager.getUser(by: $0) else {
                SystemLogger.log(message: "user for session \($0) not found")
                result.append(.init(sessionID: $0, error: .noSessionIdFound(sessionId: $0)))
                return nil
            }
            return user
        }

        let deviceName = await dependencies.uiDevice.name.isEmpty ? "defaultName" : dependencies.uiDevice.name
        let request = await DeviceRegistrationRequest(
            deviceToken: deviceToken,
            deviceName: deviceName,
            deviceModel: dependencies.uiDevice.model,
            deviceVersion: dependencies.uiDevice.systemVersion,
            appVersion: dependencies.appVersion,
            apnEnvironment: apnEnvironment,
            publicEncryptionKey: publicKey
        )

        let requestsResult = await sendRequest(request, for: users)
        result.append(contentsOf: requestsResult)
        return result
    }

    private func sendRequest(
        _ request: DeviceRegistrationRequest,
        for users: [UserManager]
    ) async -> [DeviceRegistrationResult] {
        return await withTaskGroup(of: DeviceRegistrationResult.self) { group -> [DeviceRegistrationResult] in
            for user in users {
                group.addTask { await sendRequest(request, for: user) }
            }
            var responses: [DeviceRegistrationResult] = []
            for await result in group {
                responses.append(result)
            }
            return responses
        }
    }

    private func sendRequest(
        _ request: DeviceRegistrationRequest,
        for user: UserManager
    ) async -> DeviceRegistrationResult {
        var caughtError: DeviceRegistrationError?
        do {
            _ = try await user.apiService.perform(request: request)
        } catch let responseError as ResponseError {
            caughtError = .responseError(error: responseError)
        } catch {
            PMAssertionFailure(error)
            caughtError = .unexpected(error: error)
        }
        if let caughtError {
            let token = request.deviceToken.redacted
            let sessionID = user.authCredential.sessionID
            let msg = "device registration failed for token: \(token) session: \(sessionID), error: \(caughtError)"
            SystemLogger.log(message: msg, category: .pushNotification, isError: true)
        }
        return DeviceRegistrationResult(sessionID: user.authCredential.sessionID, error: caughtError)
    }
}

extension DeviceRegistration {

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

struct DeviceRegistrationResult {
    let sessionID: String
    let error: DeviceRegistrationError?
}

enum DeviceRegistrationError: Error {
    case noSessionIdFound(sessionId: String)
    case responseError(error: ResponseError)
    case unexpected(error: Error)
}
