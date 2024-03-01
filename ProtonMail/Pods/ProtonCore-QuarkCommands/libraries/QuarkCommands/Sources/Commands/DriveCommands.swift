//
//  SettingsCommands.swift
//  ProtonCore-QuarkCommands - Created on 08.12.2023.
//
// Copyright (c) 2023. Proton Technologies AG
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

private let drivePopulate: String = "quark/raw::drive:populate"

public extension Quark {

    @discardableResult
    func drivePopulateUser(user: User, scenario: Int, hasPhotos: Bool) throws -> (data: Data, response: URLResponse) {

        let args = [
            "-u=\(user.name)",
            "-p=\(user.password)",
            "-S=\(scenario)",
            "--photo=\(hasPhotos)"
        ]

        let request = try route(drivePopulate)
            .args(args)
            .build()

        return try executeQuarkRequest(request)
    }
}
