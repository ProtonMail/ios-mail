//
//  Stabbing+Ergonomics.swift
//  ProtonCore-TestingToolkit - Created on 13/09/2021.
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

public protocol Stabbing {
    associatedtype Input
    associatedtype A1
    associatedtype A2
    associatedtype A3
    associatedtype A4
    associatedtype A5
    associatedtype A6
    associatedtype A7
    associatedtype A8
    associatedtype A9
    associatedtype A10
    associatedtype A11
    associatedtype A12
    var callCounter: UInt { get }
    var capturedArguments: [CapturedArguments<Input, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12>] { get }
}

extension StubbedFunction: Stabbing {}
extension ThrowingStubbedFunction: Stabbing {}

extension Stabbing {

    public var wasNotCalled: Bool { callCounter == .zero }
    public var wasCalled: Bool { callCounter != .zero }

    public var wasCalledExactlyOnce: Bool { callCounter == 1 }

    public var lastArguments: CapturedArguments<Input, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12>? { capturedArguments.last }

    public func arguments(forCallCounter: UInt) -> CapturedArguments<Input, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12>? {
        let argumentsIndex = Int(forCallCounter) - 1
        return capturedArguments.indices.contains(argumentsIndex) ? capturedArguments[argumentsIndex] : nil
    }
}
