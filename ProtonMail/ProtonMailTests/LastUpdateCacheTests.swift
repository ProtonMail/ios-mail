//
//  LastUpdateCacheTests.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/24/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit
import XCTest
import ProtonMail

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
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testInboxUpdateCache() {
        // initial the cache
        let lastUpdatedStore = LastUpdatedStore(shared: NSUserDefaults.standardUserDefaults())
        lastUpdatedStore.clear()
        
        // test default cache
        let time = lastUpdatedStore.inboxLastForKey(MessageLocation.inbox) as LastUpdatedStore.UpdateTime
        XCTAssert(time.start == NSDate.distantPast() as! NSDate, "The initial data incorrect should be default data before start test")
        
        // update update time
        let newUpdateTime : LastUpdatedStore.UpdateTime =  LastUpdatedStore.UpdateTime(start: NSDate(), end: NSDate())
        lastUpdatedStore.updateInboxForKey(MessageLocation.inbox, updateTime: newUpdateTime)
        let updatedTime = lastUpdatedStore.inboxLastForKey(MessageLocation.inbox) as LastUpdatedStore.UpdateTime
        XCTAssert(updatedTime.start == newUpdateTime.start, "The start time should save after update")
        XCTAssert(updatedTime.end == newUpdateTime.end, "The start time should save after update")
        
        // test clean
        lastUpdatedStore.clear()
        let cleanedTime = lastUpdatedStore.inboxLastForKey(MessageLocation.inbox) as LastUpdatedStore.UpdateTime
        XCTAssert(time.start == NSDate.distantPast() as! NSDate, "After clean the cache the data should be default")
    }

}
