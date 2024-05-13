//
//  MigrateTests.swift
//  Proton Mail - Created on 12/18/18.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.
    

import XCTest
@testable import ProtonMail

class MigrateTests: XCTestCase {
    
    class MigrateTest : Migrate {
        var _curVersion : Int
        init(l: Int, c: Int) {
            self.latestVersion = l
            self._curVersion = c
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
        var initalRun: Bool {
            get {
                return self.currentVersion == 0
            }
        }
        
        var testLogs: String = ""
        func rebuild(reason: RebuildReason) {
            switch reason {
            case .inital:
                testLogs += "inital"
            case .noSupports:
                testLogs += "noSupports"
            }
            //update cache version
            currentVersion = latestVersion
        }
    }

    func testMigrateCases() throws {
        ///test first run
        let firstTime = MigrateTest(l: 10, c: 0)
        try firstTime.run()
        XCTAssert(firstTime.testLogs == "inital")
        XCTAssert(firstTime.latestVersion == firstTime.currentVersion)
        /// current == latest
        let okRun = MigrateTest(l: 1, c: 1)
        try okRun.run()
        XCTAssert(okRun.testLogs == "")
        XCTAssert(okRun.latestVersion == okRun.currentVersion)
        /// no support
        let noSupportCase = MigrateTest(l: 9, c: 6)
        try noSupportCase.run()
        XCTAssert(noSupportCase.testLogs == "noSupports")
        XCTAssert(noSupportCase.latestVersion == noSupportCase.currentVersion)
    }
}
