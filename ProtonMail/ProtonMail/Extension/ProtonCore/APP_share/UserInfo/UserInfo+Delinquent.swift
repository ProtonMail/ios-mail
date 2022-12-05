// Copyright (c) 2022 Proton AG
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
import ProtonCore_DataModel

extension UserInfo {
    enum Delinquent: Int {
        case paid = 0
        // 1 - less than 7 days of delinquency
        // 2 - less than 14 days
        // 3 - less than 30
        // 4 - more than 30
        // Should be more or less accurate
        // [0, 1, 2] still useable
        case unpaidAvailable = 1
        case unpaidOverdue = 2
        case unpaidDelinquent = 3
        case unpaidNoReceive = 4
        case unknown = 99_999

        var isAvailable: Bool { rawValue < 3 }
    }

    var delinquentParsed: Delinquent {
        Delinquent(rawValue: delinquent) ?? .unknown
    }
}
