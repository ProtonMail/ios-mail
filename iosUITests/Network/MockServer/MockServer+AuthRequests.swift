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

import Foundation

extension MockServer {
    /// Adds the base authorization mocks needed for a given user to log in.
    func setupUserAuthorisationMocks(user: UITestUser) async {
        await addRequests(
            NetworkRequest(
                method: .post,
                remotePath: "/auth/v4",
                localPath: "auth-v4_\(user.id).json"
            ),
            NetworkRequest(
                method: .post,
                remotePath: "/auth/v4/info",
                localPath: "info_\(user.id).json"
            ),
            NetworkRequest(
                method: .post,
                remotePath: "/auth/v4/sessions",
                localPath: "sessions_\(user.id).json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/core/v4/users",
                localPath: "users_\(user.id).json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/core/v4/addresses",
                localPath: "addresses_\(user.id).json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/core/v4/key/salts",
                localPath: "salts_\(user.id).json"
            ),
            NetworkRequest(
                method: .get,
                remotePath: "/core/v4/scopes",
                localPath: "scopes_\(user.id).json"
            )
        )
    }
}
