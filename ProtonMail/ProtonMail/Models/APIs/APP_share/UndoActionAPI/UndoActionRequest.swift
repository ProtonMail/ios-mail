// Copyright (c) 2021 Proton AG
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
import ProtonCore_Networking

struct UndoActionRequest: Request {
    var auth: AuthCredential?
    let token: String

    init(token: String) {
        self.token = token
    }

    var authCredential: AuthCredential? {
        return self.auth
    }

    var path: String {
        return "/\(Constants.App.API_PREFIXED)/undoactions"
    }

    var method: HTTPMethod {
        return .post
    }

    var isAuth: Bool {
        return true
    }

    var parameters: [String: Any]? {
        let body = [
            "Token": token
        ]
        return body
    }
}

struct UndoActionResponse: APIDecodableResponse {
    var code: Int?
    var error: String?
    var details: HumanVerificationDetails?
}
