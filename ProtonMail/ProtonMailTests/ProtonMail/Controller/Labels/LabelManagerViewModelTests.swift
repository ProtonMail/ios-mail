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

    private var mockLabelPublisher: MockLabelPublisherProtocol!
    private var mockLabelManagerRouter: MockLabelManagerRouterProtocol!
    private var mockUIDelegate: MockLabelManagerUIProtocol!
    private let indexToCreateNewLabel = IndexPath(row: 0, section: 0)

    override func setUp() {
        super.setUp()

        mockLabelManagerRouter = MockLabelManagerRouterProtocol()
        mockLabelPublisher = MockLabelPublisherProtocol()
        mockUIDelegate = MockLabelManagerUIProtocol()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        mockLabelManagerRouter = nil
        mockLabelPublisher = nil
        mockUIDelegate = nil
    }

    func testDidTapReorderBegin_changesViewModeToReorder() {
        sut = makeSUT(labelType: .label)
        sut.input.didTapReorderBegin()
        XCTAssertEqual(mockUIDelegate.viewModeDidChangeStub.callCounter, 1)
        XCTAssertEqual(mockUIDelegate.viewModeDidChangeStub.lastArguments?.value, .reorder)
    }

    func testDidTapReorderEnd_changesViewModeToReorder() {
        sut = makeSUT(labelType: .label)
        sut.input.didTapReorderBegin()
        sut.input.didTapReorderEnd()
        XCTAssertEqual(mockUIDelegate.viewModeDidChangeStub.lastArguments?.value, .list)
    }

    func testDidSelectItem_toCreateNewItem_whenItemMaxNotReached() {
        sut = makeSUT(labelType: .label)
        sut.didSelectItem(at: indexToCreateNewLabel)
        XCTAssertEqual(mockLabelManagerRouter.navigateToLabelEditStub.callCounter, 1)
        XCTAssertEqual(mockUIDelegate.showAlertMaxItemsReachedStub.callCounter, 0)
    }

    func testDidSelectItem_toCreateNewItem_whenItemMaxReached() {
        sut = makeSUT(labelType: .label, dependencies: makeSUTDependencies(numLabelsToReturn: 3))
        sut.didSelectItem(at: indexToCreateNewLabel)
        XCTAssertEqual(mockLabelManagerRouter.navigateToLabelEditStub.callCounter, 0)
        XCTAssertEqual(mockUIDelegate.showAlertMaxItemsReachedStub.callCounter, 1)
    }

    func testDidSelectItem_toViewDetail() {
        sut = makeSUT(labelType: .label)
        sut.didSelectItem(at: indexToCreateNewLabel)
        XCTAssertEqual(mockLabelManagerRouter.navigateToLabelEditStub.callCounter, 1)
    }
}

extension LabelManagerViewModelTests {

    func makeSUT(
        labelType: PMLabelType,
        dependencies: LabelManagerViewModel.Dependencies? = nil
    ) -> LabelManagerViewModel {
        let depend = dependencies ?? makeSUTDependencies()
        let vm = LabelManagerViewModel(router: mockLabelManagerRouter, type: labelType, dependencies: depend)

        mockLabelPublisher.delegateStub.fixture = vm
        vm.output.setUIDelegate(mockUIDelegate)
        vm.input.viewDidLoad()

        return vm
    }

    func makeSUTDependencies(numLabelsToReturn: Int = 2) -> LabelManagerViewModel.Dependencies {
        let mockApiService = APIServiceMock()
        let mockUserManager = UserManager(api: mockApiService, role: .owner, userInfo: UserInfo.getDefault())
        mockLabelPublisher.fetchLabelsStub.bodyIs { [unowned self] _, _ in
            let labelsToReturn = LabelEntity.makeMocks(num: numLabelsToReturn)
            self.mockLabelPublisher.delegate?.receivedLabels(labels: labelsToReturn)
        }
        let dependencies = LabelManagerViewModel.Dependencies(
            userInfo: mockUserManager.userInfo,
            apiService: mockUserManager.apiService,
            labelService: mockUserManager.labelService,
            labelPublisher: mockLabelPublisher,
            userManagerSaveAction: mockUserManager,
            mailSettingsHandler: mockUserManager
        )
        return dependencies
    }
}
