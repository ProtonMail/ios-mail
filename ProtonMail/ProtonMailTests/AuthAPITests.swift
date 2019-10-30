//
//  AuthAPITests.swift
//  ProtonMail - Created on 6/17/15.
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

class AuthAPITests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
//        sharedAPIService.authAuth(username: "feng", password: "123") { auth, error in
//            if error == nil {
//                self.isSignedIn = true
//                self.username = username
//                self.password = password
//                
//                if isRemembered {
//                    self.isRememberUser = isRemembered
//                }
//                
//                let completionWrapper: UserInfoBlock = { auth, error in
//                    if error == nil {
//                        NSNotificationCenter.defaultCenter().postNotificationName(Notification.didSignIn, object: self)
//                    }
//                    
//                    completion(auth, error)
//                }
//                
//                self.fetchUserInfo(completion: completionWrapper)
//            } else {
//                self.signOut(true)
//                completion(nil, error)
//            }
//        }
        XCTAssert(true, "Pass")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure() {
            // Put the code you want to measure the time of here.
            XCTAssert(true, "Pass")
        }
    }
    
    func testAuth() {

    }

}
