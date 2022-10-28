//
//  MenuLabelTests.swift
//  ProtonMailTests
//
//
//  Copyright (c) 2021 Proton AG
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

import CoreData
import Groot
@testable import ProtonMail
import XCTest

final class MenuLabelTests: XCTestCase {
    private var menuLabels: [MenuLabel]!

    override func setUpWithError() throws {
        try super.setUpWithError()

        let coreDataService = MockCoreDataContextProvider()

        let parsedLabel = testV4LabelData.parseJson()!

        try coreDataService.enqueue { testContext in
            let labels = try GRTJSONSerialization.objects(withEntityName: Label.Attributes.entityName, fromJSONArray: parsedLabel, in: testContext)
            guard let rawData = labels as? [Label] else {
                XCTAssert(false, "Initialization failed")
                return
            }
            self.menuLabels = Array(labels: rawData
                .compactMap { LabelEntity(label: $0) },
                previousRawData: [])
            XCTAssertEqual(self.menuLabels.count, rawData.count)
        }
    }

    override func tearDown() {
        menuLabels = nil

        super.tearDown()
    }

    func testSortout() {
        let (labels, folders) = menuLabels.sortoutData()
        XCTAssertEqual(labels.count, 6)

        XCTAssertEqual(folders.count, 8)
        XCTAssertEqual(folders.getNumberOfRows(), 13)

        let targetID = "McToVpfXly8nccAey391VY652WNF7rtZEeiq6M3E07UYfGu5Bq4pcxpI7jMJQl8zaCZV3T9H8SQ9rHnyOgFKKA=="
        guard let index = folders.getRow(of: LabelID(targetID)) else {
            XCTAssert(false, "Get target folder row failed")
            return
        }
        XCTAssertEqual(index, 3)

        guard let label = folders.getLabel(of: LabelID(targetID)) else {
            XCTAssert(false, "Query target folder row failed")
            return
        }
        XCTAssertEqual(label.name, "abjbn")
        XCTAssertEqual(label.deepLevel, 1)

        let parentID = "cQj3yw8Pr_FUEs-rvDZr5cMTUo4mGBN_pIoOORQCUKYq_XWErpzIEYODkr4QU7nYt2NQGVKX5db0Cn7DIlrk5w=="
        XCTAssertEqual(label.parentID?.rawValue, parentID)

        guard let root = folders.getRootItem(of: label) else {
            XCTAssert(false, "Get root item failed")
            return
        }

        XCTAssertEqual(root.location.rawLabelID, parentID)
        XCTAssertEqual(root.name, "saved")
        XCTAssertEqual(root.deepLevel, 3)
        XCTAssertEqual(root.contains(item: label), true)
    }

    func testQueryByIndex() throws {
        let (_, folders) = menuLabels.sortoutData()

        let label = try XCTUnwrap(folders.getFolderItem(at: 5))

        let id = "qOEDAmcFE4c9_sD-JV2h6BNPN8pRsWXngWFVA1v0baVCZ8unJvKtaPPE769uFUr85nNowKGVtD2o6zFGXBOHfA=="
        XCTAssertEqual(label.location.rawLabelID, id)
        XCTAssertEqual(label.name, "sub_sub1")
    }

    func testIndentationLevel() {
        let label = MenuLabel(id: "id", name: "/name", parentID: nil, path: "a/b/c", textColor: "", iconColor: "", type: -1, order: -1, notify: false)
        label.setupIndentationByPath()
        XCTAssertEqual(label.indentationLevel, 2)

        let label2 = MenuLabel(id: "id", name: "/name", parentID: nil, path: #"a\/b\/c"#, textColor: "", iconColor: "", type: -1, order: -1, notify: false)
        label2.setupIndentationByPath()
        XCTAssertEqual(label2.indentationLevel, 0)
    }

    func testFlattenSubFolders() {
        let (labels, folders) = menuLabels.sortoutData()
        XCTAssertEqual(labels.count, 6)

        XCTAssertEqual(folders[0].flattenSubFolders().count, 1)
        XCTAssertEqual(folders[1].flattenSubFolders().count, 4)
    }

    func testSetParentID() {
        let sut = MenuLabel(location: .inbox)
        let parentID = LabelID(String.randomString(10))

        sut.set(parentID: parentID)
        XCTAssertEqual(sut.parentID, parentID)
    }

    func testContain_withNonParentIDItem_returnFalse() {
        let item = MenuLabel(location: .customize(String.randomString(10), nil))
        let sut = MenuLabel(location: .customize(String.randomString(10), nil))
        XCTAssertFalse(sut.contains(item: item))
    }

    func testContain_withItemChild_returnTrue() {
        let item = MenuLabel(location: .customize(String.randomString(10), nil))
        let sut = MenuLabel(location: .customize(String.randomString(10), nil))
        item.set(parentID: sut.location.labelID)

        XCTAssertTrue(sut.contains(item: item))
    }

    func testContain_withItemGrandChild_returnTrue() {
        // └── sut
        //     └── itemChild
        //         └── itemGrandChild
        let itemGrandChild = MenuLabel(location: .customize(String.randomString(10), nil))
        let itemChild = MenuLabel(location: .customize(String.randomString(10), nil))
        let sut = MenuLabel(location: .customize(String.randomString(10), nil))

        sut.subLabels.append(itemChild)
        itemChild.set(parentID: sut.location.labelID)
        itemChild.subLabels.append(itemGrandChild)
        itemGrandChild.set(parentID: itemChild.location.labelID)

        XCTAssertTrue(sut.contains(item: itemGrandChild))
    }

    func testContain_withNewItem_returnFalse() {
        let item = MenuLabel(location: .customize(String.randomString(10), nil))
        let sut = MenuLabel(location: .customize(String.randomString(10), nil))
        item.set(parentID: LabelID(String.randomString(10)))

        XCTAssertFalse(sut.contains(item: item))
    }
}
