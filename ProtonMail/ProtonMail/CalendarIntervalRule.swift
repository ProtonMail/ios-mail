//
//  CalendarIntervalRule.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 03/06/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

struct CalendarIntervalRule: Codable, Equatable {
    private let startMatching: DateComponents
    private let endMatching: DateComponents
    
    fileprivate static var componenstOfInterest: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
    
    internal init(start: DateComponents, end: DateComponents) {
        self.startMatching = start
        self.endMatching = end
    }
    
    internal init(duration: DateComponents, since date: Date) {
        self.startMatching = Calendar.current.dateComponents(CalendarIntervalRule.componenstOfInterest, from: date)
        let endDate = Calendar.current.date(byAdding: duration, to: date)!
        self.endMatching = Calendar.current.dateComponents(CalendarIntervalRule.componenstOfInterest, from: endDate)
    }
    
    internal func intersects(with dateOfInterest: Date) -> Bool {
        // interval already started
        guard let recentStart = Calendar.current.nextDate(after: dateOfInterest, matching: self.startMatching, matchingPolicy: .strict, repeatedTimePolicy: .first, direction: .backward), // and there is an end of interval in future
            let _ = Calendar.current.nextDate(after: dateOfInterest, matching: self.endMatching, matchingPolicy: .strict, repeatedTimePolicy: .first, direction: .forward) else
        {
            return false
        }
        
        // if there is an end of interval in the past...
        guard let recentEnd = Calendar.current.nextDate(after: dateOfInterest, matching: self.endMatching, matchingPolicy: .strict, repeatedTimePolicy: .first, direction: .backward) else
        {
            return true
        }
        
        // it should be before the start
        return Calendar.current.compare(recentEnd, to: recentStart, toGranularity: .second) == .orderedAscending
    }
}

extension Array where Element == CalendarIntervalRule {
    internal func intersects(with date: Date) -> Bool {
        return self.contains(where: { $0.intersects(with: date) } )
    }
}
