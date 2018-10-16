//
//  LockedTests.swift
//  ProtonMailTests
//
//  Created by Anatoly Rosencrantz on 16/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import XCTest
@testable import ProtonMail

class LockedTests: XCTestCase {

    func testExample() {
        let key = Array<UInt8>(hex: "0x010203")
        let message = "Santa does not exhist"
        do {
            let locked = try Locked<String>.init(clearValue: message, with: key)
            print(locked.encryptedValue)
            
            let unlocked = try locked.unlock(with: key)
            XCTAssertEqual(message, unlocked)
        } catch let error {
            XCTAssertNil(error)
        }
    }

}
