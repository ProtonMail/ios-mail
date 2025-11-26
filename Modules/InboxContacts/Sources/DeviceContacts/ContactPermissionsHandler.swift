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

import Contacts

public struct ContactPermissionsHandler {
    private let permissionsHandler: CNContactStoring

    public init(permissionsHandler: CNContactStoring) {
        self.permissionsHandler = permissionsHandler
    }

    @discardableResult
    public func requestAccessIfNeeded() async -> Bool {
        let status: CNAuthorizationStatus = permissionsHandler.authorizationStatus(for: .contacts)

        switch status {
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                permissionsHandler.requestAccess(for: .contacts) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        case .authorized, .limited:
            return true
        case .restricted, .denied:
            return false
        @unknown default:
            return false
        }
    }
}
