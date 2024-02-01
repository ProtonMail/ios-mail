//
//  LocalFeatureFlagsProtocol.swift
//  ProtonCore-FeatureFlags - Created on 29.09.23.
//
//  Copyright (c) 2023 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation

public protocol LocalFeatureFlagsDataSourceProtocol {
    func getFeatureFlags(userId: String, reloadFromLocalDataSource: Bool) -> FeatureFlags?
    func upsertFlags(_ flags: FeatureFlags, userId: String)
    func cleanAllFlags()
    func cleanFlags(for userId: String)

    var userIdForActiveSession: String? { get }
    func setUserIdForActiveSession(_ userId: String)
    func clearUserId()
}
