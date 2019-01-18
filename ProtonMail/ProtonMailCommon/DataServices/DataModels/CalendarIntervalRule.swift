//
//  CalendarIntervalRule.swift
//  ProtonMail - Created on 03/06/2018.
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
        return self.contains(where: { $0.intersects(with: date) } )
    }
}
