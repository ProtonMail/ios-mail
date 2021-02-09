//
//  CalendarIntervalRuleTests.swift
//  ProtonMailTests - Created on 03/06/2018.
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

import XCTest
@testable import ProtonMail

class CalendarIntervalRuleTests: XCTestCase {
    
    func testSingleDayEntry() {
        let sunday03h59m59s = Calendar.current.date(from: .init(year: 2018, month: 6, day: 3, hour: 03, minute: 59, second: 59))!
        let sunday10h08m00s = Calendar.current.date(from: .init(year: 2018, month: 6, day: 3, hour: 10, minute: 08, second: 00))!
        let sunday17h35m14s = Calendar.current.date(from: .init(year: 2018, month: 6, day: 3, hour: 17, minute: 35, second: 14))!
    
        let ruleSunday09to17 = CalendarIntervalRule(start: .init(hour: 09, minute: 00, weekday: 1),
                                                end: .init(hour: 17, minute: 00, weekday: 1))
        let ruleMonday09to17 = CalendarIntervalRule(start: .init(hour: 09, minute: 00, weekday: 2),
                                                end: .init(hour: 17, minute: 00, weekday: 2))
        
        XCTAssertFalse(ruleSunday09to17.intersects(with: sunday03h59m59s))
        XCTAssertTrue(ruleSunday09to17.intersects(with: sunday10h08m00s))
        XCTAssertFalse(ruleSunday09to17.intersects(with: sunday17h35m14s))
        
        XCTAssertFalse(ruleMonday09to17.intersects(with: sunday10h08m00s))
    }
    
    func testArrayOfDayEntries() {
        let sunday03h59m59s = Calendar.current.date(from: .init(year: 2018, month: 6, day: 3, hour: 03, minute: 59, second: 59))!
        let sunday11h59m59s = Calendar.current.date(from: .init(year: 2018, month: 6, day: 3, hour: 11, minute: 59, second: 59))!
        let saturday10h08m00s = Calendar.current.date(from: .init(year: 2018, month: 6, day: 2, hour: 10, minute: 08, second: 00))!
        let friday17h35m14s = Calendar.current.date(from: .init(year: 2018, month: 6, day: 1, hour: 17, minute: 35, second: 14))!
        
        let ruleSunWedFri9to17 = [1,3,5].map {
            CalendarIntervalRule(start: .init(hour: 9, minute: 00, weekday: $0),
                  end: .init(hour: 17, minute: 00, weekday: $0))
        }
        
        XCTAssertFalse(ruleSunWedFri9to17.intersects(with: sunday03h59m59s))
        XCTAssertTrue(ruleSunWedFri9to17.intersects(with: sunday11h59m59s))
        XCTAssertFalse(ruleSunWedFri9to17.intersects(with: saturday10h08m00s))
        XCTAssertFalse(ruleSunWedFri9to17.intersects(with: friday17h35m14s))
    }
    
    func testArrayOfNightEntries() {
        let monday03h59m59s = Calendar.current.date(from: .init(year: 2018, month: 6, day: 4, hour: 03, minute: 59, second: 59))!
        let sunday11h59m59s = Calendar.current.date(from: .init(year: 2018, month: 6, day: 3, hour: 11, minute: 59, second: 59))!
        let saturday10h08m00s = Calendar.current.date(from: .init(year: 2018, month: 6, day: 2, hour: 10, minute: 08, second: 00))!
        let saturday05h09m59s = Calendar.current.date(from: .init(year: 2018, month: 6, day: 2, hour: 05, minute: 09, second: 59))!
        let sunday05h50m59s = Calendar.current.date(from: .init(year: 2018, month: 6, day: 3, hour: 05, minute: 50, second: 59))!
        
        let ruleSunFri23to06 = [1, 6].map {
            CalendarIntervalRule(start: .init(hour: 23, minute: 00, weekday: $0),
                                 end: .init(hour: 06, minute: 00, weekday: $0 + 1))
        }
        
        XCTAssertTrue(ruleSunFri23to06.intersects(with: monday03h59m59s))
        XCTAssertFalse(ruleSunFri23to06.intersects(with: sunday11h59m59s))
        XCTAssertFalse(ruleSunFri23to06.intersects(with: saturday10h08m00s))
        XCTAssertTrue(ruleSunFri23to06.intersects(with: saturday05h09m59s))
        XCTAssertFalse(ruleSunFri23to06.intersects(with: sunday05h50m59s))
    }
    
    func testQuickEntry() {
        let saturday05h00m00s = Calendar.current.date(from: .init(year: 2018, month: 6, day: 2, hour: 05, minute: 00, second: 00))!
        let saturday10h08m00s = Calendar.current.date(from: .init(year: 2018, month: 6, day: 2, hour: 10, minute: 08, second: 00))!
        let saturday05h00m00sPlusWeek = Calendar.current.date(byAdding: .init(day: 7), to: saturday10h08m00s)!
        
        let rule30MinSinceSat05h00m00s = CalendarIntervalRule(duration: .init(hour: 0, minute: 30), since: saturday05h00m00s)
        let rule08HoursSinceSat05h00m00s = CalendarIntervalRule(duration: .init(hour: 8, minute: 00), since: saturday05h00m00s)
        
        XCTAssertFalse(rule30MinSinceSat05h00m00s.intersects(with: saturday10h08m00s))
        XCTAssertTrue(rule08HoursSinceSat05h00m00s.intersects(with: saturday10h08m00s))
        XCTAssertFalse(rule08HoursSinceSat05h00m00s.intersects(with: saturday05h00m00sPlusWeek))
    }
    
}
