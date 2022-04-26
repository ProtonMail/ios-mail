//
//  PMAuthentication+Extensions.swift
//  ProtonCore-Login - Created on 22.01.2021.
//
//  Copyright (c) 2022 Proton Technologies AG
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

import Foundation
import ProtonCore_DataModel

public extension User {

    var isExternal: Bool { return name == nil }

    var isInternal: Bool { !isExternal }

}

public extension Address {
    var isInternal: Bool {
        return type == .protonDomain || type == .protonAlias || type == .premiumDomain
    }

    var isCustomDomain: Bool {
        return type == .customDomain
    }

    var isExternal: Bool {
        return type == .externalAddress
    }
}

public extension Array where Element: Address {
    var firstInternal: Address? {
        // Identify the first internal address, custom domain is also OK for private users
        first(where: { $0.isInternal }) ?? first(where: { $0.isCustomDomain })
    }
    var firstExternal: Address? { first(where: { $0.isExternal }) }
    var internalOrCustomDomain: [Address] { filter { $0.isInternal || $0.isCustomDomain } }
    var hasInternalOrCustomDomain: Bool { contains { $0.isInternal || $0.isCustomDomain } }
}
