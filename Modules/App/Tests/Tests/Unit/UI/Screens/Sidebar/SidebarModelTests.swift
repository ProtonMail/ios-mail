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

import InboxTesting
import XCTest
import proton_app_uniffi

@testable import ProtonMail

@MainActor
final class SidebarModelTests {
    private lazy var sut = SidebarModel(state: .initial, sidebar: sidebarSpy, upsellEligibilityPublisher: .init(constant: .eligible(.standard)))
    private let sidebarSpy = SidebarSpy()

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

    func test_WhenChildFolderIsSelected_WhenFoldersAreUpdated_ItStaysSelected() throws {
        let folderName = PMCustomFolder.superPrivate.name

        XCTAssertEqual(try getFolder(with: folderName).isSelected, false)
        sut.handle(action: .select(item: .folder(try getFolder(with: folderName))))
        XCTAssertEqual(try getFolder(with: folderName).isSelected, true)

        emitData()

        XCTAssertEqual(try getFolder(with: folderName).isSelected, true)
    }

    func test_WhenTappingOnSettingsItem_ItDoesNotSelectIt() throws {
        let settingsUnselected = try XCTUnwrap(sut.state.other.findFirst(for: .settings, by: \.type))
        XCTAssertEqual(settingsUnselected.isSelected, false)

        sut.handle(action: .select(item: .other(settingsUnselected)))
        let settingsSelected = try XCTUnwrap(sut.state.other.findFirst(for: .settings, by: \.type))
        XCTAssertEqual(settingsSelected.isSelected, false)
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

    func test_WhenCustomFolderIsExpandedAndCollapsed_ItExpandsAndCollapsesTheFolder() throws {
        let parentFolder = try XCTUnwrap(
            sidebarSpy.stubbedCustomFolders.first(where: { !$0.children.isEmpty })
        ).sidebarFolder

        XCTAssertEqual(sidebarSpy.expandFolderInvoked, [])
        XCTAssertEqual(sidebarSpy.collapseFolderInvoked, [])

        sut.handle(action: .toggle(folder: parentFolder, expand: true))
        XCTAssertEqual(sidebarSpy.expandFolderInvoked, [parentFolder.folderID])
        XCTAssertEqual(sidebarSpy.collapseFolderInvoked, [])

        sut.handle(action: .toggle(folder: parentFolder, expand: false))
        XCTAssertEqual(sidebarSpy.collapseFolderInvoked, [parentFolder.folderID])
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

    private func getFolder(with name: String) throws -> SidebarFolder {
        try XCTUnwrap(sut.state.find(folderWithName: name, in: sut.state.folders))
    }
}

extension SidebarState {
    func find(folderWithName name: String, in folders: [SidebarFolder]) -> SidebarFolder? {
        folders.compactMap { folder in
            folder.name == name ? folder : find(folderWithName: name, in: folder.childFolders)
        }.first
    }
}
