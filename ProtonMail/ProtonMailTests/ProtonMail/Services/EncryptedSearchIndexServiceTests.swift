// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import XCTest
@testable import ProtonMail

class EncryptedSearchIndexServiceTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testTODO() throws {
        /*let body: String = "<div dir=\"ltr\">this is a testmessage<br></div>\n"
        let sut = EncryptedSearchService.shared.extractKeywordsFromBody
        let result = sut(body, true)
        
        XCTAssertEqual(result, "this is a testmessage")*/
    }
    
    //TODO test connectToSearchIndex
    //TODO test createSearchIndexTable
    //TODO test addNewEntryToSearchIndex
    //TODO test removeEntryFromSearchIndex
    //TODO test getDBParams
    //TODO test getSearchIndexName
    
    func testGetSearchIndexName() throws {
        let sut = EncryptedSearchIndexService.shared.getSearchIndexName
        let testUserID: String = "123"
        let result: String = sut(testUserID)
        
        XCTAssertEqual(result, "encryptedSearchIndex_123.sqlite3")
    }
    
    //TODO test getSearchIndexPathToDB
    //TODO test checkIfSearchIndexExists
    //TODO test getNumberOfEntriesInSearchIndex
    //TODO test deleteSearchIndex
    //TODO test getSizeOfSearchIndex
    //TODO test getFreeDiskSpace
    //TODO test getOldestMessageInSearchIndex
    //TODO test getNewestMessageInSearchIndex
    //TODO test timeToDateString
    //TODO test createSearchIndexDBIfNotExisting
    //TODO test updateLocationForMessage
    //TODO test compressSearchIndex
}
