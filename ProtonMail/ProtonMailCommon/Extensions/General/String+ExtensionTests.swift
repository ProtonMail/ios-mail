//
//  String+ExtensionTests.swift
//  ProtonMailTests
//
//  Created by Anatoly Rosencrantz on 28/09/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import XCTest
@testable import ProtonMail

class String_ExtensionTests: XCTestCase {

    func testValidEmail1() {
        XCTAssertTrue("jovan@a.org".isValidEmail())
    }
    
    func testValidEmail2() {
        XCTAssertTrue("jovan@a.co.il".isValidEmail())
    }
    
    func testValidEmail3() {
        XCTAssertFalse("jovan@a".isValidEmail())
    }
    
    func testValidEmail4() {
        XCTAssertFalse("@jovan".isValidEmail())
    }
    
    func testValidEmail5() {
        XCTAssertFalse("@jovan.ch".isValidEmail())
    }
}
