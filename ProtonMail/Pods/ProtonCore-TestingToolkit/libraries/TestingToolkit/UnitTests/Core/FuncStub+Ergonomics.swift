extension FuncStub where Input == Void, A1 == Absent, A2 == Absent, A3 == Absent, A4 == Absent, A5 == Absent, A6 == Absent, A7 == Absent,
                         A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public convenience init<T>(_ prototype: (T) -> () -> Output,
                               initialReturn: @autoclosure @escaping () -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> () -> Output,
                               initialReturn: InitialReturn<Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> () -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension FuncStub where Input == A1, A2 == Absent, A3 == Absent, A4 == Absent, A5 == Absent, A6 == Absent, A7 == Absent,
                         A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public convenience init<T>(_ prototype: (T) -> (A1) -> Output,
                               initialReturn: @autoclosure @escaping () -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1) -> Output,
                               initialReturn: InitialReturn<Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1) -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension FuncStub where Input == (A1, A2), A3 == Absent, A4 == Absent, A5 == Absent, A6 == Absent, A7 == Absent,
                         A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2) -> Output,
                               initialReturn: @autoclosure @escaping () -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2) -> Output,
                               initialReturn: InitialReturn<Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1, A2) -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension FuncStub where Input == (A1, A2, A3), A4 == Absent, A5 == Absent, A6 == Absent, A7 == Absent,
                         A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3) -> Output,
                               initialReturn: @autoclosure @escaping () -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3) -> Output,
                               initialReturn: InitialReturn<Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1, A2, A3) -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension FuncStub where Input == (A1, A2, A3, A4), A5 == Absent, A6 == Absent, A7 == Absent,
                         A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4) -> Output,
                               initialReturn: @autoclosure @escaping () -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4) -> Output,
                               initialReturn: InitialReturn<Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1, A2, A3, A4) -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension FuncStub where Input == (A1, A2, A3, A4, A5), A6 == Absent, A7 == Absent,
                         A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5) -> Output,
                               initialReturn: @autoclosure @escaping () -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5) -> Output,
                               initialReturn: InitialReturn<Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1, A2, A3, A4, A5) -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension FuncStub where Input == (A1, A2, A3, A4, A5, A6), A7 == Absent, A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6) -> Output,
                               initialReturn: @autoclosure @escaping () -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6) -> Output,
                               initialReturn: InitialReturn<Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1, A2, A3, A4, A5, A6) -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension FuncStub where Input == (A1, A2, A3, A4, A5, A6, A7), A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7) -> Output,
                               initialReturn: @autoclosure @escaping () -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7) -> Output,
                               initialReturn: InitialReturn<Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1, A2, A3, A4, A5, A6, A7) -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension FuncStub where Input == (A1, A2, A3, A4, A5, A6, A7, A8), A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8) -> Output,
                               initialReturn: @autoclosure @escaping () -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8) -> Output,
                               initialReturn: InitialReturn<Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1, A2, A3, A4, A5, A6, A7, A8) -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension FuncStub where Input == (A1, A2, A3, A4, A5, A6, A7, A8, A9), A10 == Absent, A11 == Absent, A12 == Absent {

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9) -> Output,
                               initialReturn: @autoclosure @escaping () -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9) -> Output,
                               initialReturn: InitialReturn<Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9) -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension FuncStub where Input == (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10), A11 == Absent, A12 == Absent {

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10) -> Output,
                               initialReturn: @autoclosure @escaping () -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10) -> Output,
                               initialReturn: InitialReturn<Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10) -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension FuncStub where Input == (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11), A12 == Absent {

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11) -> Output,
                               initialReturn: @autoclosure @escaping () -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11) -> Output,
                               initialReturn: InitialReturn<Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11) -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension FuncStub where Input == (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12) {

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12) -> Output,
                               initialReturn: @autoclosure @escaping () -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: @escaping (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12) -> Output,
                               initialReturn: InitialReturn<Output>,
                               function: String = #function, line: UInt = #line, file: String = #filePath) {
        self.init(initialReturn: initialReturn, function: function, line: line, file: file)
    }

    public convenience init<T>(_ prototype: (T) -> (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12) -> Output,
                               function: String = #function, line: UInt = #line, file: String = #filePath) where Output == Void {
        self.init(function: function, line: line, file: file)
    }
}

