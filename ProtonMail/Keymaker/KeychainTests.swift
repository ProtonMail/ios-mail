//
//  KeychainTests.swift
//  ProtonMail - Created on 08/07/2019.
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
@testable import Keymaker

class KeychainTests: XCTestCase {
    
    /*
     These tests can only run with signed binary, switch them on when CI will be capable of that
     */
    
    let keychain = Keychain(service: "ch.protonmail", accessGroup: "2SB5Z68H26.ch.protonmail.protonmail")

    override func setUp() {
        keychain.removeEverything()
    }

    func testAddNew() {
        let data = #function.data(using: .utf8)!
        let key = #function
        
        // check value does not appear in the keychain
        let presentsBeforeSaving = keychain.getData(forKey: key)
        XCTAssertNil(presentsBeforeSaving)
        
        // save
        let savedSuccessfully = keychain.add(data: data, forKey: key)
        XCTAssertTrue(savedSuccessfully)
        
        // verify saved
        let presentsAfterSaving = keychain.getData(forKey: key)
        XCTAssertEqual(data, presentsAfterSaving)
    }
    
    func testUpdate() {
        let dataOld = (#function + "old").data(using: .utf8)!
        let dataUpdated = (#function + "new").data(using: .utf8)!
        let key = #function
        
        // check value does not appear in the keychain
        let presentsBeforeSaving = keychain.getData(forKey: key)
        XCTAssertNil(presentsBeforeSaving)
        
        // save
        let savedSuccessfully = keychain.add(data: dataOld, forKey: key)
        XCTAssertTrue(savedSuccessfully)
        
        // verify saved
        let presentsAfterSaving = keychain.getData(forKey: key)
        XCTAssertEqual(dataOld, presentsAfterSaving)
        
        // save
        let updatedSuccessfully = keychain.add(data: dataUpdated, forKey: key)
        XCTAssertTrue(updatedSuccessfully)
        
        // verify saved
        let presentsAfterUpdating = keychain.getData(forKey: key)
        XCTAssertEqual(dataUpdated, presentsAfterUpdating)
    }
    
    func testRemove() {
        let data = #function.data(using: .utf8)!
        let key = #function
        
        // check value does not appear in the keychain
        let presentsBeforeSaving = keychain.getData(forKey: key)
        XCTAssertNil(presentsBeforeSaving)
        
        // save
        let savedSuccessfully = keychain.add(data: data, forKey: key)
        XCTAssertTrue(savedSuccessfully)
        
        // verify saved
        let presentsAfterSaving = keychain.getData(forKey: key)
        XCTAssertEqual(data, presentsAfterSaving)
        
        let removed = keychain.remove(key)
        XCTAssertTrue(removed)
        
        // verify saved
        let presentsAfterRemoving = keychain.getData(forKey: key)
        XCTAssertNil(presentsAfterRemoving)
    }

}
