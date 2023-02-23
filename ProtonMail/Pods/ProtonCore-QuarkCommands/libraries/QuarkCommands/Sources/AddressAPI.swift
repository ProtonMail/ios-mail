//
//  AddressAPI.swift
//  ProtonCore-QuarkCommands - Created on 11.12.2021.
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

import ProtonCore_Log

public enum AddAccountEmailError: Error {
    case cannotConstructUrl
    case cannotDecodeResponseBody
    case responseError(String)
    case actualError(Error)
    
    public var userFacingMessageInQuarkCommands: String {
        switch self {
        case .cannotConstructUrl: return "cannot construct url"
        case .cannotDecodeResponseBody: return "cannot decode response body"
        case .responseError(let error): return "response error: \(error)"
        case .actualError(let error): return "actual error: \(error.messageForTheUser)"
        }
    }
}
extension QuarkCommands {
    // swiftlint:disable function_parameter_count
    public static func addEmailToAccount(currentlyUsedHostUrl host: String,
                                         userID: String,
                                         password: String,
                                         email: String,
                                         isGenerateKey: Bool,
                                         callCompletionBlockOn: DispatchQueue = .main,
                                         completion: @escaping (Result<Bool, AddAccountEmailError>) -> Void) {
        var urlString: String = "\(host)/internal/quark/user:create:address?userID=\(userID)&password=\(password)&email=\(email)"
        if !isGenerateKey {
            urlString.append("&--gen-keys=None")
        }
        guard let url = URL(string: urlString) else { completion(.failure(.cannotConstructUrl)); return }
        
        let completion: (Result<Bool, AddAccountEmailError>) -> Void = { result in
            callCompletionBlockOn.async { completion(result) }
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let input = String(data: data, encoding: .utf8) else {
                guard let error = error else { completion(.failure(.cannotDecodeResponseBody)); return }
                completion(.failure(.actualError(error)))
                return
            }
            guard input.contains("New address information:") else {
                completion(.failure(.responseError(input)))
                return
            }
            completion(.success(true))
        }.resume()
    }
}

public func addAddress(userID: String,
                       password: String,
                       email: String,
                       isGenerateKey: Bool = true,
                       currentlyUsedHostUrl host: String) -> Bool {
    let semaphore = DispatchSemaphore(value: 0)
    var result: Bool = false
    QuarkCommands.addEmailToAccount(currentlyUsedHostUrl: host,
                                    userID: userID,
                                    password: password,
                                    email: email,
                                    isGenerateKey: isGenerateKey,
                                    callCompletionBlockOn: .global(qos: .userInitiated)){ completion in
        switch completion {
        case .failure(let error):
            PMLog.debug(error.userFacingMessageInQuarkCommands)
        case .success(let details):
            result = details
        }
        semaphore.signal()
    }
    semaphore.wait()
    return result
}
