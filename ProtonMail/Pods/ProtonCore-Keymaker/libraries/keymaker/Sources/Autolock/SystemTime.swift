//
//  SystemTime.swift
//  ProtonMail - Created on 22/02/2019.
//
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
    
import Foundation

struct SystemTime {
    enum Errors: Error {
        case systemTimeCompromised
    }
    private static var timer: Timer!
    private static var lastCheckedSystemTime: SystemTime = {
        let initial = SystemTime.distantPast()
        SystemTime.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            SystemTime.updateTimeCanary()
        }
        return initial
    }()
    
    let clock: Date
    let uptime: TimeInterval
    
    static func updateTimeCanary() {
        _ = self.pureCurrent()
    }
    
    static func validCurrent() throws -> SystemTime {
        let last = self.lastCheckedSystemTime
        let current = self.pureCurrent()
        
        if current.isIllegal(comparedTo: last) {
            throw Errors.systemTimeCompromised
        }
        
        return current
    }
    static func pureCurrent() -> SystemTime {
        let current = SystemTime(clock: Date(), uptime: ProcessInfo().systemUptime)
        self.lastCheckedSystemTime = current
        return current
    }
    
    // misalignment between uptime and clock deltas can only happen if someone was playing with device time settings while app was suspended (hence not was not able to get NSSystemClockDidChange notification)
    private func isIllegal(comparedTo older: SystemTime) -> Bool {
        // we want to be sure clock and uptime were not moving backwards
        guard case let clockDelta = self.clock.timeIntervalSince(older.clock),
            clockDelta > 0,
            case let uptimeDelta = (self.uptime - older.uptime),
            uptimeDelta > 0 else
        {
            return true
        }
        
        // uptimeDelta can be legally less than clockDelta if device was asleep while app was suspended. uptimeDelta can be legally equal if device was not sleeping at all. but if uptimeDelta (hence number of seconds device was working) is higher than clockDelta (hence number of seconds system clock ticked since our last check) - someone was playing with system clock and that is illegal
        return uptimeDelta.rounded(.down) > clockDelta.rounded(.down)
    }
}

extension SystemTime { // Date-like methods
    static func distantFuture() -> SystemTime {
        return SystemTime(clock: Date.distantFuture, uptime: Date.distantFuture.timeIntervalSince1970)
    }
    static func distantPast() -> SystemTime {
        return SystemTime(clock: Date.distantPast, uptime: Date.distantPast.timeIntervalSince1970)
    }
    func timeIntervalSince(_ older: SystemTime) -> TimeInterval {
        return self.clock.timeIntervalSince(older.clock)
    }
}
