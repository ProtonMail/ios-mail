//
//  ProtonMailAPIService.swift
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

import Foundation
import ProtonCoreNetworking

public protocol APIServiceLoggingDelegate: AnyObject {
    func accessTokenRefreshDidStart(for sessionID: String,
                                    sessionType: APISessionTypeForLogging)
    func accessTokenRefreshDidSucceed(for sessionID: String,
                                      sessionType: APISessionTypeForLogging,
                                      reason: APIServiceAccessTokenRefreshSuccessReasonForLogging)
    func accessTokenRefreshDidFail(for sessionID: String,
                                   sessionType: APISessionTypeForLogging,
                                   error: APIServiceAccessTokenRefreshErrorForLogging)
}

// MARK: - Access token refresh logging

public enum APISessionTypeForLogging: String, Equatable {
    case authenticated
    case unauthenticated

    static func from(_ credential: Credential) -> Self {
        credential.isForUnauthenticatedSession ? .unauthenticated : .authenticated
    }

    static func from(_ authCredential: AuthCredential) -> Self {
        authCredential.isForUnauthenticatedSession ? .unauthenticated : .authenticated
    }
}

public enum APIServiceAccessTokenRefreshSuccessReasonForLogging: String, Equatable {
    case accessTokenRefreshed
    case freshAccessTokenAlreadyAvailable
}

public enum APIServiceAccessTokenRefreshErrorForLogging: Error, LocalizedError {
    case noAuthDelegate
    case noAccessTokenToBeRefreshed
    case tooManyRefreshingAttempts
    case legacyRefreshFailedWithLogout
    case localCacheBadRefreshRetried
    case refreshFailedWithAuthError(AuthErrors)
    case unauthSessionInvalidatedAndRefetched
    case refreshFailedWithLogout

    public var errorDescription: String? {
        switch self {
        case .noAuthDelegate: return ".noAuthDelegate"
        case .noAccessTokenToBeRefreshed: return ".noAccessTokenToBeRefreshed"
        case .tooManyRefreshingAttempts: return ".tooManyRefreshingAttempts"
        case .legacyRefreshFailedWithLogout: return ".legacyRefreshFailedWithLogout"
        case .localCacheBadRefreshRetried: return ".localCacheBadRefreshRetried"
        case .refreshFailedWithAuthError(let authErrors): return ".refreshFailedWithAuthError: \(authErrors.localizedDescription)"
        case .unauthSessionInvalidatedAndRefetched: return ".unauthSessionInvalidatedAndRefetched"
        case .refreshFailedWithLogout: return ".refreshFailedWithLogout"
        }
    }
}
