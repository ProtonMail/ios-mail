//
//  LockedTests.swift
//  ProtonMailTests
//
//  Created by Anatoly Rosencrantz on 16/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import XCTest
@testable import Keymaker

class LockedTests: XCTestCase {
    let message = "Santa does not exhist"
    
    func testCodableLockUnlock() {
        var key = Array<UInt8>(repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, key.count, &key)
        guard status == 0 else {
            XCTAssert(false, "failed to create cryptographically secure key")
            return
        }
        
        do {
            let locked = try Locked<[String]>.init(clearValue: [message], with: key)
            let unlocked = try locked.unlock(with: key)
            XCTAssertEqual(message, unlocked.first!)
        } catch let error {
            XCTAssertNil(error)
        }
    }

    func testCustomLocker() {
        let locker: (String) throws -> Data = { cleartext in
            guard let data = cleartext.data(using: .utf8) else {
                throw NSError(domain: "failed to turn string into data", code: 0, userInfo: nil)
            }
            return data
        }
        let unlocker: (Data) throws -> String = { cypher in
            guard let cleartext = String(data: cypher, encoding: .utf8) else {
                throw NSError(domain: "failed to turn data into string", code: 1, userInfo: nil)
            }
            return cleartext
        }
        
        do {
            let locked = try Locked<String>(clearValue: message, with: locker)
            let unlocked = try locked.unlock(with: unlocker)
            XCTAssertEqual(message, unlocked)
        } catch let error {
            XCTAssertNil(error)
        }
    }
}
