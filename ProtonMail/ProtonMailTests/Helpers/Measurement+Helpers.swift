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

@testable import ProtonMail

extension Measurement where UnitType: UnitInformationStorage {

    init() {
        self = .zero
    }

    static var randomBytesPositiveValue: Measurement<UnitInformationStorage> {
        let value = Double.random(in: 0...Double.greatestFiniteMagnitude)
        return .init(value: value, unit: .bytes)
    }

    static var randomBytesNegativeValue: Measurement<UnitInformationStorage> {
        let value = Double.random(in: -Double.greatestFiniteMagnitude..<0)
        return .init(value: value, unit: .bytes)
    }
}
