//
//  NetworkTests.swift
//  ProtonMailTests
//
//  Created by Yanfeng Zhang on 9/17/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import XCTest

import OHHTTPStubs
import AFNetworking

class NetworkTests: XCTestCase {

    override func setUp() {
        
        OHHTTPStubs.setEnabled(true)
        
        OHHTTPStubs.onStubActivation() { request, descriptor, response in
            // ...
        }
    }

    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
    }

    func testExample() {
        /*let sub = */stub(condition: isHost("www.example.com") && isPath("/1")) { request in
            let body = "{ \"data\": 1 }".data(using: String.Encoding.utf8)!
            let headers = [ "Content-Type" : "application/json"]
            return OHHTTPStubsResponse(data: body, statusCode: 200, headers: headers)
        }
        
        let expectation1 = self.expectation(description: "Success completion block called")
        let url = URL(string: "https://www.example.com/1")!
        let manager = AFHTTPSessionManager()
        manager.get(url.absoluteString, parameters: nil, progress: nil, success: { (task, response) -> Void in
            XCTAssertEqual(response as? NSDictionary, [ "data": 1 ])
            //OHHTTPStubs.removeStub(sub)
            expectation1.fulfill()
        }) { (task, error) -> Void in
            XCTFail("This shouldn't return an error")
        }
        let expectation2 = self.expectation(description: "Success completion block called")
        manager.get(url.absoluteString, parameters: nil, progress: nil, success: { (task, response) -> Void in
            XCTAssertEqual(response as? NSDictionary, [ "data": 1 ])
            expectation2.fulfill()
        }) { (task, error) -> Void in
            XCTFail("This shouldn't return an error")
        }
        
        self.waitForExpectations(timeout: 1) { (expectationError) -> Void in
            XCTAssertNil(expectationError)
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
