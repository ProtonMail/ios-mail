//
//  Autolocker.swift
//  Keymaker
//
//  Created by Anatoly Rosencrantz on 23/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

public protocol SettingsProvider {
    var lockTime: AutolockTimeout { get }
}

public class Autolocker {
    // there is no need to persist this value anywhere except memory since we can not unlock the app automatically after relaunch (except NoneProtection case)
    // by the same reason we can benefit from system uptime value instead of current Date which can be played with in Settings.app
    internal var autolockCountdownStart: TimeInterval?
    private var userSettingsProvider: SettingsProvider
    
    public init(lockTimeProvider: SettingsProvider) {
        self.userSettingsProvider = lockTimeProvider
    }
    
    internal func updateAutolockCountdownStart() {
        self.autolockCountdownStart = ProcessInfo().systemUptime
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
            return TimeInterval(numberOfMinutes * 60) < ProcessInfo().systemUptime - lastBackgroundedAt
        }
    }
}
