//
//  AppVersionTests.swift
//  ProtonMailTests
//
//  Created by Anatoly Rosencrantz on 15/06/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import XCTest
@testable import ProtonMail

class AppVersionTests: XCTestCase {

    func testExample() {
        let verA = "1.9.0"
        let verB = "1.9.1"
        let verC = "2.0.0"
        let verD = "0.0.1"
        let verE = "5.0"
        let verF = "1"
        let verG = "1.9.0"
        
        let correctOrder = [verA, verB, verC, verD, verE, verF, verG].map(AppVersion.init).sorted().map{ $0.string }
        XCTAssertEqual(correctOrder, [verD, verF, verA, verG, verB, verC, verE])
    }
}
