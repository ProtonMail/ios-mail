//
//  UserNotificationsSnoozer.swift
//  ProtonMail - Created on 05/06/2018.
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

// model
class NotificationsSnoozerCore {
    
    internal enum Configuration {
        case quick(rule: CalendarIntervalRule)
        case scheduled(rule: CalendarIntervalRule)
        
        internal func evaluate(at date: Date) -> Bool {
            switch self {
            case .quick(rule: let rule), .scheduled(rule: let rule):
                return rule.intersects(with: date)
            }
        }
        
        internal func belongs(to type: CodingKeys) -> Bool {
            switch self {
            case .quick where type == .quick,
                 .scheduled where type == .scheduled: return true
            default: return false
            }
        }
        
        internal var rule: CalendarIntervalRule {
            switch self {
            case .quick(rule: let rule), .scheduled(rule: let rule):
                return rule
            }
        }
    }
    
    internal func configs(ofCase type: Configuration.CodingKeys? = nil) -> [Configuration] {
        guard let configs = userCachedStatus.snoozeConfiguration else {
            return []
        }
        guard let type = type else {
            return configs
        }
        return configs.filter {
            switch $0 {
            case Configuration.quick where type == .quick: return true
            case Configuration.scheduled where type == .scheduled: return true
            default: return false
            }
        }
    }
    
    // TODO: evaluated configs can be cached here
    
    // check if snoozed currently
    internal func isSnoozeActive(at date: Date) -> Bool {
        return self.configs().contains { $0.evaluate(at: date) }
    }
    
    internal func isNonRepeatingSnoozeActive(at date: Date) -> Bool {
        return self.configs(ofCase: .quick).contains { $0.evaluate(at: date) }
    }
    
    internal func activeConfigurations(at date: Date, ofCase type: Configuration.CodingKeys? = nil) -> [Configuration] {
        return self.configs(ofCase: type).filter { $0.evaluate(at: date) }
    }
    
    // set snooze config
    internal func add(_ configurations: [Configuration]) {
        var currentSettings = userCachedStatus.snoozeConfiguration
        currentSettings?.append(contentsOf: configurations)
        userCachedStatus.snoozeConfiguration = currentSettings
    }
    internal func add(_ configuration: Configuration) {
        var currentSettings = userCachedStatus.snoozeConfiguration
        currentSettings?.append(configuration)
        userCachedStatus.snoozeConfiguration = currentSettings
    }
    
    // remove snooze config
    private func unsnooze(_ configurations: [Configuration]) {
        guard var currentSettings = userCachedStatus.snoozeConfiguration else {
            return
        }
        currentSettings = currentSettings.filter { !configurations.contains($0) }
        userCachedStatus.snoozeConfiguration = currentSettings
    }
    
    internal func unsnoozeNonRepeating() {
        self.unsnooze(self.configs(ofCase: .quick))
    }
    
    internal func unsnoozeRepeating() {
        self.unsnooze(self.configs(ofCase: .scheduled))
    }
}

// utilitary

extension NotificationsSnoozerCore.Configuration: Encodable, Decodable {
    internal enum CodingKeys: CodingKey {
        case quick
        case scheduled
    }
    
    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .quick(let rule):
            try container.encode(rule, forKey: .quick)
        case .scheduled(let rules):
            try container.encode(rules, forKey: .scheduled)
        }
    }
    
    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let quick =  try? container.decode(CalendarIntervalRule.self, forKey: .quick) {
            self = .quick(rule: quick)
            return
        }
        
        if let scheduled =  try? container.decode(CalendarIntervalRule.self, forKey: .scheduled) {
            self = .scheduled(rule: scheduled)
            return
        }
        
        throw NSError(domain: "\(NotificationsSnoozerCore.self)", code: 0, localizedDescription: "Failed to decode value from container")
    }
}

extension NotificationsSnoozerCore.Configuration: Equatable {
    internal static func == (lhs: NotificationsSnoozerCore.Configuration, rhs: NotificationsSnoozerCore.Configuration) -> Bool {
        switch (lhs, rhs) {
        case (.quick(let x1), .quick(let x2)) where x1 == x2: return true
        case (.scheduled(let x1), .scheduled(let x2)) where x1 == x2: return true
        default: return false
        }
    }
}
