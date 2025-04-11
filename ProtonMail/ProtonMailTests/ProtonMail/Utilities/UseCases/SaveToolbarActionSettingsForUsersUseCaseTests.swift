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
import ProtonCoreDataModel
import ProtonCoreTestingToolkitUnitTestsServices

class SaveToolbarActionSettingsForUsersUseCaseTests: XCTestCase {
    var sut: SaveToolbarActionSettingsForUsersUseCase!
    var firstUserAPI: APIServiceMock!
    private var firstUser: UserManager!

    override func setUp() {
        super.setUp()
        firstUserAPI = APIServiceMock()
        firstUser = UserManager(api: firstUserAPI)
        sut = SaveToolbarActionSettings(dependencies: .init(apiService: firstUserAPI, mailSettingsHandler: firstUser))
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        firstUserAPI = nil
        firstUser = nil
    }

    func testExecute() {
        let e = expectation(description: "Closure is called")
        let messageActions: [MessageViewActionSheetAction] = [.reply, .markUnread, .star]
        prepareAPIStub(
            of: firstUserAPI,
            messageActions: messageActions,
            listViewActions: nil
        )

        let preference = ToolbarActionPreference(
            messageActions: messageActions,
            listViewActions: nil
        )
        sut.execute(params: .init(preference: preference)) { result in
            switch result {
            case .failure(_):
                XCTFail("Should not return error")
            case .success():
                // TODO: Check update in userInfo
                break
            }
            e.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testExecute_withServerError() {
        let e = expectation(description: "Closure is called")
        let messageActions: [MessageViewActionSheetAction] = [.reply, .markUnread, .star]
        firstUserAPI.requestJSONStub.bodyIs { _, _, _, _, _, _, _, _, _, _, _, _, completion in
            let error = NSError.apiServiceError(code: 404, localizedDescription: "", localizedFailureReason: "")
            completion(nil, .failure(error))
        }

        let preference = ToolbarActionPreference(
            messageActions: messageActions,
            listViewActions: nil
        )
        sut.execute(params: .init(preference: preference)) { result in
            switch result {
            case .failure(let error):
                XCTAssertTrue(error is UpdateToolbarActionError)
            case .success():
                XCTFail("Should not reach here")
            }
            e.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testExecute_withAllNilInput() {
        let e = expectation(description: "Closure is called")

        let preference = ToolbarActionPreference(
            messageActions: nil,
            listViewActions: nil
        )
        sut.execute(params: .init(preference: preference)) { result in
            switch result {
            case .failure(let error):
                XCTAssertTrue(error is UpdateToolbarActionError)
            case .success():
                XCTFail("Should not reach here")
            }
            e.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testExecute_withDefaultAction() {
        let e = expectation(description: "Closure is called")
        let preference = ToolbarActionPreference(
            messageActions: MessageViewActionSheetAction.defaultActions,
            listViewActions: MessageViewActionSheetAction.defaultActions
        )

        firstUserAPI.requestJSONStub.bodyIs { _, _, path, parameter, _, _, _, _, _, _, _, _, completion in
            if let parameter = parameter as? [String: Any] {
                if let req = parameter["ConversationToolbar"] as? [String] {
                    XCTAssertTrue(req.isEmpty)
                }
                if let req = parameter["MessageToolbar"] as? [String] {
                    XCTAssertTrue(req.isEmpty)
                }
                if let req = parameter["ListToolbar"] as? [String] {
                    XCTAssertTrue(req.isEmpty)
                }
            }

            if path.contains("mail/v4/settings/mobilesettings") {
                let defaultActions: [String: Any] = [
                    "IsCustom": true,
                    "Actions": []
                ]
                let mailSettings: [String: Any] = [
                    "MessageToolbar": defaultActions,
                    "ConversationToolbar": defaultActions,
                    "ListToolbar": defaultActions
                ]
                let response: [String: Any] = [
                    "Code": 1000,
                    "MailSettings": mailSettings
                ]
                completion(nil, .success(response))
            } else {
                XCTFail("Unexpected path")
                completion(nil, .failure(.init(domain: "", code: 999)))
            }
        }

        sut.execute(params: .init(preference: preference)) { result in
            switch result {
            case .failure(_):
                XCTFail("Should not reach here")
            case .success():
                break
            }
            e.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    private func makeUserInfo(userID: UserID) -> UserInfo {
        return UserInfo(maxSpace: nil,
                        maxBaseSpace: nil,
                        maxDriveSpace: nil,
                        usedSpace: nil,
                        usedBaseSpace: nil,
                        usedDriveSpace: nil,
                        language: nil,
                        maxUpload: nil,
                        role: nil,
                        delinquent: nil,
                        keys: nil,
                        userId: userID.rawValue,
                        linkConfirmation: nil,
                        credit: nil,
                        currency: nil,
                        createTime: nil,
                        subscribed: nil,
                        edmOptOut: nil)
    }

    private func prepareAPIStub(
        of api: APIServiceMock,
        messageActions: [MessageViewActionSheetAction]?,
        listViewActions: [MessageViewActionSheetAction]?
    ) {
        api.requestJSONStub.bodyIs { _, _, path, parameter, _, _, _, _, _, _, _, _, completion in
            if let parameter = parameter as? [String: Any] {
                if let actions = messageActions,
                   let req = parameter["MessageToolbar"] as? [String] {
                    let converted = ServerToolbarAction.convert(action: actions)
                    XCTAssertEqual(req, converted.map(\.rawValue))
                }
                if let actions = listViewActions,
                   let req = parameter["ListToolbar"] as? [String] {
                    let converted = ServerToolbarAction.convert(action: actions)
                    XCTAssertEqual(req, converted.map(\.rawValue))
                }
            }

            if path.contains("mail/v4/settings/mobilesettings") {
                let messageActions: [String: Any] = [
                    "IsCustom": messageActions != nil,
                    "Actions": (ServerToolbarAction.convert(action: messageActions ?? [])).map(\.rawValue)
                ]
                let listActions: [String: Any] = [
                    "IsCustom": listViewActions != nil,
                    "Actions": (ServerToolbarAction.convert(action: listViewActions ?? [])).map(\.rawValue)
                ]
                let mailSettings: [String: Any] = [
                    "MessageToolbar": messageActions,
                    "ListToolbar": listActions
                ]
                let response: [String: Any] = [
                    "Code": 1000,
                    "MailSettings": mailSettings
                ]
                completion(nil, .success(response))
            } else {
                XCTFail("Unexpected path")
                completion(nil, .failure(.init(domain: "", code: 999)))
            }
        }
    }
}
