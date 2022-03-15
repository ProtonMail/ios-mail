//
//  CalendarIntervalRule.swift
//  ProtonMail - Created on 03/06/2018.
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

struct CalendarIntervalRule: Codable, Equatable {
    internal let startMatching: DateComponents
    internal let endMatching: DateComponents

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
        guard let recentStart = Calendar.current.nextDate(after: dateOfInterest,
                                                          matching: self.startMatching,
                                                          matchingPolicy: .strict,
                                                          repeatedTimePolicy: .first,
                                                          direction: .backward), // and there is an end of interval in future
            let _ = Calendar.current.nextDate(after: dateOfInterest,
                                              matching: self.endMatching,
                                              matchingPolicy: .strict,
                                              repeatedTimePolicy: .first,
                                              direction: .forward) else {
            return false
        }

        // if there is an end of interval in the past...
        guard let recentEnd = Calendar.current.nextDate(after: dateOfInterest,
                                                        matching: self.endMatching,
                                                        matchingPolicy: .strict,
                                                        repeatedTimePolicy: .first,
                                                        direction: .backward) else {
            return true
        }

        // it should be before the start
        return Calendar.current.compare(recentEnd, to: recentStart, toGranularity: .second) == .orderedAscending
    }

    internal func soonestEnd(from date: Date) -> Date? {
        return Calendar.current.nextDate(after: date, matching: self.endMatching, matchingPolicy: .strict, repeatedTimePolicy: .first, direction: .forward)
    }
}

extension Array where Element == CalendarIntervalRule {
    internal func intersects(with date: Date) -> Bool {
        return self.contains(where: { $0.intersects(with: date) })
    }
}
