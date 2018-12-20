//
//  MigrateTests.swift
//  ProtonMail - Created on 12/18/18.
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
@testable import ProtonMail

class MigrateTests: XCTestCase {
    
    class MigrateTest : Migrate {
        func logout() {
            
        }
        
        var _curVersion : Int
        init(l: Int, c: Int, s: [Int]) {
            self.latestVersion = l
            self._curVersion = c
            self.supportedVersions = s
        }
        var latestVersion: Int
        var currentVersion: Int {
            get {
                return _curVersion
            }
            set {
                self._curVersion = newValue
            }
        }
        var supportedVersions: [Int]
        var initalRun: Bool {
            get {
                return self.currentVersion == 0
            }
        }
        
        var testLogs: String = ""
        func migrate(from verfrom: Int, to verto: Int) -> Bool {
            
            switch (verfrom, verto) {
            case (4,5):
                testLogs += "ok:from:\(verfrom)-to:\(verto)"
                return true
            case (5,6),(6,7):
                testLogs += "ignore:from:\(verfrom)-to:\(verto)"
                return true
            case (7,8):
                return false
            default:
                testLogs += "default:from:\(verfrom)-to:\(verto)"
                return true
            }
        }
        func rebuild(reason: RebuildReason) {
            switch reason {
            case .inital:
                testLogs += "inital"
            case .noSupports:
                testLogs += "noSupports"
            case .invalidSupport:
                testLogs += "invalidSupport"
            case .failed(let from, let to):
                testLogs += "failed:from:\(from)-to:\(to)"
            }
            //update cache version
            currentVersion = latestVersion
        }
        func cleanLagacy() {
            testLogs += "cleanLagacy"
        }
    }

    func testMigrateCases() {
        ///test first run
        let firstTime = MigrateTest(l: 10, c: 0, s: [3,4,5])
        firstTime.run()
        XCTAssert(firstTime.testLogs == "inital")
        XCTAssert(firstTime.latestVersion == firstTime.currentVersion)
        /// current == latest
        let okRun = MigrateTest(l: 1, c: 1, s: [3,4,5])
        okRun.run()
        XCTAssert(okRun.testLogs == "")
        XCTAssert(okRun.latestVersion == okRun.currentVersion)
        /// wong supported versiosn
        let wrongSupport = MigrateTest(l: 9, c: 7, s: [3,4,5,6,7,8,10])
        wrongSupport.run()
        XCTAssert(wrongSupport.testLogs == "invalidSupport")
        XCTAssert(wrongSupport.latestVersion == wrongSupport.currentVersion)
        /// no support 1
        let noSupportCase1 = MigrateTest(l: 9, c: 2, s: [3,4,5])
        noSupportCase1.run()
        XCTAssert(noSupportCase1.testLogs == "noSupports")
        XCTAssert(noSupportCase1.latestVersion == noSupportCase1.currentVersion)
        /// no support 2
        let noSupportCase2 = MigrateTest(l: 9, c: 6, s: [3,4,5])
        noSupportCase2.run()
        XCTAssert(noSupportCase2.testLogs == "noSupports")
        XCTAssert(noSupportCase2.latestVersion == noSupportCase2.currentVersion)
        /// no support 3
        let noSupportCase3 = MigrateTest(l: 9, c: 6, s: [])
        noSupportCase3.run()
        XCTAssert(noSupportCase3.testLogs == "noSupports")
        XCTAssert(noSupportCase3.latestVersion == noSupportCase3.currentVersion)
        /// migrate case 1
        let mCase1 = MigrateTest(l: 5, c: 3, s: [3,4])
        mCase1.run()
        XCTAssert(mCase1.testLogs == "default:from:3-to:4ok:from:4-to:5cleanLagacy")
        XCTAssert(mCase1.latestVersion == mCase1.currentVersion)
        /// migrate case 2
        let mCase2 = MigrateTest(l: 10, c: 4, s: [3,4,5,6,7,8,10])
        mCase2.run()
        XCTAssert(mCase2.testLogs == "ok:from:4-to:5ignore:from:5-to:6ignore:from:6-to:7failed:from:7-to:8")
        XCTAssert(mCase2.latestVersion == mCase2.currentVersion)
        /// migrate case 3
        let mCase3 = MigrateTest(l: 7, c: 4, s: [3,4,5,6])
        mCase3.run()
        XCTAssert(mCase3.testLogs == "ok:from:4-to:5ignore:from:5-to:6ignore:from:6-to:7cleanLagacy")
        XCTAssert(mCase3.latestVersion == mCase3.currentVersion)
        /// migrate case 4
        let mCase4 = MigrateTest(l: 7, c: 6, s: [3,4,5,6])
        mCase4.run()
        XCTAssert(mCase4.testLogs == "ignore:from:6-to:7cleanLagacy")
        XCTAssert(mCase4.latestVersion == mCase4.currentVersion)
    }
}
