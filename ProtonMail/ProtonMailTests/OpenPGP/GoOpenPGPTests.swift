//
//  GoOpenPGPTests.swift
//  ProtonMailTests
//
//  Created by Yanfeng Zhang on 5/7/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import XCTest
import Pm

class GoOpenPGPTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            for _ in 0 ... 100 {
                let result = PmCheckPassphrase(OpenPGPDefines.privateKey, OpenPGPDefines.passphrase)
                XCTAssertTrue(result, "checkPassphrase failed")
            }
        }
    }
    
    //MARK: - Test methods
    func testCheckPassphrase() {
        let result = PmCheckPassphrase(OpenPGPDefines.privateKey, OpenPGPDefines.passphrase)
        XCTAssertTrue(result, "checkPassphrase failed")
    }
    
    func testEncryption() {
        self.measure {
            for _ in 0 ... 100 {
                var error : NSError?
                let out = PmEncryptMessageSingleKey(OpenPGPDefines.publicKey, "test", "", "", true, &error)
                if let err = error {
                    
                }
            }
        }
    }
    
    func testDecryption() {
        
    }
}
