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

extension Measurement where UnitType: Dimension {
    static var zero: Measurement<UnitType> {
        .init(value: 0.0, unit: UnitType.baseUnit())
    }

    static var max: Measurement<UnitType> {
        .init(value: .greatestFiniteMagnitude, unit: UnitType.baseUnit())
    }
}

extension Measurement where UnitType == UnitInformationStorage {

    /// Returns a localised string represenation with units: KB, MB, GB ...
    var stringFormatted: String {
        ByteCountFormatter.string(from: self, countStyle: .file)
    }
}
