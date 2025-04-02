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

import proton_app_uniffi

protocol LegacyValueConvertible<PrimitiveType> {
    associatedtype PrimitiveType

    init?(legacyValue: PrimitiveType)
}

extension AppAppearance: LegacyValueConvertible {
    init?(legacyValue: Int) {
        self.init(rawValue: UInt8(legacyValue))
    }
}

extension AutoLock: LegacyValueConvertible {
    init?(legacyValue: String) {
        guard let integerValue = UInt8(legacyValue) else {
            return nil
        }

        switch integerValue {
        case 0:
            self = .always
        case let positiveNumber:
            self = .minutes(UInt8(positiveNumber))
        }
    }
}
