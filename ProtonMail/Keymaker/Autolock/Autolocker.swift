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
    private var timer: Timer!
    private var autolockCountdownStart: SystemTime?
    
    private var userSettingsProvider: SettingsProvider
    
    public init(lockTimeProvider: SettingsProvider) {
        self.userSettingsProvider = lockTimeProvider
        
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateSystemTimeCanary), userInfo: nil, repeats: true)
    
        NotificationCenter.default.addObserver(self, selector: #selector(systemClockCompromised), name: NSNotification.Name.NSSystemClockDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(systemClockCompromised), name: UIApplication.significantTimeChangeNotification, object: nil)
    }
    
    deinit {
        self.timer.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func systemClockCompromised() {
        guard let _ = self.autolockCountdownStart else {
            return // no countdown running
        }
        self.autolockCountdownStart = SystemTime.distantPast()
    }
    
    @objc private func updateSystemTimeCanary() {
        // SystemTime do not participate in objc runtime, so we're running timer via Autolocker
        SystemTime.updateTimeCanary()
    }
    
    internal func updateAutolockCountdownStart() {
        self.autolockCountdownStart = SystemTime.pureCurrent()
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
            do {
                let current = try SystemTime.validCurrent()
                return TimeInterval(numberOfMinutes * 60) < current.timeIntervalSince(lastBackgroundedAt)
            } catch _ {
                return true
            }
        }
    }
}
