//
//  StubbedFunction.swift
//  PMLoginTests - Created on 31/03/2021.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import XCTest

public enum Absent: Int, Equatable, Codable { case nothing }

public struct InitialReturn<Output> {
    let closure: () -> Output

    fileprivate init(_ closure: @escaping () -> Output) {
        self.closure = closure
    }

    public static var crash: InitialReturn<Output> {
        .init {
            fatalError("Stub setup error — you must provide a default value of type \(Output.self) if this stub is ever called!")
        }
    }
}

@propertyWrapper
public final class FuncStub<Input, Output, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12> {

    public var wrappedValue: StubbedFunction<Input, Output, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12>

    init(initialReturn: @escaping () -> Output, function: String, line: UInt, file: String) {
        wrappedValue = StubbedFunction(initialReturn: .init(initialReturn), function: function, line: line, file: file)
    }

    init(initialReturn: InitialReturn<Output>, function: String, line: UInt, file: String) {
        wrappedValue = StubbedFunction(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    init(function: String, line: UInt, file: String) where Output == Void {
        wrappedValue = StubbedFunction(initialReturn: .init {}, function: function, line: line, file: file)
    }
}

public final class StubbedFunction<Input, Output, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12> {

    public internal(set) var callCounter: UInt = .zero
    private var capturedArguments: [CapturedArguments<Input, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12>] = []

    public var description: String
    public var ensureWasCalled = false
    public var failOnBeingCalledUnexpectedly = false

    private lazy var implementation: (UInt, Input) -> Output = { [unowned self] _, _ in
        if self.failOnBeingCalledUnexpectedly {
            XCTFail("this method should not be called but was: \(self.description)")
        }
        return self.initialReturn.closure()
    }

    private let initialReturn: InitialReturn<Output>

    init(initialReturn: InitialReturn<Output>, function: String, line: UInt, file: String) {
        self.initialReturn = initialReturn
        description = "\(function) at line \(line) of file \(file)"
    }

    func setBody(_ implementation: @escaping (UInt, Input) -> Output) {
        self.implementation = implementation
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

// ergonomics
extension StubbedFunction {

    public var wasNotCalled: Bool { callCounter == .zero }
    public var wasCalled: Bool { callCounter != .zero }

    public var wasCalledExactlyOnce: Bool { callCounter == 1 }

    public var lastArguments: CapturedArguments<Input, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12>? { capturedArguments.last }

    public func arguments(forCallCounter: UInt) -> CapturedArguments<Input, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12>? {
        guard callCounter > 0, capturedArguments.count >= callCounter else { return nil }
        return capturedArguments[Int(callCounter - 1)]
    }

}

