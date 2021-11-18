//
//  Organization.swift
//  ProtonCore-Payments - Created on 11/08/2021.
//
//  Copyright (c) 2019 Proton Technologies AG
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.
//

import Foundation

public struct Organization: Codable, Equatable {

//    public let name: String
//    public let displayName: String
//    public let planName: String?
//    public let vPNPlanName: String?
//    public let twoFactorGracePeriod: Int?
//    public let theme: String?
//    public let email: String?
    public let maxDomains: Int
    public let maxAddresses: Int
    public let maxSpace: Int64
    public let maxMembers: Int
    public let maxVPN: Int
    public let maxCalendars: Int?
//    public let features: Int
//    public let flags: Int
//    public let usedDomains: Int
//    public let usedAddresses: Int
//    public let usedSpace: Int
//    public let assignedSpace: Int
//    public let usedMembers: Int
//    public let usedVPN: Int
//    public let hasKeys: Int
//    public let toMigrate: Int

    public var isMultiUser: Bool { maxMembers > 1 }

    public init(maxDomains: Int,
                maxAddresses: Int,
                maxSpace: Int64,
                maxMembers: Int,
                maxVPN: Int,
                maxCalendars: Int?) {
        self.maxDomains = maxDomains
        self.maxAddresses = maxAddresses
        self.maxSpace = maxSpace
        self.maxMembers = maxMembers
        self.maxVPN = maxVPN
        self.maxCalendars = maxCalendars
    }
}
