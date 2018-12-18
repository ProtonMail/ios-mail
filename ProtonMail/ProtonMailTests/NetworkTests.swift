//
//  NetworkTests.swift
//  ProtonMailTests - Created on 9/17/18.
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
