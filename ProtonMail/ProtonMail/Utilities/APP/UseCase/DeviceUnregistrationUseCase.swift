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

import ProtonCore_Networking
import ProtonCore_Services

protocol DeviceUnregistrationUseCase {
    func execute(sessionIDs: [String], deviceToken: String) async -> [DeviceUnregistrationResult]
}

struct DeviceUnregistration: DeviceUnregistrationUseCase {
    private let dependencies: Dependencies

    init(dependencies: Dependencies = .init()) {
        self.dependencies = dependencies
    }

    func execute(sessionIDs: [String], deviceToken: String) async -> [DeviceUnregistrationResult] {
        guard !sessionIDs.isEmpty else { return [] }
        return await sendRequests(sessionIDs: sessionIDs, deviceToken: deviceToken)
    }

    private func sendRequests(sessionIDs: [String], deviceToken: String) async -> [DeviceUnregistrationResult] {
        return await withTaskGroup(of: DeviceUnregistrationResult.self) { group -> [DeviceUnregistrationResult] in
            for sessionID in sessionIDs {
                group.addTask {
                    let request = DeviceUnregistrationRequest(deviceToken: deviceToken, uid: sessionID)
                    return await sendRequest(request, sessionID: sessionID)
                }
            }
            var responses: [DeviceUnregistrationResult] = []
            for await result in group {
                responses.append(result)
            }
            return responses
        }
    }

    private func sendRequest(
        _ request: DeviceUnregistrationRequest,
        sessionID: String
    ) async -> DeviceUnregistrationResult {
        var caughtError: DeviceUnregistrationError?
        do {
            _ = try await dependencies.apiService.perform(request: request)
        } catch let responseError as ResponseError {
            caughtError = .responseError(error: responseError)
        } catch {
            PMAssertionFailure(error)
            caughtError = .unexpected(error: error)
        }
        if let caughtError {
            let token = request.deviceToken.redacted
            let sessionID = sessionID.redacted
            let msg = "device unregistration failed for token: \(token) session: \(sessionID) error: \(caughtError)"
            SystemLogger.log(message: msg, category: .pushNotification, isError: true)
        }
        return DeviceUnregistrationResult(sessionID: sessionID, error: caughtError)
    }
}

extension DeviceUnregistration {

    struct Dependencies {
        let apiService: APIService

        init(apiService: APIService = PMAPIService.unauthorized) {
            self.apiService = apiService
        }
    }
}

struct DeviceUnregistrationResult {
    let sessionID: String
    let error: DeviceUnregistrationError?
}

enum DeviceUnregistrationError: Error {
    case responseError(error: ResponseError)
    case unexpected(error: Error)
}
