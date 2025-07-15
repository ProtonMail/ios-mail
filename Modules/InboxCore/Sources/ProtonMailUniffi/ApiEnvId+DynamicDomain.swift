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
import proton_app_uniffi

extension ApiEnvId {
    public init(dynamicDomain: String) {
        let scientistSuffix = Self.scientist(.empty).domain

        switch dynamicDomain {
        case Self.prod.domain:
            self = .prod
        case Self.atlas.domain:
            self = .atlas
        case _ where dynamicDomain.hasSuffix(scientistSuffix):
            let scientistName = dynamicDomain.dropLast(scientistSuffix.count)
            self = .scientist(String(scientistName))
        default:
            self = .custom(dynamicDomain)
        }
    }

    public var domain: String {
        switch self {
        case .prod:
            "proton.me"
        case .atlas:
            "proton.black"
        case .scientist(let name):
            "\(name).proton.black"
        case .custom(let fullURL):
            URL(string: fullURL)!.host()!
        }
    }
}
