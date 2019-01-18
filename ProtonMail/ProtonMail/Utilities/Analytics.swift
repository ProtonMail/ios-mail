//
//  Analytics.swift
//  ProtonMail - Created on 30/11/2018.
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
import Sentry

class Analytics {
    typealias Event = Sentry.Event
    static var shared = Analytics()
    
    private var sentryEndpoint: String {
        #if Enterprise
            return "https://3f5b27555fa64b519002266dcdc7744c:d9b72932c36d4456b9535c93b7c7e834@api.protonmail.ch/reports/sentry/25"
        #else
            return "https://bcbe8b2a026848c4b139df228d088072:b0643c66a54347f299b4e70bc39ce6ba@api.protonmail.ch/reports/sentry/7"
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
    
    func logCustomEvent(withName: String, customAttributes: Dictionary<String, Any>) {
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
