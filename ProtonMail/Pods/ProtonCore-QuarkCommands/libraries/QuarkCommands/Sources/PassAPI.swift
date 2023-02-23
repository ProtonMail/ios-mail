//
//  PassAPI.swift
//  ProtonCore-QuarkCommands - Created on 30.11.2021.
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

public enum PassScopeError: Error {
    case cannotConstructUrl
    case cannotDecodeResponseBody
    case responseError(String)
    case actualError(Error)
}

extension QuarkCommands {
    public static func addPassScopeToUser(username: String,
                                          currentlyUsedHostUrl host: String,
                                          callCompletionBlockOn: DispatchQueue = .main,
                                          completion: @escaping (Result<Bool, PassScopeError>) -> Void) {
        let urlString = "\(host)/internal/quark/raw::pass:access:set?-u=\(username)"
        guard let url = URL(string: urlString) else {
            completion(.failure(.cannotConstructUrl))
            return
        }

        let completion: (Result<Bool, PassScopeError>) -> Void = { result in
            callCompletionBlockOn.async { completion(result) }
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let input = String(data: data, encoding: .utf8) else {
                guard let error = error else { completion(.failure(.cannotDecodeResponseBody)); return }
                completion(.failure(.actualError(error)))
                return
            }
            guard input.contains("User has access.") else {
                completion(.failure(.responseError(input)))
                return
            }
            completion(.success(true))
        }.resume()
    }
}
