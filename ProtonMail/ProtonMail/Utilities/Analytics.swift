//
//  Analytics.swift
//  ProtonMail - Created on 30/11/2018.
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
import Sentry

class Analytics {
    typealias Event = Sentry.Event
    static var shared = Analytics()
    
    private var sentryEndpoint: String {
        #if Enterprise
            return ObfuscatedConstants.Sentry.enterprise
        #else
            return ObfuscatedConstants.Sentry.live
        #endif
    }
    
    
    func setup() {
        do {
            Client.shared = try Client(dsn: self.sentryEndpoint)
            try Client.shared?.startCrashHandler()
        } catch let error {
            PMLog.D("Error starting Sentry: \(error)")
        }
    }
    
    func logCustomEvent(customAttributes: Dictionary<String, Any>) {
        Client.shared?.snapshotStacktrace {
            let event = Event(level: .debug)
            event.message = customAttributes.json()
            Client.shared?.send(event: event)
        }
    }
    
    func recordError(_ error: NSError) {
        Client.shared?.snapshotStacktrace {
            let event = Event(level: .error)
            event.message = error.localizedDescription
            Client.shared?.appendStacktrace(to: event)
            Client.shared?.send(event: event)
        }
    }
}
