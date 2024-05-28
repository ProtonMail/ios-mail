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

private let coreSettingsUpdate: String = "quark/raw::core:user:settings:update"

public extension Quark {

    @discardableResult
    func enableEarlyAccess(username: String) throws {

        let args = [
            "--user=\(username)",
            "--early-access=1"
        ]

        let request = try route(coreSettingsUpdate)
            .args(args)
            .build()

        do {
            let (textData, urlResponse) = try executeQuarkRequest(request)
            guard
                let responseHTML = String(data: textData, encoding: .utf8),
                responseHTML.contains("Done")
            else {
                throw QuarkError(urlResponse: urlResponse, message: "Cannot enable early access: \(String(describing: String(data: textData, encoding: .utf8)))")
            }
        } catch {
            throw error
        }
    }
}
