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
            return "https://3f5b27555fa64b519002266dcdc7744c@api.protonmail.ch/reports/sentry/25"
        #else
            return "https://bcbe8b2a026848c4b139df228d088072@api.protonmail.ch/reports/sentry/7"
        #endif
    }
    
    func setup() {
        SentrySDK.start { (options) in
            options.dsn = self.sentryEndpoint
            #if DEBUG
            options.debug = true
            #endif
        }
    }
    
    func logCustomEvent(customAttributes: Dictionary<String, Any>, user: UserManager?=nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
        let event = Event(level: .debug)
        let append = "\((file as NSString).lastPathComponent) : \(function) : \(line) : \(column)"
        event.message = "\(append) - \(customAttributes.json())"
        event.user = self.getUsesr()
        SentrySDK.capture(event: event)
    }
    
    func recordError(_ error: NSError, user: UserManager?=nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
        let event = Event(level: .error)
        let append = "\((file as NSString).lastPathComponent) : \(function) : \(line) : \(column)"
        event.message = "\(append) - \(error.localizedDescription)"
        event.user = self.getUsesr()
        SentrySDK.capture(event: event)
    }
    
    private func getUsesr(currentUser: UserManager?=nil) -> Sentry.User {
        guard let currentUser = currentUser else {
            return Sentry.User(userId: "Not record")
        }
        let user = Sentry.User(userId: currentUser.userinfo.userId)
        return user
    }
}

extension Analytics {
    
    struct Events {
        static let event = "Event"
        static let logout = "Logout"
    }
    struct Reason {
        static let reason = "Reason"
        static let tokenRevoke = "Token Revoke"
        static let delinquent = "Delinquent limitation"
        static let logoutAll = "Logout All"
        static let userAction = "User Action"
    }
    
}