extension StubbedFunction where Input == Void, A1 == Absent, A2 == Absent, A3 == Absent, A4 == Absent, A5 == Absent, A6 == Absent, A7 == Absent,
                                A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt) -> Output) {
        setBody { counter, _ in implementation(counter) }
    }

    public func callAsFunction() -> Output {
        let input: Void = ()
        return callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension StubbedFunction where Input == A1, A2 == Absent, A3 == Absent, A4 == Absent, A5 == Absent, A6 == Absent, A7 == Absent,
                                A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt, A1) -> Output) {
        setBody { implementation($0, $1) }
    }

    public func callAsFunction(_ a1: A1) -> Output {
        let input = a1
        return callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension StubbedFunction where Input == (A1, A2), A3 == Absent, A4 == Absent, A5 == Absent, A6 == Absent, A7 == Absent,
                                A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt, A1, A2) -> Output) {
        setBody { implementation($0, $1.0, $1.1) }
    }

    public func callAsFunction(_ a1: A1, _ a2: A2) -> Output {
        let input = (a1, a2)
        return callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension StubbedFunction where Input == (A1, A2, A3), A4 == Absent, A5 == Absent, A6 == Absent, A7 == Absent,
                                A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt, A1, A2, A3) -> Output) {
        setBody { implementation($0, $1.0, $1.1, $1.2) }
    }

    public func callAsFunction(_ a1: A1, _ a2: A2, _ a3: A3) -> Output {
        let input = (a1, a2, a3)
        return callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension StubbedFunction where Input == (A1, A2, A3, A4), A5 == Absent, A6 == Absent, A7 == Absent,
                                A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt, A1, A2, A3, A4) -> Output) {
        setBody { implementation($0, $1.0, $1.1, $1.2, $1.3) }
    }

    public func callAsFunction(_ a1: A1, _ a2: A2, _ a3: A3, _ a4: A4) -> Output {
        let input = (a1, a2, a3, a4)
        return callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension StubbedFunction where Input == (A1, A2, A3, A4, A5), A6 == Absent, A7 == Absent,
                                A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5) -> Output) {
        setBody { implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4) }
    }

    public func callAsFunction(_ a1: A1, _ a2: A2, _ a3: A3, _ a4: A4, _ a5: A5) -> Output {
        let input = (a1, a2, a3, a4, a5)
        return callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension StubbedFunction where Input == (A1, A2, A3, A4, A5, A6),
                                A7 == Absent, A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5, A6) -> Output) {
        setBody { implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5) }
    }

    public func callAsFunction(_ a1: A1, _ a2: A2, _ a3: A3, _ a4: A4, _ a5: A5, _ a6: A6) -> Output {
        let input = (a1, a2, a3, a4, a5, a6)
        return callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension StubbedFunction where Input == (A1, A2, A3, A4, A5, A6, A7),
                                A8 == Absent, A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5, A6, A7) -> Output) {
        setBody { implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6) }
    }

    public func callAsFunction(_ a1: A1, _ a2: A2, _ a3: A3, _ a4: A4, _ a5: A5, _ a6: A6, _ a7: A7) -> Output {
        let input = (a1, a2, a3, a4, a5, a6, a7)
        return callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension StubbedFunction where Input == (A1, A2, A3, A4, A5, A6, A7, A8), A9 == Absent, A10 == Absent, A11 == Absent, A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5, A6, A7, A8) -> Output) {
        setBody { implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7) }
    }

    public func callAsFunction(_ a1: A1, _ a2: A2, _ a3: A3, _ a4: A4, _ a5: A5, _ a6: A6, _ a7: A7, _ a8: A8) -> Output {
        let input = (a1, a2, a3, a4, a5, a6, a7, a8)
        return callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension StubbedFunction where Input == (A1, A2, A3, A4, A5, A6, A7, A8, A9), A10 == Absent, A11 == Absent, A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5, A6, A7, A8, A9) -> Output) {
        setBody { implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8) }
    }

    public func callAsFunction(_ a1: A1, _ a2: A2, _ a3: A3, _ a4: A4, _ a5: A5, _ a6: A6, _ a7: A7, _ a8: A8, _ a9: A9) -> Output {
        let input = (a1, a2, a3, a4, a5, a6, a7, a8, a9)
        return callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension StubbedFunction where Input == (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10), A11 == Absent, A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10) -> Output) {
        setBody { implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9) }
    }

    public func callAsFunction(_ a1: A1, _ a2: A2, _ a3: A3, _ a4: A4, _ a5: A5, _ a6: A6, _ a7: A7, _ a8: A8, _ a9: A9, _ a10: A10) -> Output {
        let input = (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
        return callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension StubbedFunction where Input == (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11), A12 == Absent {

    public func bodyIs(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11) -> Output) {
        setBody { implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10) }
    }

    public func callAsFunction(
        _ a1: A1, _ a2: A2, _ a3: A3, _ a4: A4, _ a5: A5, _ a6: A6, _ a7: A7, _ a8: A8, _ a9: A9, _ a10: A10, _ a11: A11
    ) -> Output {
        let input = (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11)
        return callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}

extension StubbedFunction where Input == (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12) {

    public func bodyIs(_ implementation: @escaping (UInt, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12) -> Output) {
        setBody { implementation($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11) }
    }

    public func callAsFunction(
        _ a1: A1, _ a2: A2, _ a3: A3, _ a4: A4, _ a5: A5, _ a6: A6, _ a7: A7, _ a8: A8, _ a9: A9, _ a10: A10, _ a11: A11, _ a12: A12
    ) -> Output {
        let input = (a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12)
        return callAsFunction(input: input, arguments: CapturedArguments(input: input))
    }
}
