//
//  FuncStub.swift
//  ProtonCore-TestingToolkit - Created on 31/03/2021.
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import XCTest

@propertyWrapper
public final class FuncStub<Input, Output, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12> {

    public var wrappedValue: StubbedFunction<Input, Output, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12>

    init(initialReturn: @escaping (Input) throws -> Output, function: String, line: UInt, file: String) {
        wrappedValue = StubbedFunction(initialReturn: .init(initialReturn), function: function, line: line, file: file)
    }

    init(initialReturn: InitialReturn<Input, Output>, function: String, line: UInt, file: String) {
        wrappedValue = StubbedFunction(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    init(function: String, line: UInt, file: String) where Output == Void {
        wrappedValue = StubbedFunction(initialReturn: .init { _ in }, function: function, line: line, file: file)
    }
}

public final class StubbedFunction<Input, Output, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12> {

    public private(set) var callCounter: UInt = .zero
    public private(set) var capturedArguments: [CapturedArguments<Input, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12>] = []

    public var description: String
    public var ensureWasCalled = false
    public var failOnBeingCalledUnexpectedly = false

    private lazy var implementation: (UInt, Input) -> Output = { [unowned self] _, input in
        guard let initialReturn = initialReturn else {
            XCTFail("initial return was not provided: \(self.description)")
            fatalError()
        }
        if self.failOnBeingCalledUnexpectedly {
            XCTFail("this method should not be called but was: \(self.description)")
            return try! initialReturn.closure(input)
        }
        return try! initialReturn.closure(input)
    }

    private var initialReturn: InitialReturn<Input, Output>?

    init(initialReturn: InitialReturn<Input, Output>, function: String, line: UInt, file: String) {
        self.initialReturn = initialReturn
        description = "\(function) at line \(line) of file \(file)"
    }

    func replaceBody(_ newImplementation: @escaping (UInt, Input) -> Output) {
        initialReturn = nil
        implementation = newImplementation
    }

    func appendBody(_ additionalImplementation: @escaping (UInt, Input) -> Output) {
        guard initialReturn == nil else {
            replaceBody(additionalImplementation)
            return
        }
        let currentImplementation = implementation
        implementation = {
            // ignoring the first output
            _ = currentImplementation($0, $1)
            return additionalImplementation($0, $1)
        }
    }

    func callAsFunction(input: Input, arguments: CapturedArguments<Input, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12>) -> Output {
        callCounter += 1
        capturedArguments.append(arguments)
        return implementation(callCounter, input)
    }

    deinit {
        if ensureWasCalled && callCounter == 0 {
            XCTFail("this method should be called but wasn't: \(description)")
        }
    }
}
