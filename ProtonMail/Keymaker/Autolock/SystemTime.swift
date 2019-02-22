//
//  SystemTime.swift
//  ProtonMail - Created on 22/02/2019.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

import Foundation

struct SystemTime {
    enum Errors: Error {
        case systemTimeCompromised
    }
    private static var lastCheckedSystemTime: SystemTime = SystemTime.distantPast()
    let clock: Date
    let uptime: TimeInterval
    
    static func updateTimeCanary() {
        let _ = self.pureCurrent()
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
