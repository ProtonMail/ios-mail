//
//  AuthAPITests.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit
import XCTest




class AuthAPITests: XCTestCase {

  //
    
    
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
        }
    }
    
    func testAuth()
    {
//        apiService.authAuth(username: "zhj4478", password: "31Feng31"){ auth, error in
//            if error == nil {
//                XCTAssert(true, "Pass")
//            } else {
//                
//                XCTAssertTrue(false, "failed")
//            }
//        }

    }

}
