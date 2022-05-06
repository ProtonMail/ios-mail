// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation

struct Phantom<Tag, RawValue> {
    let rawValue: RawValue
}

extension Phantom: Decodable  where RawValue: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: try container.decode(RawValue.self))
    }
}

extension Phantom: Equatable where RawValue: Equatable {
    static func == (lhs: Phantom<Tag, RawValue>, rhs: Phantom<Tag, RawValue>) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension Phantom: Hashable where RawValue: Hashable {}
