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

import Foundation
import ProtonCoreQuarkCommands

private let usersSubscription = "quark/raw::user:create:subscription"

extension Quark {
    @available(*, deprecated, renamed: "newSeedNewSubscriber", message: "`Use new payment provider`.")
    @discardableResult
    func enableSubscription(id: Int, plan: String) throws -> (data: Data, response: URLResponse) {
        let args = [
            "userID=\(id)",
            "--planID=\(plan)"
        ]

        let request = try route(usersSubscription)
            .args(args)
            .build()

        return try executeQuarkRequest(request)
    }
}
