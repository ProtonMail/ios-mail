// Copyright (c) 2023 Proton Technologies AG
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

import ProtonCore_Networking

/*
 This API allows for marking email addresses and whole domains as spam or blocking them.

 See https://protonmail.gitlab-pages.protontech.ch/Slim-API/mail/#tag/IncomingDefaults
 */
enum IncomingDefaultsAPI {
    // This enum replicates `Message.Location` but is necessary, because the API does not accept Strings for the "Location" parameter.
    enum Location: Int, Codable {
        case inbox = 0
        case spam = 4
        case blocked = 14
    }

    static let path = "/\(Constants.App.API_PREFIXED)/incomingdefaults"
}

struct IncomingDefaultDTO: Parsable {
    enum CodingKeys: String, CodingKey {
        case email
        case id = "ID"
        case location
        case time
    }

    let email: String
    let id: String
    let location: IncomingDefaultsAPI.Location
    let time: Date
}

struct GetIncomingDefaultsRequest: Request {
    private let location: IncomingDefaultsAPI.Location
    private let page: Int

    var parameters: [String: Any]? {
        [
            "Location": location.rawValue,
            "Page": page
        ]
    }

    var path: String {
        IncomingDefaultsAPI.path
    }

    init(location: IncomingDefaultsAPI.Location, page: Int) {
        self.location = location
        self.page = page
    }
}

struct GetIncomingDefaultsResponse: APIDecodableResponse {
    let code: Int
    let incomingDefaults: [IncomingDefaultDTO]
    let total: Int
}

struct AddIncomingDefaultsRequest: Request {
    enum Target {
        case domain(String)
        case email(String)
    }

    private let location: IncomingDefaultsAPI.Location
    private let overwrite: Bool
    private let target: Target

    var method: HTTPMethod {
        .post
    }

    var parameters: [String: Any]? {
        var params: [String: Any] = [
            "Location": location.rawValue
        ]

        switch target {
        case .domain(let domain):
            params["Domain"] = domain
        case .email(let email):
            params["Email"] = email
        }

        return params
    }

    var path: String {
        "\(IncomingDefaultsAPI.path)?Overwrite=\(overwrite ? 1 : 0)"
    }

    init(location: IncomingDefaultsAPI.Location, overwrite: Bool = false, target: Target) {
        self.location = location
        self.overwrite = overwrite
        self.target = target
    }
}

struct AddIncomingDefaultsResponse: APIDecodableResponse {
    let code: Int
    let incomingDefault: IncomingDefaultDTO
    let undoToken: UndoTokenData
}

struct DeleteIncomingDefaultsRequest: Request {
    let parameters: [String: Any]?

    var method: HTTPMethod {
        .put
    }

    var path: String {
        "\(IncomingDefaultsAPI.path)/delete"
    }

    init(ids: [String]) {
        parameters = [
            "IDs": ids
        ]
    }
}

struct DeleteIncomingDefaultsResponse: APIDecodableResponse {
}
