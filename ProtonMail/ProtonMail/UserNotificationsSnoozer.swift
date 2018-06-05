//
//  UserNotificationsSnoozer.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 05/06/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

final class UserNotificationsSnoozer {
    internal enum Configuration {
        case quick(rule: CalendarIntervalRule)
        case scheduled(rules: [CalendarIntervalRule])
        
        func evaluate() -> Bool {
            switch self {
            case .quick(rule: let rule):
                return rule.intersects(with: Date())
                
            case .scheduled(rules: let rules):
                return rules.intersects(with: Date())
            }
        }
    }
    
    // check if snoozed currently
    internal func evaluate() -> Bool {
        return userCachedStatus.snoozeConfiguration?.contains { $0.evaluate() } ?? false
    }
    
    // set snooze config
    internal func snooze(_ configuration: Configuration) {
        var currentSettings = userCachedStatus.snoozeConfiguration ?? []
        currentSettings.append(configuration)
        userCachedStatus.snoozeConfiguration = currentSettings
    }
    
    // remove snooze config
    internal func unsnooze(_ configuration: Configuration) {
        guard var currentSettings = userCachedStatus.snoozeConfiguration else {
            return
        }
        currentSettings = currentSettings.filter { $0 != configuration }
        userCachedStatus.snoozeConfiguration = currentSettings
    }
}

extension UserNotificationsSnoozer.Configuration: Encodable, Decodable {
    private enum CodingKeys: CodingKey {
        case quick
        case scheduled
        case whileAt
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
        
        if let scheduled =  try? container.decode(Array<CalendarIntervalRule>.self, forKey: .scheduled) {
            self = .scheduled(rules: scheduled)
            return
        }
        
        throw NSError(domain: "\(UserNotificationsSnoozer.self)", code: 0, localizedDescription: "Failed to decode value from container")
    }
}

extension UserNotificationsSnoozer.Configuration: Equatable {
    static func == (lhs: UserNotificationsSnoozer.Configuration, rhs: UserNotificationsSnoozer.Configuration) -> Bool {
        switch (lhs, rhs) {
        case (.quick(let x1), .quick(let x2)) where x1 == x2:
            return true
            
        case (.scheduled(let x1), .scheduled(let x2)) where x1 == x2:
            return true
            
        default:
            return false
        }
    }
}
