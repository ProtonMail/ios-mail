//
//  LastUpdateCacheTests.swift
//  ProtonMailTests = Created on 6/24/15.
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


import UIKit
import XCTest
@testable import ProtonMail

class LastUpdateCacheTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure() {
            // Put the code you want to measure the time of here.
            XCTAssert(true, "Pass")
        }
    }
    
    func testInboxUpdateCache() {
        // initial the cache
//        let lastUpdatedStore = LastUpdatedStore(shared: UserDefaults.standardUserDefaults())
//        lastUpdatedStore.clear()
        
//        // test default cache
//        let time = lastUpdatedStore.inboxLastForKey(MessageLocation.inbox) as LastUpdatedStore.UpdateTime
//        XCTAssert(time.start == NSDate.distantPast() as! NSDate, "The initial data incorrect should be default data before start test")
//        
//        // update update time
//        let newUpdateTime : LastUpdatedStore.UpdateTime =  LastUpdatedStore.UpdateTime(start: NSDate(), end: NSDate(), update: NSDate())
//        lastUpdatedStore.updateInboxForKey(MessageLocation.inbox, updateTime: newUpdateTime)
//        let updatedTime = lastUpdatedStore.inboxLastForKey(MessageLocation.inbox) as LastUpdatedStore.UpdateTime
//        XCTAssert(updatedTime.start == newUpdateTime.start, "The start time should save after update")
//        XCTAssert(updatedTime.end == newUpdateTime.end, "The end time should save after update")
//        XCTAssert(updatedTime.update == newUpdateTime.update, "The update time should save after update")
//        
//        // test clean
//        lastUpdatedStore.clear()
//        let cleanedTime = lastUpdatedStore.inboxLastForKey(MessageLocation.inbox) as LastUpdatedStore.UpdateTime
//        XCTAssert(time.start == NSDate.distantPast() as! NSDate, "After clean the cache the data should be default")
    }

}
