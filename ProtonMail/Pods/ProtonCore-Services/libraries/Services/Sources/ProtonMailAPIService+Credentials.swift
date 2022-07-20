//
//  ProtonMailAPIService+Credentials.swift
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
import ProtonCore_Doh
import ProtonCore_Log
import ProtonCore_Networking
import ProtonCore_Utilities

// MARK: - Fetching and refreshing credentials

extension String {
    var isRefreshPath: Bool {
        return self.contains("/auth/refresh")
    }
}

extension PMAPIService {
    
    enum AuthCredentialFetchingResult: Equatable {
        case found(credentials: AuthCredential)
        case notFound
        case wrongConfigurationNoDelegate
        
        var toNSError: NSError? {
            switch self {
            case .found: return nil
            case .notFound: return NSError.protonMailError(0, localizedDescription: "Empty token")  // TODO: translations
            case .wrongConfigurationNoDelegate: return NSError.protonMailError(0, localizedDescription: "AuthDelegate is required") // TODO: translations
            }
        }
    }
    
    func fetchAuthCredentials(completion: @escaping (AuthCredentialFetchingResult) -> Void) {
        performSeriallyInAuthCredentialQueue { continuation in
            self.fetchAuthCredentialsNoSync(continuation: continuation, completion: completion)
        }
    }
    
    enum AuthCredentialRefreshingResult {
        case refreshed(credentials: AuthCredential)
        case wrongConfigurationNoDelegate
        case noCredentialsToBeRefreshed
        case logout(underlyingError: ResponseError)
        case refreshingError(underlyingError: AuthErrors)
        case unknownError
    }
    
    func refreshAuthCredential(credentialsCausing401: AuthCredential, completion: @escaping (AuthCredentialRefreshingResult) -> Void) {
        performSeriallyInAuthCredentialQueue { continuation in
            self.refreshAuthCredentialNoSync(credentialsCausing401: credentialsCausing401, continuation: continuation, completion: completion)
        }
    }
    
    private func performSeriallyInAuthCredentialQueue(operation: @escaping (_ continuation: @escaping () -> Void) -> Void) {
        fetchAuthCredentialsAsyncQueue.async {
            self.fetchAuthCredentialsSyncSerialQueue.sync {
                let group = DispatchGroup()
                group.enter()
                operation { group.leave() }
                group.wait()
            }
        }
    }
    
    private func finalize<T>(result: T, continuation: @escaping () -> Void, completion: @escaping (T) -> Void) {
        fetchAuthCredentialCompletionBlockBackgroundQueue.async {
            continuation()
            completion(result)
        }
    }
    
    private func fetchAuthCredentialsNoSync(continuation: @escaping () -> Void,
                                            completion: @escaping (AuthCredentialFetchingResult) -> Void) {

        guard let authDelegate = authDelegate else {
            finalize(result: .wrongConfigurationNoDelegate, continuation: continuation, completion: completion)
            return
        }

        guard let credential = authDelegate.getToken(bySessionUID: sessionUID) else {
            finalize(result: .notFound, continuation: continuation, completion: completion)
            return
        }
        
        // we copy credentials to ensure updating the instance in authDelegate doesn't influence the refresh logic
        finalize(result: .found(credentials: AuthCredential(copying: credential)),
                 continuation: continuation,
                 completion: completion)
    }
    
    private func refreshAuthCredentialNoSync(credentialsCausing401: AuthCredential,
                                             continuation: @escaping () -> Void,
                                             completion: @escaping (AuthCredentialRefreshingResult) -> Void) {

        guard let authDelegate = authDelegate else {
            finalize(result: .wrongConfigurationNoDelegate, continuation: continuation, completion: completion)
            return
        }
        
        guard let currentCredentials = authDelegate.getToken(bySessionUID: sessionUID) else {
            finalize(result: .noCredentialsToBeRefreshed, continuation: continuation, completion: completion)
            return
        }
        
        guard currentCredentials.accessToken == credentialsCausing401.accessToken else {
            // we copy credentials to ensure updating the instance in authDelegate doesn't influence the refresh logic
            finalize(result: .refreshed(credentials: AuthCredential(copying: currentCredentials)),
                     continuation: continuation,
                     completion: completion)
            return
        }
        
        authDelegate.onRefresh(bySessionUID: sessionUID) { newCredential, error in
            self.debugError(error)
            
            if case .networkingError(let responseError) = error,
               // according to documentation 422 indicates expired refresh token and 400 indicates invalid refresh token
               // both situations should result in user logout
               responseError.httpCode == 422 || responseError.httpCode == 400 {
                DispatchQueue.main.async {
                    completion(.logout(underlyingError: responseError))
                    self.authDelegate?.onLogout(sessionUID: self.sessionUID)
                    // this is the only place in which we wait with the continuation until after the completion block call
                    // the reason being we want to call completion after the delegate call
                    // and in all the places in this service we call completion block before `onLogout` delegate method
                    continuation()
                }
                
            } else if case .networkingError(let responseError) = error,
                      let underlyingError = responseError.underlyingError,
                      underlyingError.code == APIErrorCode.AuthErrorCode.localCacheBad {
                // TODO: the original logic: we're just refreshing again. seems to me like a possibility for a loop. I believe we should introduce an exit condition here
                continuation()
                self.refreshAuthCredential(credentialsCausing401: credentialsCausing401, completion: completion)
                
            } else if let error = error {
                self.finalize(result: .refreshingError(underlyingError: error), continuation: continuation, completion: completion)
            } else if let credential = newCredential {
                self.authDelegate?.onUpdate(auth: credential)
                // originally, this completion block was called on the main queue, but I think it's not required anymore
                self.finalize(result: .refreshed(credentials: AuthCredential(credential)), continuation: continuation, completion: completion)
            } else {
                self.finalize(result: .unknownError, continuation: continuation, completion: completion)
            }
        }
    }
}
