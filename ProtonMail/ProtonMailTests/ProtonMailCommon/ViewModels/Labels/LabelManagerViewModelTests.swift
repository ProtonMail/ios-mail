// Copyright (c) 2022 Proton AG
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

import XCTest
@testable import ProtonMail
import ProtonCore_DataModel
import ProtonCore_TestingToolkit

class LabelManagerViewModelTests: XCTestCase {
    private var sut: LabelManagerViewModel!

    private var mockLabelManagerRouter = MockLabelManagerRouter()
    private var mockUIDelegate: MockLabelManagerUIProtocol!
    private let indexToCreateNewLabel = IndexPath(row: 0, section: 0)

    override func setUp() {
        super.setUp()
        mockUIDelegate = MockLabelManagerUIProtocol()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        mockUIDelegate = nil
    }

    func testDidTapReorderBegin_changesViewModeToReorder() {
        sut = makeSUT(labelType: .label)
        sut.input.didTapReorderBegin()
        XCTAssertTrue(mockUIDelegate.wasCalledViewModeDidChange)
        XCTAssertEqual(mockUIDelegate.viewMode, LabelManagerViewModel.ViewMode.reorder)
    }

    func testDidTapReorderEnd_changesViewModeToReorder() {
        sut = makeSUT(labelType: .label)
        sut.input.didTapReorderBegin()
        sut.input.didTapReorderEnd()
        XCTAssertEqual(mockUIDelegate.viewMode, LabelManagerViewModel.ViewMode.list)
    }

    func testDidSelectItem_toCreateNewItem_whenItemMaxNotReached() {
        sut = makeSUT(labelType: .label)
        sut.didSelectItem(at: indexToCreateNewLabel)
        XCTAssertTrue(mockLabelManagerRouter.wasNavigateToLabelEditCalled)
        XCTAssertFalse(mockUIDelegate.wasShowAlertMaxItemsReached)
    }

    func testDidSelectItem_toCreateNewItem_whenItemMaxReached() {
        sut = makeSUT(labelType: .label, dependencies: makeSUTDependencies(numLabelsToReturn: 3))
        sut.didSelectItem(at: indexToCreateNewLabel)
        XCTAssertFalse(mockLabelManagerRouter.wasNavigateToLabelEditCalled)
        XCTAssertTrue(mockUIDelegate.wasShowAlertMaxItemsReached)
    }

    func testDidSelectItem_toViewDetail() {
        sut = makeSUT(labelType: .label)
        sut.didSelectItem(at: indexToCreateNewLabel)
        XCTAssertTrue(mockLabelManagerRouter.wasNavigateToLabelEditCalled)
    }
}

extension LabelManagerViewModelTests {

    func makeSUT(
        labelType: PMLabelType,
        dependencies: LabelManagerViewModel.Dependencies? = nil
    ) -> LabelManagerViewModel {
        let depend = dependencies ?? makeSUTDependencies()
        let vm = LabelManagerViewModel(router: mockLabelManagerRouter, type: labelType, dependencies: depend)

        depend.labelPublisher.delegate = vm
        vm.output.setUIDelegate(mockUIDelegate)
        vm.input.viewDidLoad()

        return vm
    }

    func makeSUTDependencies(numLabelsToReturn: Int = 2) -> LabelManagerViewModel.Dependencies {
        let mockApiService = APIServiceMock()
        let mockUserManager = UserManager(api: mockApiService, role: .owner, userInfo: UserInfo.getDefault())
        let mockLabelPublisher = MockLabelPublisher()
        mockLabelPublisher.labelsToReturn = LabelEntity.makeMocks(num: numLabelsToReturn)
        let dependencies = LabelManagerViewModel.Dependencies(
            userInfo: mockUserManager.userInfo,
            apiService: mockUserManager.apiService,
            labelService: mockUserManager.labelService,
            labelPublisher: mockLabelPublisher,
            userManagerSaveAction: mockUserManager
        )
        return dependencies
    }
}

private class MockLabelManagerRouter: LabelManagerRouterProtocol {
    private(set) var wasNavigateToLabelEditCalled: Bool = false

    func navigateToLabelEdit(
        editMode: LabelEditMode,
        labels: [MenuLabel],
        type: PMLabelType,
        userInfo: UserInfo,
        labelService: LabelsDataService
    ) {
        wasNavigateToLabelEditCalled = true
    }
}

private class MockLabelManagerUIProtocol: LabelManagerUIProtocol {
    private(set) var wasCalledViewModeDidChange: Bool = false
    private(set) var wasShowAlertMaxItemsReached: Bool = false
    private(set) var viewMode: LabelManagerViewModel.ViewMode = .list

    func viewModeDidChange(mode: LabelManagerViewModel.ViewMode) {
        wasCalledViewModeDidChange = true
        viewMode = mode
    }

    func showLoadingHUD() {}

    func hideLoadingHUD() {}

    func reloadData() {}

    func reload(section: Int) {}

    func showToast(message: String) {}

    func showAlertMaxItemsReached() {
        wasShowAlertMaxItemsReached = true
    }

    func showNoInternetConnectionToast() {}
}
