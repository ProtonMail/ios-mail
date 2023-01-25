//
//  SessionsRequest.swift
//  ProtonCore-Services - Created on 7/12/22.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCore_Networking
import ProtonCore_Doh

final class SessionsRequestResponse: Response, Codable {
    public let accessToken: String
    public let refreshToken: String
    public let tokenType: String
    public let scopes: [String]
    public let UID: String
}

final class SessionsRequest: Request {
    let path = "/auth/v4/sessions"
    let method: HTTPMethod = .post
    let isAuth = false
}

extension PMAPIService {
    
    func performSessionsRequest(completion: @escaping (Result<Credential, ResponseError>) -> Void) {
        let sessionsRequest = SessionsRequest()
        sessionRequest(request: sessionsRequest) { (task, result: Result<SessionsRequestResponse, APIError>) in
            switch result {
            case .success(let sessionsResponse):
                let credential = Credential(UID: sessionsResponse.UID, accessToken: sessionsResponse.accessToken, refreshToken: sessionsResponse.refreshToken, userName: "", userID: "", scopes: sessionsResponse.scopes)
                completion(.success(credential))
            case .failure(let error):
                let httpCode = task.flatMap(\.response).flatMap { $0 as? HTTPURLResponse }.map(\.statusCode)
                let responseCode = error.domain == ResponseErrorDomains.withResponseCode.rawValue ? error.code : nil
                completion(.failure(.init(httpCode: httpCode, responseCode: responseCode, userFacingMessage: error.localizedDescription, underlyingError: error)))
            }
        }
    }
}
