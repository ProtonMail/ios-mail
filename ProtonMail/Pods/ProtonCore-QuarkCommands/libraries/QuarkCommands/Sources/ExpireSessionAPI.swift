//
//  ExpireSessionAPI.swift
//  ProtonCore-QuarkCommands - Created on 19.05.2022.
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
//

import Foundation

public enum ExpireSessionError: Error {
    case cannotConstructUrl
    case callFailedOfUnknownReason(responseBody: String?)
    case callFailed(reason: Error)
}

extension QuarkCommands {
    public static func expireSession(currentlyUsedHostUrl host: String,
                                     username: String,
                                     expireRefreshToken: Bool = false,
                                     callCompletionBlockOn: DispatchQueue = .main,
                                     completion: @escaping (Result<Void, ExpireSessionError>) -> Void) {
        var urlString = "\(host)/internal/quark/user:expire:sessions?User=\(username)"
        if expireRefreshToken {
            urlString += "&--refresh=null"
        }
        
        let completion: (Result<Void, ExpireSessionError>) -> Void = { result in
            callCompletionBlockOn.async { completion(result) }
        }

        guard let url = URL(string: urlString) else { completion(.failure(.cannotConstructUrl)); return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(.callFailed(reason: error)))
                return
            }
            
            let body = data.flatMap { String(data: $0, encoding: .utf8) }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(.callFailedOfUnknownReason(responseBody: body)))
                return
            }
            completion(.success(()))
        }.resume()
    }
}
