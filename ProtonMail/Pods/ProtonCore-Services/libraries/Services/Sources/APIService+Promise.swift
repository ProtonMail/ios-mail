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

// swiftlint:disable todo

import Foundation
import ProtonCore_Networking
import PromiseKit
import AwaitKit

public extension APIService {

    @available(*, deprecated, message: "ProtonCore is moving away from PromiseKit. Please switch to other available APIs")
    func run<T>(route: Request) -> Promise<T> where T: Response {

        let deferred = Promise<T>.pending()
        let completionWrapper: CompletionBlock = { task, responseDict, error in
            switch Response.parseNetworkCallResults(to: T.self, response: task?.response, responseDict: responseDict, error: error) {
            case (_, let networkingError?):
                deferred.resolver.reject(networkingError)
            case (let response, nil):
                deferred.resolver.fulfill(response)
            }
        }

        self.request(method: route.method,
                     path: route.path,
                     parameters: route.parameters,
                     headers: route.header,
                     authenticated: route.isAuth,
                     autoRetry: route.autoRetry,
                     customAuthCredential: route.authCredential,
                     nonDefaultTimeout: route.nonDefaultTimeout,
                     completion: completionWrapper)

        return deferred.promise
    }
}
