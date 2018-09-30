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

    func testExample() {
        XCTAssertTrue("jovan@a.org".isValidEmail())
        XCTAssertTrue("jovan@a.co.il".isValidEmail())
        
        XCTAssertFalse("jovan@a".isValidEmail())
        XCTAssertFalse("@jovan".isValidEmail())
        XCTAssertFalse("@jovan.ch".isValidEmail())
    }

}
