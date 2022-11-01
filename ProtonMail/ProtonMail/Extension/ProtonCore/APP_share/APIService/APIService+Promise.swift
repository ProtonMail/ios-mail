//
//  APIService.swift
//  ProtonCore-Services - Created on 5/22/20.
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

import AwaitKit
import Foundation
import PromiseKit
import ProtonCore_Networking
import ProtonCore_Services

public extension APIService {

    func run<T>(route: Request) -> Promise<T> where T: Response {

        let deferred = Promise<T>.pending()
        typealias Completion = (URLSessionDataTask?, Swift.Result<JSONDictionary, ResponseError>) -> Void
        let completionWrapper: Completion = { task, result in
            switch Response.parseNetworkCallResults(
                responseObject: T(),
                originalResponse: task?.response,
                responseDict: try? result.get(),
                error: result.nsError
            ) {
            case (_, let networkingError?):
                deferred.resolver.reject(networkingError)
            case (let response, nil):
                deferred.resolver.fulfill(response)
            }
        }

        self.perform(request: route, jsonDictionaryCompletion: completionWrapper)

        return deferred.promise
    }
}
