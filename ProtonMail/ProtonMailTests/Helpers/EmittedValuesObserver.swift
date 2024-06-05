// Copyright (c) 2024 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Combine

/// Use this class when `AsyncPublisher.Iterator.next()` does not remember past values.
final class EmittedValuesObserver<T> {
    private var cancellable: AnyCancellable!
    private var continuationsWaitingForNextValue: [CheckedContinuation<T, Never>] = []
    private var elementsQueuedToBeRead: [T] = []

    init(observing publisher: AnyPublisher<T, Never>) {
        cancellable = publisher.sink { [unowned self] in
            if !continuationsWaitingForNextValue.isEmpty {
                for continuation in continuationsWaitingForNextValue {
                    continuation.resume(returning: $0)
                }

                continuationsWaitingForNextValue.removeAll()
            } else {
                self.elementsQueuedToBeRead.append($0)
            }
        }
    }

    var hasPendingUnreadValues: Bool {
        !elementsQueuedToBeRead.isEmpty
    }

    func next() async -> T {
        if !elementsQueuedToBeRead.isEmpty {
            return elementsQueuedToBeRead.removeFirst()
        } else {
            return await withCheckedContinuation { continuation in
                continuationsWaitingForNextValue.append(continuation)
            }
        }
    }
}

extension EmittedValuesObserver where T: Equatable {
    func expectNextValue(toBe expected: T, file: StaticString = #filePath, line: UInt = #line) async {
        let nextValue = await next()
        XCTAssertEqual(nextValue, expected, file: file, line: line)
    }
}
