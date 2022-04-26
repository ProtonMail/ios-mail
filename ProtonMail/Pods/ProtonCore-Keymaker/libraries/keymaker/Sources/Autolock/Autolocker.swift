//
//  Autolocker.swift
//  ProtonCore-Keymaker - Created on 23/10/2018.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

#if canImport(UIKit)
import UIKit
#endif

public protocol SettingsProvider {
    var lockTime: AutolockTimeout { get }
}

protocol TimeProvider {
    var date: Date { get }
    var deviceUptime: TimeInterval { get }
}

struct AutolockerTimeProvider: TimeProvider {
    var date: Date { Date() }
    var deviceUptime: TimeInterval {
        do {
            let time = try Clock.deviceUptime()
            return TimeInterval(time.tv_sec)
        } catch {
            // `ProcessInfo().systemUptime` does not return the time since the device
            // booted. When the device goes to sleep `systemUptime` does not get updated.
            return ProcessInfo().systemUptime
        }
    }
}

public class Autolocker {
    private var countdownStartedAt: Date?
    private var countdownStartedAtUptime: TimeInterval?
    private var userSettingsProvider: SettingsProvider
    private var timeProvider: TimeProvider
    
    private var secondsSinceCountdownStarted: TimeInterval? {
        guard let countdownStartedAt = countdownStartedAt else {
            return nil
        }
        return timeProvider.date.timeIntervalSince(countdownStartedAt)
    }
    
    private var secondsSinceCountdownUptime: TimeInterval? {
        guard let countdownStartedAtUptime = countdownStartedAtUptime else {
            return nil
        }
        return timeProvider.deviceUptime - countdownStartedAtUptime
    }

    private var hasCountdownStarted: Bool {
        countdownStartedAt != nil
    }

    init(lockTimeProvider: SettingsProvider, timeProvider: TimeProvider) {
        self.userSettingsProvider = lockTimeProvider
        self.timeProvider = timeProvider
    }

    public convenience init(lockTimeProvider: SettingsProvider) {
        self.init(lockTimeProvider: lockTimeProvider, timeProvider: AutolockerTimeProvider())
    }
    
    /// Asks to register the moment we start the countdown for the autolock
    func startCountdown() {
        countdownStartedAt = timeProvider.date
        countdownStartedAtUptime = timeProvider.deviceUptime
    }
    
    /// Disables the countdown
    func releaseCountdown() {
        countdownStartedAt = nil
        countdownStartedAtUptime = nil
    }
    
    func shouldAutolockNow() -> Bool {
        guard hasCountdownStarted else { return false }

        switch userSettingsProvider.lockTime {
        case .always:
            return true
        case .never:
            return false
        case .minutes(let numberOfMinutes):
            return shouldAutolockIfTimeElapsed(minutes: numberOfMinutes) || hasTimeBeenTampered()
        }
    }
    
    /// Returns `true` if the number of minutes elapsed since countdown started is higher than the minutes passed as parameter.
    private func shouldAutolockIfTimeElapsed(minutes: Int) -> Bool {
        guard let secondsSinceCountdownStarted = secondsSinceCountdownStarted else {
            return false
        }
        let secondsToPassForAutolock = TimeInterval(minutes * 60)
        return secondsSinceCountdownStarted > secondsToPassForAutolock
    }
    
    /// Returns `true` if determines the device date/time has been modified trying to bypass the autolock feature.
    ///
    /// The way to detect tampering is based on these scenarios:
    ///
    /// 1. It makes sure the current date is not before the date when the countdown started (in case the uptime is not available).
    /// 2. If the current date is after the countdown start date, checks that the uptime and the date differences are similar.
    private func hasTimeBeenTampered() -> Bool {
        guard let secondsSinceCountdownStarted = secondsSinceCountdownStarted,
                let secondsSinceCountdownUptime = secondsSinceCountdownUptime else {
                    return false
                }
        let dateOlderThanCountdownStart = secondsSinceCountdownStarted < 0
        let allowedDifferenceInSeconds = TimeInterval(2)
        let uptimeAndDateDoNotMatch = abs(secondsSinceCountdownUptime - secondsSinceCountdownStarted) > allowedDifferenceInSeconds
        return dateOlderThanCountdownStart || uptimeAndDateDoNotMatch
    }
}
