//
//  String+Extensions.swift
//  ProtonCore-Utilities - Created on 4/19/21.
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

import Foundation

extension String {
    
    public var utf8: Data? {
        return self.data(using: .utf8)
    }

    public func initials() -> String {
        let invalids = "[.,/#!$@%^&*;:{}=\\-_`~()]"
        let splits = self
            .components(separatedBy: .whitespaces)
            .compactMap { $0.first?.uppercased() }
            .filter { !invalids.contains($0) }

        var initials = [splits.first]
        if splits.count > 1 {
            initials.append(splits.last)
        }

        let result = initials
            .compactMap { $0 }
            .joined()
        return result.isEmpty ? "?": result
    }

}

extension String {
    
    subscript(value: Int) -> Character {
        self[index(at: value)]
    }

    subscript(value: NSRange) -> Substring {
        self[value.lowerBound..<value.upperBound]
    }

    subscript(value: CountableClosedRange<Int>) -> Substring {
        self[index(at: value.lowerBound)...index(at: value.upperBound)]
    }

    subscript(value: CountableRange<Int>) -> Substring {
        self[index(at: value.lowerBound)..<index(at: value.upperBound)]
    }

    subscript(value: PartialRangeUpTo<Int>) -> Substring {
        self[..<index(at: value.upperBound)]
    }

    subscript(value: PartialRangeThrough<Int>) -> Substring {
        self[...index(at: value.upperBound)]
    }

    subscript(value: PartialRangeFrom<Int>) -> Substring {
        self[index(at: value.lowerBound)...]
    }

    func index(at offset: Int) -> String.Index {
        index(startIndex, offsetBy: offset)
    }
}
