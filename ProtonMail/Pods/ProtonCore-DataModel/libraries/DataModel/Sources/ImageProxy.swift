//
//  ImageProxy.swift
//  ProtonCore-DataModel - Created on 25/08/2022.
//
//  Copyright (c) 2022 Proton Technologies AG
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
//  along with ProtonCore. If not, see <https://www.gnu.org/licenses/>.

import Foundation

public struct ImageProxy: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let none = Self([])

    /// Whether remote images are downloaded and incorporated into mail at delivery. Implemented by the backend.
    public static let imageIncorporator = Self(rawValue: 1 << 0)

    /// Whether loading remote images on the clients passes through the proton proxy. Implemented by the client.
    public static let imageProxy = Self(rawValue: 1 << 1)
}
