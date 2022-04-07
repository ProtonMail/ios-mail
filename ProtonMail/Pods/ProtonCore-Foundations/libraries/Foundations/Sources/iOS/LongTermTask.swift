//
//  LongTermTask.swift
//  ProtonCore-Foundations - Created on 01.02.22.
//
//  Copyright (c) 2020 Proton Technologies AG
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
import UIKit
import ProtonCore_Log

public class LongTermTask {
    
    private let timeout = 20
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    public var inProgress = false {
        didSet {
            if oldValue == true, inProgress == false {
                finishLongTermTask()
            }
        }
    }
    
    public init() {
        setupObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        finishLongTermTask()
    }
    
    private func setupObservers() {
        NotificationCenter.default.removeObserver(self)
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc private func appMovedToBackground() {
        if inProgress {
            scheduleLongTermTask()
        }
    }
    
    private func scheduleLongTermTask() {
        finishLongTermTask()
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.finishLongTermTask()
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(timeout)) { [weak self] in
            self?.finishLongTermTask()
        }
        PMLog.debug("Schedule background task: \(self.backgroundTaskID)")
    }
    
    private func finishLongTermTask() {
        if backgroundTaskID == .invalid { return }
        PMLog.debug("End background task: \(backgroundTaskID)")
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
    }
}
