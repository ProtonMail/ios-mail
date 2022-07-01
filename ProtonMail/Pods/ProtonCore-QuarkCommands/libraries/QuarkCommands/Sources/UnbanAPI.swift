//
//  UnbanAPI.swift
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
import ProtonCore_Doh
import ProtonCore_Services

public typealias UnbanDetails = Void

public enum UnbanError: Error {
    case cannotConstructUrl
    case callFailedOfUnknownReason(responseBody: String?)
    case callFailed(reason: Error)
}

extension QuarkCommands {
    
    public static func unban(currentlyUsedHostUrl host: String,
                             callCompletionBlockOn: DispatchQueue = .main,
                             completion: @escaping (Result<UnbanDetails, UnbanError>) -> Void) {
        
        let urlString = "\(host)/internal/quark/jail:unban"
        performCommand(url: urlString, currentlyUsedHostUrl: host, callCompletionBlockOn: callCompletionBlockOn, completion: completion)
    }
    
    public static func disableJail(currentlyUsedHostUrl host: String,
                                   callCompletionBlockOn: DispatchQueue = .main,
                                   completion: @escaping (Result<UnbanDetails, UnbanError>) -> Void) {
        let urlString = "\(host)/internal/system?JAILS_ENABLED=0"
        performCommand(url: urlString, currentlyUsedHostUrl: host, callCompletionBlockOn: callCompletionBlockOn, completion: completion)
    }
    
    public static func performCommand(url urlString: String,
                                      currentlyUsedHostUrl: String,
                                      callCompletionBlockOn: DispatchQueue = .main,
                                      completion: @escaping (Result<UnbanDetails, UnbanError>) -> Void) {
        
        guard let url = URL(string: urlString) else { completion(.failure(.cannotConstructUrl)); return }
        
        let completion: (Result<UnbanDetails, UnbanError>) -> Void = { result in
            callCompletionBlockOn.async { completion(result) }
        }
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

@available(*, deprecated, message: "Use asynchronous variant unban(currentlyUsedHostUrl:completion:)")
public func executeQuarkUnban(doh: DoH & ServerConfig, serviceDelegate: APIServiceDelegate) {
    let semaphore = DispatchSemaphore(value: 0)
    QuarkCommands.unban(currentlyUsedHostUrl: doh.getCurrentlyUsedHostUrl(),
                        callCompletionBlockOn: .global(qos: .userInitiated)) { _ in
        semaphore.signal()
    }
    semaphore.wait()
}
