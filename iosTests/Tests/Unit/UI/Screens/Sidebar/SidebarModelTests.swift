// Copyright (c) 2024 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

@testable import ProtonMail
import XCTest
import proton_mail_uniffi

class SidebarModelTests: BaseTestCase {

    var sut: SidebarModel!
    var sidebarSpy: SidebarSpy!

    override func setUp() {
        super.setUp()

        sidebarSpy = .init()
        sut = .init(state: .initial, sidebar: sidebarSpy)

        sut.handle(action: .viewAppear)
        emitData()
    }

    override func tearDown() {
        sut = nil
        sidebarSpy = nil

        super.tearDown()
    }

    func test_WhenAppear_ItSelectsFirstSystemFolder() throws {
        let firstUnselectedSystemFolder = try XCTUnwrap(sut.state.system.first)
        XCTAssertEqual(firstUnselectedSystemFolder.isSelected, true)
    }

    func test_WhenTappingOnSecondSystemFolder_ItSelectsIt() throws {
        let firstUnselectedSystemFolder = try XCTUnwrap(sut.state.system.last)
        XCTAssertEqual(firstUnselectedSystemFolder.isSelected, false)

        sut.handle(action: .select(item: .system(firstUnselectedSystemFolder)))
        let firstSelectedSystemFolder = try XCTUnwrap(sut.state.system.last)
        XCTAssertEqual(firstSelectedSystemFolder.isSelected, true)
    }

    func test_WhenTappingOnFirstLabel_ItSelectsIt() throws {
        let firstUnselectedLabel = try XCTUnwrap(sut.state.labels.first)
        XCTAssertEqual(firstUnselectedLabel.isSelected, false)

        sut.handle(action: .select(item: .label(firstUnselectedLabel)))
        let firstSelectedLabel = try XCTUnwrap(sut.state.labels.first)
        XCTAssertEqual(firstSelectedLabel.isSelected, true)
    }

    func test_WhenTappingOnFirstFolder_ItSelectsIt() throws {
        let firstUnselectedFolder = try XCTUnwrap(sut.state.folders.first)
        XCTAssertEqual(firstUnselectedFolder.isSelected, false)

        sut.handle(action: .select(item: .folder(firstUnselectedFolder)))
        let firstSelectedFolder = try XCTUnwrap(sut.state.folders.first)
        XCTAssertEqual(firstSelectedFolder.isSelected, true)
    }

    func test_WhenTappingOnSubscriptionItem_ItDoesNotSelectIt() throws {
        let subscriptionUnselected = try XCTUnwrap(sut.state.other.findFirst(for: .subscriptions, by: \.type))
        XCTAssertEqual(subscriptionUnselected.isSelected, false)

        sut.handle(action: .select(item: .other(subscriptionUnselected)))
        let subscriptionSelected = try XCTUnwrap(sut.state.other.findFirst(for: .subscriptions, by: \.type))
        XCTAssertEqual(subscriptionSelected.isSelected, false)
    }

    func test_WhenTappingOnShareLogsItem_ItDoesNotSelectIt() throws {
        let shareLogsUnselected = try XCTUnwrap(sut.state.other.findFirst(for: .shareLogs, by: \.type))
        XCTAssertEqual(shareLogsUnselected.isSelected, false)

        sut.handle(action: .select(item: .other(shareLogsUnselected)))
        let shareLogsStillUnselected = try XCTUnwrap(sut.state.other.findFirst(for: .shareLogs, by: \.type))
        XCTAssertEqual(shareLogsStillUnselected.isSelected, false)
    }

    func test_WhenLabelIsSelectedAndNewLabelIsAdded_ItKeepsSelectionAndAddsNewLabel() throws {
        let firstLabel = try XCTUnwrap(sut.state.labels.first)
        sut.handle(action: .select(item: .label(firstLabel)))
        XCTAssertEqual(sut.state.labels.count, 2)

        let newLabel = PMCustomLabel.testData(id: 5, name: "New label")
        let oldLabels = sidebarSpy.stubbedCustomLabels
        emit(labels: oldLabels + [newLabel])

        XCTAssertEqual(sut.state.labels.count, 3)
        let selectedLabel = try XCTUnwrap(sut.state.labels.first(where: \.isSelected))
        XCTAssertEqual(selectedLabel.id, firstLabel.id)
    }

    // MARK: - Private

    private func emitData() {
        sidebarSpy.stubbedSystemLabels = [.inbox, .sent]
        sidebarSpy.spiedWatchers[.system]?.onUpdate()

        sidebarSpy.stubbedCustomFolders = [.topSecretFolder]
        sidebarSpy.spiedWatchers[.folder]?.onUpdate()

        emit(labels: [.importantLabel, .topSecretLabel])
    }

    private func emit(labels: [PMCustomLabel]) {
        sidebarSpy.stubbedCustomLabels = labels
        sidebarSpy.spiedWatchers[.label]?.onUpdate()
    }

}
