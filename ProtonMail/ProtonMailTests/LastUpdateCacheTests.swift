//
//  LastUpdateCacheTests.swift
//  ProtonMailTests = Created on 6/24/15.
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
