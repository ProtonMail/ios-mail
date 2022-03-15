//
//  ViewModelBase.swift
//  ProtonMail - Created on 2/22/18.
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

// logging for view model could merge with timer
class ViewModelBase: NSObject {

    private var debugInfo: [String] = []
    private var logging: Bool = false

    func start(_ initLog: String) {
        self.debugInfo.removeAll()
        self.debugInfo.append(initLog)
        self.logging = true
    }

    func log(_ log: String) {
        if self.logging {
            self.debugInfo.append(log)
        }
    }

    func end(_ endLog: String) {
        self.debugInfo.append(endLog)
        self.logging = false
    }

    var logs: String {
        get {
            return debugInfo.joined(separator: "\r\n")
        }
    }
}
