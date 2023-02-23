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

import Foundation
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_Services

/// This use case updates the toolbar action inside the userInfo of the user passed in.
/// It sends a request to update the mailSettings of the user. Then, update the
/// mailSettings by the response of the API.
typealias SaveToolbarActionSettingsForUsersUseCase = NewUseCase<Void, SaveToolbarActionSettings.Params>

struct ToolbarActionPreference {
    let conversationActions: [MessageViewActionSheetAction]?
    let messageActions: [MessageViewActionSheetAction]?
    let listViewActions: [MessageViewActionSheetAction]?
}

enum UpdateToolbarActionError: Error {
    case invalidInput
    case backendSaveError(error: ResponseError)
}

final class SaveToolbarActionSettings: SaveToolbarActionSettingsForUsersUseCase {

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    override func executionBlock(params: Params, callback: @escaping NewUseCase<Void, Params>.Callback) {
        let conversationActions = params.preference.conversationActions
            .map(ServerToolbarAction.convert)
        let messageActions = params.preference.messageActions
            .map(ServerToolbarAction.convert)
        let listViewActions = params.preference.listViewActions
            .map(ServerToolbarAction.convert)

        guard let request = UpdateToolbarActionSettingRequest(
            message: messageActions,
            conversation: conversationActions,
            listView: listViewActions
        ) else {
            callback(.failure(UpdateToolbarActionError.invalidInput))
            return
        }

        dependencies.apiService.perform(
            request: request,
            response: MailSettingsResponse()
        ) { _, response in
            if let error = response.error {
                callback(.failure(UpdateToolbarActionError.backendSaveError(error: error)))
            } else {
                self.updateToolbarActions(response: response)
                callback(.success)
            }
        }
    }

    private func updateToolbarActions(response: MailSettingsResponse) {
        dependencies.userInfo.parse(mailSettings: response.mailSettings)
    }
}

extension SaveToolbarActionSettings {
    struct Params {
        let preference: ToolbarActionPreference
    }

    struct Dependencies {
        let apiService: APIService
        let userInfo: UserInfo

        init(user: UserManager) {
            apiService = user.apiService
            userInfo = user.userInfo
        }

        init(apiService: APIService, userInfo: UserInfo) {
            self.apiService = apiService
            self.userInfo = userInfo
        }
    }
}
