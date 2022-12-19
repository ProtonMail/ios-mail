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

class SaveToolbarActionSettingsForUsersUseCaseTests: XCTestCase {
    var sut: SaveToolbarActionSettingsForUsersUseCase!
    var firstUserAPI: APIServiceMock!
    var firstUserID: UserID = "1"
    var firstUserInfo: UserInfo!

    override func setUp() {
        super.setUp()
        firstUserAPI = APIServiceMock()
        firstUserInfo = makeUserInfo(userID: firstUserID)
        sut = SaveToolbarActionSettings(
            dependencies: .init(apiService: firstUserAPI,
                                userInfo: firstUserInfo)
        )
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        firstUserAPI = nil
        firstUserInfo = nil
    }

    func testExecute() {
        let e = expectation(description: "Closure is called")
        let conversationActions: [MessageViewActionSheetAction] = [.reply, .markUnread, .star]
        prepareAPIStub(
            of: firstUserAPI,
            conversationActions: conversationActions,
            messageActions: nil,
            listViewActions: nil
        )

        let preference = ToolbarActionPreference(
            conversationActions: conversationActions,
            messageActions: nil,
            listViewActions: nil
        )
        sut.executionBlock(params: .init(preference: preference)) { result in
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
        let conversationActions: [MessageViewActionSheetAction] = [.reply, .markUnread, .star]
        firstUserAPI.requestJSONStub.bodyIs { _, _, _, _, _, _, _, _, _, _, completion in
            let error = NSError.apiServiceError(code: 404, localizedDescription: "", localizedFailureReason: "")
            completion(nil, .failure(error))
        }

        let preference = ToolbarActionPreference(
            conversationActions: conversationActions,
            messageActions: nil,
            listViewActions: nil
        )
        sut.executionBlock(params: .init(preference: preference)) { result in
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
            conversationActions: nil,
            messageActions: nil,
            listViewActions: nil
        )
        sut.executionBlock(params: .init(preference: preference)) { result in
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

    private func makeUserInfo(userID: UserID) -> UserInfo {
        return UserInfo(maxSpace: nil,
                        usedSpace: nil,
                        language: nil,
                        maxUpload: nil,
                        role: nil,
                        delinquent: nil,
                        keys: nil,
                        userId: userID.rawValue,
                        linkConfirmation: nil,
                        credit: nil,
                        currency: nil,
                        subscribed: nil)
    }

    private func prepareAPIStub(
        of api: APIServiceMock,
        conversationActions: [MessageViewActionSheetAction]?,
        messageActions: [MessageViewActionSheetAction]?,
        listViewActions: [MessageViewActionSheetAction]?
    ) {
        api.requestJSONStub.bodyIs { _, _, path, parameter, _, _, _, _, _, _, completion in
            if let parameter = parameter as? [String: Any] {
                if let actions = conversationActions,
                   let req = parameter["ConversationToolbar"] as? [String] {
                    let converted = ServerToolbarAction.convert(action: actions)
                    XCTAssertEqual(req, converted.map(\.rawValue))
                }
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
                let conversationActions: [String: Any] = [
                    "IsCustom": conversationActions != nil,
                    "Actions": (ServerToolbarAction.convert(action: conversationActions ?? [])).map(\.rawValue)
                ]
                let listActions: [String: Any] = [
                    "IsCustom": listViewActions != nil,
                    "Actions": (ServerToolbarAction.convert(action: listViewActions ?? [])).map(\.rawValue)
                ]
                let mailSettings: [String: Any] = [
                    "MessageToolbar": messageActions,
                    "ConversationToolbar": conversationActions,
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
