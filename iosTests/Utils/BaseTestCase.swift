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

@testable import ProtonMail
import XCTest

class BaseTestCase: XCTestCase {

    private var originalDispatchOnMain: ((DispatchWorkItem) -> Void)!
    private var originalDispatchOnMainAfter: Dispatcher.DispatchAfterType!
    private var original_swift_task_enqueueGlobal_hook: ConcurrencyEnvironment.Hook!
    private var originalCalendar: Calendar!

    override func setUp() {
        super.setUp()

        originalDispatchOnMain = Dispatcher.dispatchOnMain
        originalDispatchOnMainAfter = Dispatcher.dispatchOnMainAfter
        original_swift_task_enqueueGlobal_hook = ConcurrencyEnvironment.swift_task_enqueueGlobal_hook
        originalCalendar = DateEnvironment.calendar

        Dispatcher.dispatchOnMain = { task in task.perform() }
        Dispatcher.dispatchOnMainAfter = { _, task in task.perform() }
        ConcurrencyEnvironment.swift_task_enqueueGlobal_hook = { job, _ in
            TestExecutor.shared.enqueue(job)
        }
        DateEnvironment.calendar = .warsawEnUS
    }

    override func tearDown() {
        Dispatcher.dispatchOnMain = originalDispatchOnMain
        Dispatcher.dispatchOnMainAfter = originalDispatchOnMainAfter
        ConcurrencyEnvironment.swift_task_enqueueGlobal_hook = original_swift_task_enqueueGlobal_hook
        DateEnvironment.calendar = originalCalendar

        originalDispatchOnMain = nil
        originalDispatchOnMainAfter = nil
        original_swift_task_enqueueGlobal_hook = nil
        originalCalendar = nil

        super.tearDown()
    }

}

private final class TestExecutor: SerialExecutor {
    static let shared = TestExecutor()

    func enqueue(_ job: consuming ExecutorJob) {
        job.runSynchronously(on: asUnownedSerialExecutor())
    }

    func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }
}

private extension Calendar {
    static var warsawEnUS: Self {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Warsaw").unsafelyUnwrapped
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }
}
