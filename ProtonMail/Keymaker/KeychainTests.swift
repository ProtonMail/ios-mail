//
//  KeychainTests.swift
//  ProtonMail - Created on 08/07/2019.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

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
