//
//  Autolocker.swift
//  Keymaker - Created on 23/10/2018.
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

public protocol SettingsProvider {
    var lockTime: AutolockTimeout { get }
}

public class Autolocker {
    // there is no need to persist this value anywhere except memory since we can not unlock the app automatically after relaunch (except NoneProtection case)
    // 
    private var lastCheckedSystemUptime: TimeInterval
    private var lastCheckedSystemClock: Date
    private var timer: Timer!
    
    private var autolockCountdownStart: TimeInterval?
    
    private var userSettingsProvider: SettingsProvider
    
    public init(lockTimeProvider: SettingsProvider) {
        self.userSettingsProvider = lockTimeProvider
        
        self.lastCheckedSystemClock = Date()
        self.lastCheckedSystemUptime = ProcessInfo().systemUptime
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateSystemTimers), userInfo: nil, repeats: true)
    
        NotificationCenter.default.addObserver(self, selector: #selector(systemClockCompromised), name: NSNotification.Name.NSSystemClockDidChange, object: nil)
    }
    
    deinit {
        self.timer.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func systemClockCompromised() {
        guard let _ = self.autolockCountdownStart else {
            return // no autolocker
        }
        self.autolockCountdownStart = Date.distantPast.timeIntervalSince1970
        self.updateSystemTimers()
    }
    
    @objc private func updateSystemTimers() {
        self.lastCheckedSystemClock = Date()
        self.lastCheckedSystemUptime = ProcessInfo().systemUptime
    }
    
    private func currentTime() -> TimeInterval {
        let systemClock = Date()
        let systemUptime = ProcessInfo().systemUptime
        
        // misalignment between uptime and clock deltas can only happen if someone was playing with device time settings while app was suspended and was not able to get NSSystemClockDidChange notification
        if systemClock.timeIntervalSince(self.lastCheckedSystemClock).rounded(.down) < (systemUptime - self.lastCheckedSystemUptime).rounded(.down) {
            self.systemClockCompromised()
            return Date.distantFuture.timeIntervalSince1970
        }
        
        return systemClock.timeIntervalSince1970
    }
    
    internal func updateAutolockCountdownStart() {
        self.autolockCountdownStart = self.currentTime()
    }
    
    internal func releaseCountdown() {
        self.autolockCountdownStart = nil
    }
    
    internal func shouldAutolockNow() -> Bool {
        // no countdown started - no need to lock
        guard let lastBackgroundedAt = self.autolockCountdownStart else {
            return false
        }
        
        switch self.userSettingsProvider.lockTime {
        case .always: return true
        case .never: return false
        case .minutes(let numberOfMinutes):
            return TimeInterval(numberOfMinutes * 60) < self.currentTime() - lastBackgroundedAt
        }
    }
}
