//
//  ProtonRetryPolicy.swift
//  ProtonCore-Networking - Created on 7/14/22.
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

#if canImport(Alamofire)
import Alamofire
import Foundation

public final class ProtonRetryPolicy {

    public enum RetryMode {
        case userInitiated
        case background
    }

    private let mode: RetryMode
    private let retryLimit: Int
    private let exponentialBackoffBase: Int
    private let exponentialBackoffScale: Double

    init(mode: RetryMode = .userInitiated,
         retryLimit: Int = 3,
         exponentialBackoffBase: Int = 2,
         exponentialBackoffScale: Double = 0.5) {
        self.mode = mode
        self.retryLimit = retryLimit
        self.exponentialBackoffBase = exponentialBackoffBase
        self.exponentialBackoffScale = exponentialBackoffScale
    }

    public func retry(statusCode: Int?,
                      retryCount: Int,
                      headers: HTTPHeaders?,
                      completion: @escaping (RetryResult) -> Void) {
        guard mode == .background, retryCount < retryLimit, let statusCode = statusCode else {
            completion(.doNotRetry)
            return
        }

        let defaultDelay = delayWithJitter(retryCount: retryCount)

        if [503, 429].contains(statusCode) {
            guard let delay = retryAfter(headers) else {
                completion(.retryWithDelay(defaultDelay))
                return
            }
            completion(.retryWithDelay(delay.withJitter()))
            return
        }

        if [408, 502].contains(statusCode) {
            guard retryCount < 1 else {
                completion(.doNotRetry)
                return
            }
            completion(.retryWithDelay(defaultDelay))
            return
        }
        completion(.retryWithDelay(defaultDelay))
    }

    private func retryAfter(_ headers: HTTPHeaders?) -> Double? {
        guard let retryAfterHeader = headers?.first(where: { header in header.name == "Retry-After" }),
              let delay = Double(retryAfterHeader.value), // assuming the value is in seconds
              delay > 0 else {
            return nil
        }
        return delay
    }

    private func delayWithJitter(retryCount: Int) -> Double {
        let delay = pow(Double(exponentialBackoffBase), Double(retryCount)) * exponentialBackoffScale
        return delay.withJitter()
    }
}

extension ProtonRetryPolicy: RequestInterceptor {
    public func retry(_ request: Alamofire.Request,
                      for session: Alamofire.Session,
                      dueTo error: Error,
                      completion: @escaping (RetryResult) -> Void) {
        retry(statusCode: request.response?.statusCode,
              retryCount: request.retryCount,
              headers: request.response?.headers,
              completion: completion)
    }
}

private extension Double {
    func withJitter() -> Double {
        self + Double.random(in: 0..<(self / 2))
    }
}

#endif
