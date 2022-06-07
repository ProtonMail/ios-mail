//
//  ThrowingFuncStub+Ergonomics.swift
//  ProtonCore-TestingToolkit - Created on 13/09/2021.
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

// swiftlint:disable function_parameter_count

import Foundation

extension ThrowingFuncStub where Input == Void, Output == Void, A1 == Absent, A2 == Absent, A3 == Absent, A4 == Absent, A5 == Absent, A6 == Absent, A7 == Absent,
                         A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public convenience init<T>(_ prototype: (T) -> () throws -> Void,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(function: function, line: line, file: file)
    }
}

extension ThrowingFuncStub where Input == Void, A1 == Absent, A2 == Absent, A3 == Absent, A4 == Absent, A5 == Absent, A6 == Absent, A7 == Absent,
                         A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public convenience init<T>(_ prototype: (T) -> () throws -> Output,
                               initialReturn: @autoclosure @escaping () throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> () throws -> Output,
                               initialReturn: @escaping () throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> () throws -> Output,
                               initialReturn: InitialReturn<Input, Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }
}

extension ThrowingFuncStub where Input == A1, A2 == Absent, A3 == Absent, A4 == Absent, A5 == Absent, A6 == Absent, A7 == Absent,
                         A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public convenience init<T>(_ prototype: (T) -> (A1) throws -> Output,
                               initialReturn: @autoclosure @escaping () throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: { _ in try initialReturn() }, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1) throws -> Output,
                               initialReturn: @escaping (Input) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1) throws -> Output,
                               initialReturn: InitialReturn<Input, Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension ThrowingFuncStub where Input == (A1, A2), A3 == Absent, A4 == Absent, A5 == Absent, A6 == Absent, A7 == Absent,
                         A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2) throws -> Output,
                               initialReturn: @autoclosure @escaping () throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: { _ in try initialReturn() }, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2) throws -> Output,
                               initialReturn: @escaping (Input) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2) throws -> Output,
                               initialReturn: InitialReturn<Input, Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1, A2) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension ThrowingFuncStub where Input == (A1, A2, A3), A4 == Absent, A5 == Absent, A6 == Absent, A7 == Absent,
                         A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3) throws -> Output,
                               initialReturn: @autoclosure @escaping () throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: { _ in try initialReturn() }, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3) throws -> Output,
                               initialReturn: @escaping (Input) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3) throws -> Output,
                               initialReturn: InitialReturn<Input, Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1, A2, A3) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension ThrowingFuncStub where Input == (A1, A2, A3, A4), A5 == Absent, A6 == Absent, A7 == Absent,
                         A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4) throws -> Output,
                               initialReturn: @autoclosure @escaping () throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: { _ in try initialReturn() }, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4) throws -> Output,
                               initialReturn: @escaping (Input) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4) throws -> Output,
                               initialReturn: InitialReturn<Input, Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1, A2, A3, A4) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension ThrowingFuncStub where Input == (A1, A2, A3, A4, A5), A6 == Absent, A7 == Absent,
                         A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5) throws -> Output,
                               initialReturn: @autoclosure @escaping () throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: { _ in try initialReturn() }, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5) throws -> Output,
                               initialReturn: @escaping (Input) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5) throws -> Output,
                               initialReturn: InitialReturn<Input, Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1, A2, A3, A4, A5) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension ThrowingFuncStub where Input == (A1, A2, A3, A4, A5, A6), A7 == Absent, A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6) throws -> Output,
                               initialReturn: @autoclosure @escaping () throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: { _ in try initialReturn() }, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6) throws -> Output,
                               initialReturn: @escaping (Input) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6) throws -> Output,
                               initialReturn: InitialReturn<Input, Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1, A2, A3, A4, A5, A6) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension ThrowingFuncStub where Input == (A1, A2, A3, A4, A5, A6, A7), A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7) throws -> Output,
                               initialReturn: @autoclosure @escaping () throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: { _ in try initialReturn() }, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7) throws -> Output,
                               initialReturn: @escaping (Input) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7) throws -> Output,
                               initialReturn: InitialReturn<Input, Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1, A2, A3, A4, A5, A6, A7) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension ThrowingFuncStub where Input == (A1, A2, A3, A4, A5, A6, A7, A8), A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8) throws -> Output,
                               initialReturn: @autoclosure @escaping () throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: { _ in try initialReturn() }, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8) throws -> Output,
                               initialReturn: @escaping (Input) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8) throws -> Output,
                               initialReturn: InitialReturn<Input, Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1, A2, A3, A4, A5, A6, A7, A8) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension ThrowingFuncStub where Input == (A1, A2, A3, A4, A5, A6, A7, A8, A9), A10 == Absent, A11 == Absent, A12 == Absent {

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9) throws -> Output,
                               initialReturn: @autoclosure @escaping () throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: { _ in try initialReturn() }, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9) throws -> Output,
                               initialReturn: @escaping (Input) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9) throws -> Output,
                               initialReturn: InitialReturn<Input, Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension ThrowingFuncStub where Input == (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10), A11 == Absent, A12 == Absent {

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10) throws -> Output,
                               initialReturn: @autoclosure @escaping () throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: { _ in try initialReturn() }, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10) throws -> Output,
                               initialReturn: @escaping (Input) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10) throws -> Output,
                               initialReturn: InitialReturn<Input, Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension ThrowingFuncStub where Input == (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11), A12 == Absent {

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11) throws -> Output,
                               initialReturn: @autoclosure @escaping () throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: { _ in try initialReturn() }, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11) throws -> Output,
                               initialReturn: @escaping (Input) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11) throws -> Output,
                               initialReturn: InitialReturn<Input, Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension ThrowingFuncStub where Input == (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12) {

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12) throws -> Output,
                               initialReturn: @autoclosure @escaping () throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: { _ in try initialReturn() }, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12) throws -> Output,
                               initialReturn: @escaping (Input) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12) throws -> Output,
                               initialReturn: InitialReturn<Input, Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12) throws -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension ThrowingStubbedFunction where Input == Void, A1 == Absent, A2 == Absent, A3 == Absent, A4 == Absent, A5 == Absent, A6 == Absent, A7 == Absent,
                                A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt) throws -> Output) {
        replaceBody { counter, _ in try implementation(counter) }
    }

    public func addToBody(_ implementation: @escaping (UInt) throws -> Output) {
        appendBody { counter, _ in try implementation(counter) }
    }

    public func callAsFunction() throws -> Output {
        let input: Void = ()
        return try callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension ThrowingStubbedFunction where Input == A1, A2 == Absent, A3 == Absent, A4 == Absent, A5 == Absent, A6 == Absent, A7 == Absent,
                                A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt, A1) throws -> Output) {
        replaceBody { try implementation($0, $1) }
    }

    public func addToBody(_ implementation: @escaping (UInt, A1) throws -> Output) {
        appendBody { try implementation($0, $1) }
    }

    public func callAsFunction(_ a1: A1) throws -> Output {
        let input = a1
        return try callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension ThrowingStubbedFunction where Input == (A1, A2), A3 == Absent, A4 == Absent, A5 == Absent, A6 == Absent, A7 == Absent,
                                A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt, A1, A2) throws -> Output) {
        replaceBody { try implementation($0, $1.0, $1.1) }
    }

    public func addToBody(_ implementation: @escaping (UInt, A1, A2) throws -> Output) {
        appendBody { try implementation($0, $1.0, $1.1) }
    }

    public func callAsFunction(_ a1: A1, _ a2: A2) throws -> Output {
        let input = (a1, a2)
        return try callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension ThrowingStubbedFunction where Input == (A1, A2, A3), A4 == Absent, A5 == Absent, A6 == Absent, A7 == Absent,
                                A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt, A1, A2, A3) throws -> Output) {
        replaceBody { try implementation($0, $1.0, $1.1, $1.2) }
    }

    public func addToBody(_ implementation: @escaping (UInt, A1, A2, A3) throws -> Output) {
        appendBody { try implementation($0, $1.0, $1.1, $1.2) }
    }

    public func callAsFunction(_ a1: A1, _ a2: A2, _ a3: A3) throws -> Output {
        let input = (a1, a2, a3)
        return try callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension ThrowingStubbedFunction where Input == (A1, A2, A3, A4), A5 == Absent, A6 == Absent, A7 == Absent,
                                A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt, A1, A2, A3, A4) throws -> Output) {
        replaceBody { try implementation($0, $1.0, $1.1, $1.2, $1.3) }
    }

    public func addToBody(_ implementation: @escaping (UInt, A1, A2, A3, A4) throws -> Output) {
        appendBody { try implementation($0, $1.0, $1.1, $1.2, $1.3) }
    }

    public func callAsFunction(_ a1: A1, _ a2: A2, _ a3: A3, _ a4: A4) throws -> Output {
        let input = (a1, a2, a3, a4)
        return try callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension ThrowingStubbedFunction where Input == (A1, A2, A3, A4, A5), A6 == Absent, A7 == Absent,
                                A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5) throws -> Output) {
        replaceBody { try implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4) }
    }

    public func addToBody(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5) throws -> Output) {
        appendBody { try implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4) }
    }

    public func callAsFunction(_ a1: A1, _ a2: A2, _ a3: A3, _ a4: A4, _ a5: A5) throws -> Output {
        let input = (a1, a2, a3, a4, a5)
        return try callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension ThrowingStubbedFunction where Input == (A1, A2, A3, A4, A5, A6),
                                A7 == Absent, A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5, A6) throws -> Output) {
        replaceBody { try implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5) }
    }

    public func addToBody(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5, A6) throws -> Output) {
        appendBody { try implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5) }
    }

    public func callAsFunction(_ a1: A1, _ a2: A2, _ a3: A3, _ a4: A4, _ a5: A5, _ a6: A6) throws -> Output {
        let input = (a1, a2, a3, a4, a5, a6)
        return try callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension ThrowingStubbedFunction where Input == (A1, A2, A3, A4, A5, A6, A7),
                                A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5, A6, A7) throws -> Output) {
        replaceBody { try implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6) }
    }

    public func addToBody(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5, A6, A7) throws -> Output) {
        appendBody { try implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6) }
    }

    public func callAsFunction(_ a1: A1, _ a2: A2, _ a3: A3, _ a4: A4, _ a5: A5, _ a6: A6, _ a7: A7) throws -> Output {
        let input = (a1, a2, a3, a4, a5, a6, a7)
        return try callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension ThrowingStubbedFunction where Input == (A1, A2, A3, A4, A5, A6, A7, A8), A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5, A6, A7, A8) throws -> Output) {
        replaceBody { try implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7) }
    }

    public func addToBody(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5, A6, A7, A8) throws -> Output) {
        appendBody { try implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7) }
    }

    public func callAsFunction(_ a1: A1, _ a2: A2, _ a3: A3, _ a4: A4, _ a5: A5, _ a6: A6, _ a7: A7, _ a8: A8) throws -> Output {
        let input = (a1, a2, a3, a4, a5, a6, a7, a8)
        return try callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension ThrowingStubbedFunction where Input == (A1, A2, A3, A4, A5, A6, A7, A8, A9), A10 == Absent, A11 == Absent, A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5, A6, A7, A8, A9) throws -> Output) {
        replaceBody { try implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8) }
    }

    public func addToBody(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5, A6, A7, A8, A9) throws -> Output) {
        appendBody { try implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8) }
    }

    public func callAsFunction(_ a1: A1, _ a2: A2, _ a3: A3, _ a4: A4, _ a5: A5, _ a6: A6, _ a7: A7, _ a8: A8, _ a9: A9) throws -> Output {
        let input = (a1, a2, a3, a4, a5, a6, a7, a8, a9)
        return try callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension ThrowingStubbedFunction where Input == (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10), A11 == Absent, A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10) throws -> Output) {
        replaceBody { try implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9) }
    }

    public func addToBody(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10) throws -> Output) {
        appendBody { try implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9) }
    }

    public func callAsFunction(
        _ a1: A1, _ a2: A2, _ a3: A3, _ a4: A4, _ a5: A5, _ a6: A6, _ a7: A7, _ a8: A8, _ a9: A9, _ a10: A10
    ) throws -> Output {
        let input = (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
        return try callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension ThrowingStubbedFunction where Input == (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11), A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11) throws -> Output) {
        replaceBody { try implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10) }
    }

    public func addToBody(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11) throws -> Output) {
        appendBody { try implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10) }
    }

    public func callAsFunction(
        _ a1: A1, _ a2: A2, _ a3: A3, _ a4: A4, _ a5: A5, _ a6: A6, _ a7: A7, _ a8: A8, _ a9: A9, _ a10: A10, _ a11: A11
    ) throws -> Output {
        let input = (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11)
        return try callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension ThrowingStubbedFunction where Input == (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12) {

    public func bodyIs(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12) throws -> Output) {
        replaceBody { try implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11) }
    }

    public func addToBody(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12) throws -> Output) {
        appendBody { try implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11) }
    }

    public func callAsFunction(
        _ a1: A1, _ a2: A2, _ a3: A3, _ a4: A4, _ a5: A5, _ a6: A6, _ a7: A7, _ a8: A8, _ a9: A9, _ a10: A10, _ a11: A11, _ a12: A12
    ) throws -> Output {
        let input = (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12)
        return try callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}
