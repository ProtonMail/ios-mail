//
//  CapturedArguments.swift
//  ProtonCore-TestingToolkit
//
//  Created by Krzysztof Siejkowski on 27/05/2021.
//

import Foundation

public struct CapturedArguments<Input, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12> {

    private let argument1: A1
    private let argument2: A2
    private let argument3: A3
    private let argument4: A4
    private let argument5: A5
    private let argument6: A6
    private let argument7: A7
    private let argument8: A8
    private let argument9: A9
    private let argument10: A10
    private let argument11: A11
    private let argument12: A12

    private init(a1: A1, a2: A2, a3: A3, a4: A4, a5: A5, a6: A6, a7: A7, a8: A8, a9: A9, a10: A10, a11: A11, a12: A12) {
        self.argument1 = a1
        self.argument2 = a2
        self.argument3 = a3
        self.argument4 = a4
        self.argument5 = a5
        self.argument6 = a6
        self.argument7 = a7
        self.argument8 = a8
        self.argument9 = a9
        self.argument10 = a10
        self.argument11 = a11
        self.argument12 = a12
    }
}

extension CapturedArguments: Equatable where A1: Equatable, A2: Equatable, A3: Equatable, A4: Equatable, A5: Equatable, A6: Equatable,
                                             A7: Equatable, A8: Equatable, A9: Equatable, A10: Equatable, A11: Equatable, A12: Equatable {}

extension CapturedArguments: Codable where A1: Codable, A2: Codable, A3: Codable, A4: Codable, A5: Codable, A6: Codable,
                                           A7: Codable, A8: Codable, A9: Codable, A10: Codable, A11: Codable, A12: Codable {}

extension CapturedArguments where Input == Void, A1 == Absent, A2 == Absent, A3 == Absent, A4 == Absent, A5 == Absent, A6 == Absent, A7 == Absent,
                                  A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    init(input _: Input) {
        self.init(a1: .nothing, a2: .nothing, a3: .nothing, a4: .nothing, a5: .nothing, a6: .nothing,
                  a7: .nothing, a8: .nothing, a9: .nothing, a10: .nothing, a11: .nothing, a12: .nothing)
    }
}

extension CapturedArguments where Input == A1, A2 == Absent, A3 == Absent, A4 == Absent, A5 == Absent, A6 == Absent, A7 == Absent,
                                  A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public var a1: A1 { argument1 }

    public var value: A1 { a1 }

    init(input: Input) {
        self.init(a1: input, a2: .nothing, a3: .nothing, a4: .nothing, a5: .nothing, a6: .nothing,
                  a7: .nothing, a8: .nothing, a9: .nothing, a10: .nothing, a11: .nothing, a12: .nothing)
    }
}

extension CapturedArguments where Input == (A1, A2), A3 == Absent, A4 == Absent, A5 == Absent, A6 == Absent, A7 == Absent,
                                  A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public var a1: A1 { argument1 }
    public var a2: A2 { argument2 }

    public var first: A1 { a1 }
    public var second: A2 { a2 }

    init(input: Input) {
        self.init(a1: input.0, a2: input.1, a3: .nothing, a4: .nothing, a5: .nothing, a6: .nothing,
                  a7: .nothing, a8: .nothing, a9: .nothing, a10: .nothing, a11: .nothing, a12: .nothing)
    }
}

extension CapturedArguments where Input == (A1, A2, A3), A4 == Absent, A5 == Absent, A6 == Absent, A7 == Absent,
                                  A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public var a1: A1 { argument1 }
    public var a2: A2 { argument2 }
    public var a3: A3 { argument3 }

    public var first: A1 { a1 }
    public var second: A2 { a2 }
    public var third: A3 { a3 }

    init(input: Input) {
        self.init(a1: input.0, a2: input.1, a3: input.2, a4: .nothing, a5: .nothing, a6: .nothing,
                  a7: .nothing, a8: .nothing, a9: .nothing, a10: .nothing, a11: .nothing, a12: .nothing)
    }
}

extension CapturedArguments where Input == (A1, A2, A3, A4), A5 == Absent, A6 == Absent, A7 == Absent,
                                  A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public var a1: A1 { argument1 }
    public var a2: A2 { argument2 }
    public var a3: A3 { argument3 }
    public var a4: A4 { argument4 }

    public var first: A1 { a1 }
    public var second: A2 { a2 }
    public var third: A3 { a3 }
    public var forth: A4 { a4 }

    init(input: Input) {
        self.init(a1: input.0, a2: input.1, a3: input.2, a4: input.3, a5: .nothing, a6: .nothing,
                  a7: .nothing, a8: .nothing, a9: .nothing, a10: .nothing, a11: .nothing, a12: .nothing)
    }
}

extension CapturedArguments where Input == (A1, A2, A3, A4, A5), A6 == Absent, A7 == Absent,
                                  A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public var a1: A1 { argument1 }
    public var a2: A2 { argument2 }
    public var a3: A3 { argument3 }
    public var a4: A4 { argument4 }
    public var a5: A5 { argument5 }

    public var first: A1 { a1 }
    public var last: A5 { a5 }

    init(input: Input) {
        self.init(a1: input.0, a2: input.1, a3: input.2, a4: input.3, a5: input.4, a6: .nothing,
                  a7: .nothing, a8: .nothing, a9: .nothing, a10: .nothing, a11: .nothing, a12: .nothing)
    }
}

