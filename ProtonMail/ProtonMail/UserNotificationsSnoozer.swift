//
//  UserNotificationsSnoozer.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 05/06/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

// model

final class UserNotificationsSnoozer {
    internal enum Configuration {
        case quick(rule: CalendarIntervalRule)
        case scheduled(rule: CalendarIntervalRule)
        
        internal func evaluate(at date: Date) -> Bool {
            switch self {
            case .quick(rule: let rule), .scheduled(rule: let rule):
                return rule.intersects(with: date)
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
    
    internal func activeConfigurations(at date: Date) -> [Configuration] {
        return self.configs().filter { $0.evaluate(at: date) }
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

// controller
extension UserNotificationsSnoozer {
    
    @available(iOS 10.0, *)
    internal func overview(at date: Date) -> String {
        guard case let activeConfigs = self.activeConfigurations(at: date), !activeConfigs.isEmpty else {
            return "Notification Snooze".localized
        }
        let descriptions: [String] = activeConfigs.compactMap { $0.localizedDescription(at: date) }
        return descriptions.joined(separator: ", ")
    }
    
    @available(iOS 10.0, *)
    internal func quickOptionsDialog(for date: Date,
                                     onStateChangedTo: ((Bool)->Void)? = nil) -> UIViewController
    {
        // time-based options
        let minutes = [30].map { (unit: Measurement<UnitDuration>(value: Double($0), unit: .minutes),
                                  component: DateComponents(minute: $0)) }
        let hours = [1, 2, 4, 8].map { (unit: Measurement<UnitDuration>(value: Double($0), unit: .hours),
                                        component: DateComponents(hour: $0)) }
        var timeBasedOptions = minutes
        timeBasedOptions.append(contentsOf: hours)

        // Measurement has plural nouns localization out of the box
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .long
        
        let timeBasedActions = timeBasedOptions.map { time in
            UIAlertAction(title: formatter.string(from: time.unit), style: .default) { _ in
                self.unsnoozeNonRepeating()
                self.add(.quick(rule: .init(duration: time.component, since: Date()))) // here we need date of tap, not creation!
                onStateChangedTo?(true)
            }
        }
        
        let dialog = UIAlertController(title: nil,
                                       message: self.overview(at: date),
                                       preferredStyle: .actionSheet)
        
        // other actions
        let turnOff = UIAlertAction(title: "Turn Off".localized, style: .destructive) { _ in
            self.unsnoozeNonRepeating()
            onStateChangedTo?(false)
        }
        let custom = UIAlertAction(title: "Custom".localized, style: .default) { _ in
            // FIXME: segue
            onStateChangedTo?(self.isSnoozeActive(at: Date()))
        }
        let scheduled = UIAlertAction(title: "Scheduled".localized, style: .default) { _ in
            // FIXME: segue
            onStateChangedTo?(self.isSnoozeActive(at: Date()))
        }
        let cancel = UIAlertAction(title: "Cancel".localized, style: .cancel) { _ in dialog.dismiss(animated: true, completion: nil) }
        
        // bring everything together
        
        if self.isNonRepeatingSnoozeActive(at: date) {
            [turnOff].forEach( dialog.addAction )
        }
        timeBasedActions.forEach( dialog.addAction )
        [custom, scheduled, cancel].forEach( dialog.addAction )
        
        return dialog
    }
}

@available(iOS 10.0, *)
extension UserNotificationsSnoozer.Configuration {
    private static var measurementFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter = NumberFormatter()
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }()
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    fileprivate func localizedDescription(at date: Date) -> String? {
        switch self {
        case .quick(rule: let rule):
            guard let timeInterval = rule.soonestEnd(from: date)?.timeIntervalSince(date) else {
                return nil
            }
            let measurement = Measurement<UnitDuration>(value: timeInterval, unit: .seconds)
            return "Snoozed for".localized + " " + UserNotificationsSnoozer.Configuration.measurementFormatter.string(from: measurement)
            
        case .scheduled(rule: let rule):
            guard let soonestEnd = rule.soonestEnd(from: date) else {
                return nil
            }
            
            return "Snoozed till".localized + " " + UserNotificationsSnoozer.Configuration.dateFormatter.string(from: soonestEnd)
        }
    }
}

// utilitary

extension UserNotificationsSnoozer.Configuration: Encodable, Decodable {
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
        
        throw NSError(domain: "\(UserNotificationsSnoozer.self)", code: 0, localizedDescription: "Failed to decode value from container")
    }
}

extension UserNotificationsSnoozer.Configuration: Equatable {
    internal static func == (lhs: UserNotificationsSnoozer.Configuration, rhs: UserNotificationsSnoozer.Configuration) -> Bool {
        switch (lhs, rhs) {
        case (.quick(let x1), .quick(let x2)) where x1 == x2: return true
        case (.scheduled(let x1), .scheduled(let x2)) where x1 == x2: return true
        default: return false
        }
    }
}
