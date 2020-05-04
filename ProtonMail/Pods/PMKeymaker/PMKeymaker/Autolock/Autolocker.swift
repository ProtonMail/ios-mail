//
//  Autolocker.swift
//  Keymaker - Created on 23/10/2018.
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
import UIKit

public protocol SettingsProvider {
    var lockTime: AutolockTimeout { get }
}

public class Autolocker {
    // there is no need to persist this value anywhere except memory since we can not unlock the app automatically after relaunch (except NoneProtection case)
    private var autolockCountdownStart: SystemTime?
    private var userSettingsProvider: SettingsProvider
    
    public init(lockTimeProvider: SettingsProvider) {
        self.userSettingsProvider = lockTimeProvider
        
        NotificationCenter.default.addObserver(self, selector: #selector(systemClockCompromised), name: NSNotification.Name.NSSystemClockDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(systemClockCompromised), name: UIApplication.significantTimeChangeNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func systemClockCompromised() {
        guard self.autolockCountdownStart != nil else {
            return // no countdown running
        }
        SystemTime.updateTimeCanary()
        self.autolockCountdownStart = SystemTime.distantPast()
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
