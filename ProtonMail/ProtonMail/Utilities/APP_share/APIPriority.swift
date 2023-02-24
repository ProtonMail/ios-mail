// Copyright (c) 2023 Proton Technologies AG
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

/// https://datatracker.ietf.org/doc/html/rfc9218#name-urgency
/// The bigger the number, the lower the priority.
enum APIPriority: String, CaseIterable {
    case highestPriority = "u=0"
    case priority1 = "u=1"
    case priority2 = "u=2"
    case `default` = "u=3"
    case priority4 = "u=4"
    case priority5 = "u=5"
    case priority6 = "u=6"
    case lowestPriority = "u=7"
}
