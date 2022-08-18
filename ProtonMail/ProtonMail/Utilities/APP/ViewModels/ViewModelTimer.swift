//
//  ViewModelTimer.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

//Timer for view model could merge with Base
class ViewModelTimer: NSObject {
    
    private var timer : Timer?
    private var fetchingStopped : Bool = true
    
    // MARK: - Private methods
    func setupTimer(_ run: Bool = true, timerInterval: TimeInterval = 30) {
        self.timer = Timer.scheduledTimer(timeInterval: timerInterval,
                                          target: self,
                                          selector: #selector(timerAction),
                                          userInfo: nil,
                                          repeats: true)
        fetchingStopped = false
        if run {
            self.timer?.fire()
        }
    }

    func stopTimer() {
        fetchingStopped = true
        if let t = self.timer {
            t.invalidate()
            self.timer = nil
        }
    }

    @objc private func timerAction() {
        if !fetchingStopped {
            self.fireFetch()
        }
    }

    func fireFetch() {
        fatalError("This method must be overridden")
    }
}