extension CapturedArguments where Input == (A1, A2, A3, A4, A5, A6), A7 == Absent,
                                  A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public var a1: A1 { argument1 }
    public var a2: A2 { argument2 }
    public var a3: A3 { argument3 }
    public var a4: A4 { argument4 }
    public var a5: A5 { argument5 }
    public var a6: A6 { argument6 }

    public var first: A1 { a1 }
    public var last: A6 { a6 }

    init(input: Input) {
        self.init(a1: input.0, a2: input.1, a3: input.2, a4: input.3, a5: input.4, a6: input.5,
                  a7: .nothing, a8: .nothing, a9: .nothing, a10: .nothing, a11: .nothing, a12: .nothing)
    }
}

extension CapturedArguments where Input == (A1, A2, A3, A4, A5, A6, A7),
                                  A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public var a1: A1 { argument1 }
    public var a2: A2 { argument2 }
    public var a3: A3 { argument3 }
    public var a4: A4 { argument4 }
    public var a5: A5 { argument5 }
    public var a6: A6 { argument6 }
    public var a7: A7 { argument7 }

    public var first: A1 { a1 }
    public var last: A7 { a7 }

    init(input: Input) {
        self.init(a1: input.0, a2: input.1, a3: input.2, a4: input.3, a5: input.4, a6: input.5,
                  a7: input.6, a8: .nothing, a9: .nothing, a10: .nothing, a11: .nothing, a12: .nothing)
    }
}

extension CapturedArguments where Input == (A1, A2, A3, A4, A5, A6, A7, A8), A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public var a1: A1 { argument1 }
    public var a2: A2 { argument2 }
    public var a3: A3 { argument3 }
    public var a4: A4 { argument4 }
    public var a5: A5 { argument5 }
    public var a6: A6 { argument6 }
    public var a7: A7 { argument7 }
    public var a8: A8 { argument8 }

    public var first: A1 { a1 }
    public var last: A8 { a8 }

    init(input: Input) {
        self.init(a1: input.0, a2: input.1, a3: input.2, a4: input.3, a5: input.4, a6: input.5,
                  a7: input.6, a8: input.7, a9: .nothing, a10: .nothing, a11: .nothing, a12: .nothing)
    }
}

extension CapturedArguments where Input == (A1, A2, A3, A4, A5, A6, A7, A8, A9), A10 == Absent, A11 == Absent, A12 == Absent {

    public var a1: A1 { argument1 }
    public var a2: A2 { argument2 }
    public var a3: A3 { argument3 }
    public var a4: A4 { argument4 }
    public var a5: A5 { argument5 }
    public var a6: A6 { argument6 }
    public var a7: A7 { argument7 }
    public var a8: A8 { argument8 }
    public var a9: A9 { argument9 }

    public var first: A1 { a1 }
    public var last: A9 { a9 }

    init(input: Input) {
        self.init(a1: input.0, a2: input.1, a3: input.2, a4: input.3, a5: input.4, a6: input.5,
                  a7: input.6, a8: input.7, a9: input.8, a10: .nothing, a11: .nothing, a12: .nothing)
    }
}

extension CapturedArguments where Input == (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10), A11 == Absent, A12 == Absent {

    public var a1: A1 { argument1 }
    public var a2: A2 { argument2 }
    public var a3: A3 { argument3 }
    public var a4: A4 { argument4 }
    public var a5: A5 { argument5 }
    public var a6: A6 { argument6 }
    public var a7: A7 { argument7 }
    public var a8: A8 { argument8 }
    public var a9: A9 { argument9 }
    public var a10: A10 { argument10 }

    public var first: A1 { a1 }
    public var last: A10 { a10 }

    init(input: Input) {
        self.init(a1: input.0, a2: input.1, a3: input.2, a4: input.3, a5: input.4, a6: input.5,
                  a7: input.6, a8: input.7, a9: input.8, a10: input.9, a11: .nothing, a12: .nothing)
    }
}

extension CapturedArguments where Input == (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11), A12 == Absent {

    public var a1: A1 { argument1 }
    public var a2: A2 { argument2 }
    public var a3: A3 { argument3 }
    public var a4: A4 { argument4 }
    public var a5: A5 { argument5 }
    public var a6: A6 { argument6 }
    public var a7: A7 { argument7 }
    public var a8: A8 { argument8 }
    public var a9: A9 { argument9 }
    public var a10: A10 { argument10 }
    public var a11: A11 { argument11 }

    public var first: A1 { a1 }
    public var last: A11 { a11 }

    init(input: Input) {
        self.init(a1: input.0, a2: input.1, a3: input.2, a4: input.3, a5: input.4, a6: input.5,
                  a7: input.6, a8: input.7, a9: input.8, a10: input.9, a11: input.10, a12: .nothing)
    }
}

extension CapturedArguments where Input == (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12) {

    public var a1: A1 { argument1 }
    public var a2: A2 { argument2 }
    public var a3: A3 { argument3 }
    public var a4: A4 { argument4 }
    public var a5: A5 { argument5 }
    public var a6: A6 { argument6 }
    public var a7: A7 { argument7 }
    public var a8: A8 { argument8 }
    public var a9: A9 { argument9 }
    public var a10: A10 { argument10 }
    public var a11: A11 { argument11 }
    public var a12: A12 { argument12 }

    public var first: A1 { a1 }
    public var last: A12 { a12 }

    init(input: Input) {
        self.init(a1: input.0, a2: input.1, a3: input.2, a4: input.3, a5: input.4, a6: input.5,
                  a7: input.6, a8: input.7, a9: input.8, a10: input.9, a11: input.10, a12: input.11)
    }
}
