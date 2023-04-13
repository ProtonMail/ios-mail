//
//  UniquelyMergeable.swift
//  ProtonCore-Utilities-Tests - Created on 13/01/2023.
//
//  Copyright (c) 2023 Proton Technologies AG
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation

/// A type that allows instances to be merged, preserving order and removing duplicate elements.
protocol UniquelyMergeable {
    associatedtype Element

    /// Merges two instances, preserving order and removing duplicate elements.
    func uniquelyMerging(with other: Self) -> Self

    /// Returns a copy, appending the contents of the argument.
    func appending(_ other: Self) -> Self

    /// Returns a copy, with all duplicate elements removed, preserving the order of elements.
    var uniqued: Self { get }
}

extension UniquelyMergeable {
    public func uniquelyMerging(with other: Self) -> Self {
        self.appending(other).uniqued
    }
}
