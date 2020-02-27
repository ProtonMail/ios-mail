//
//  NetworkTests.swift
//  ProtonMailTests - Created on 9/17/18.
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

import OHHTTPStubs
import AFNetworking

class NetworkTests: XCTestCase {

    override func setUp() {
        
        HTTPStubs.setEnabled(true)
        
        HTTPStubs.onStubActivation() { request, descriptor, response in
            // ...
        }
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
    }

    func testExample() {
        /*let sub = */stub(condition: isHost("www.example.com") && isPath("/1")) { request in
            let body = "{ \"data\": 1 }".data(using: String.Encoding.utf8)!
            let headers = [ "Content-Type" : "application/json"]
            return HTTPStubsResponse(data: body, statusCode: 200, headers: headers)
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
