// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
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
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation

struct Phantom<Tag, RawValue> {
    let rawValue: RawValue
}

extension Phantom: CustomStringConvertible where RawValue: CustomStringConvertible {
    var description: String {
        rawValue.description
    }
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

extension Phantom: ExpressibleByIntegerLiteral where RawValue: ExpressibleByIntegerLiteral {
    typealias IntegerLiteralType = RawValue.IntegerLiteralType
    init(integerLiteral value: IntegerLiteralType) {
        self.init(rawValue: RawValue(integerLiteral: value))
    }
}

extension Phantom: ExpressibleByStringLiteral where RawValue: ExpressibleByStringLiteral {
    typealias StringLiteralType = RawValue.StringLiteralType

    init(stringLiteral: StringLiteralType) {
        self.init(rawValue: RawValue(stringLiteral: stringLiteral))
    }

    init(_ stringLiteral: StringLiteralType) {
        self.init(rawValue: RawValue(stringLiteral: stringLiteral))
    }
}

extension Phantom: ExpressibleByUnicodeScalarLiteral where RawValue: ExpressibleByUnicodeScalarLiteral {
    typealias UnicodeScalarLiteralType = RawValue.UnicodeScalarLiteralType

    init(unicodeScalarLiteral: UnicodeScalarLiteralType) {
        self.init(rawValue: RawValue(unicodeScalarLiteral: unicodeScalarLiteral))
    }
}

// swiftlint:disable:next line_length
extension Phantom: ExpressibleByExtendedGraphemeClusterLiteral where RawValue: ExpressibleByExtendedGraphemeClusterLiteral {
    typealias ExtendedGraphemeClusterLiteralType = RawValue.ExtendedGraphemeClusterLiteralType

    init(extendedGraphemeClusterLiteral: ExtendedGraphemeClusterLiteralType) {
        self.init(rawValue: RawValue(extendedGraphemeClusterLiteral: extendedGraphemeClusterLiteral))
    }
}
