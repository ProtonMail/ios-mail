// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Technologies AG and Proton Calendar.
//
// Proton Calendar is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Calendar is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Calendar. If not, see https://www.gnu.org/licenses/.

@testable import ProtonCoreEventsLoop
import Foundation

class TimerSchedulerSpy: TimerScheduler {

    func simulateTick() {
        addCalls.last?.timer.fire()
    }

    private(set) var addCalls: [(timer: Timer, mode: RunLoop.Mode)] = []

    // MARK: - TimerScheduler

    func add(_ timer: Timer, forMode mode: RunLoop.Mode) {
        addCalls.append((timer, mode))
    }

}