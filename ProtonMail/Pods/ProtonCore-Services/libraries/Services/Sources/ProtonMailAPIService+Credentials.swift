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

// swiftlint:disable function_parameter_count

// MARK: - Fetching and refreshing credentials

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
        case tooManyRefreshingAttempts
        case noCredentialsToBeRefreshed
        case logout(underlyingError: ResponseError)
        case refreshingError(underlyingError: AuthErrors)
    }
    
    func refreshAuthCredential(credentialsCausing401: AuthCredential,
                               refreshCounter: Int = 3,
                               legacyPath: Bool,
                               deviceFingerprints: ChallengeProperties,
                               completion: @escaping (AuthCredentialRefreshingResult) -> Void) {
        performSeriallyInAuthCredentialQueue { continuation in
            self.refreshAuthCredentialNoSync(credentialsCausing401: credentialsCausing401,
                                             refreshCounter: refreshCounter,
                                             legacyPath: legacyPath,
                                             deviceFingerprints: deviceFingerprints,
                                             continuation: continuation,
                                             completion: completion)
        }
    }

    enum SessionAquisitionResult {
        case aquired(AuthCredential)
        case aquiringError(ResponseError)
        case wrongConfigurationNoDelegate(NSError)
    }

    func aquireSession(deviceFingerprints: ChallengeProperties, completion: @escaping (SessionAquisitionResult) -> Void) {
        performSeriallyInAuthCredentialQueue { continuation in
            self.aquireSessionNoSync(deviceFingerprints: deviceFingerprints,
                                     continuation: continuation,
                                     completion: completion)
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

        guard let credential = authDelegate.authCredential(sessionUID: sessionUID) else {
            finalize(result: .notFound, continuation: continuation, completion: completion)
            return
        }
        
        // we copy credentials to ensure updating the instance in authDelegate doesn't influence the refresh logic
        finalize(result: .found(credentials: AuthCredential(copying: credential)),
                 continuation: continuation,
                 completion: completion)
    }
    
    private func refreshAuthCredentialNoSync(credentialsCausing401: AuthCredential,
                                             refreshCounter: Int,
                                             legacyPath: Bool,
                                             deviceFingerprints: ChallengeProperties,
                                             continuation: @escaping () -> Void,
                                             completion: @escaping (AuthCredentialRefreshingResult) -> Void) {

        guard let authDelegate = authDelegate else {
            finalize(result: .wrongConfigurationNoDelegate, continuation: continuation, completion: completion)
            return
        }
        
        guard let currentCredentials = authDelegate.authCredential(sessionUID: sessionUID) else {
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

        guard refreshCounter > 0 else {
            finalize(result: .tooManyRefreshingAttempts, continuation: continuation, completion: completion)
            return
        }
        
        authDelegate.onRefresh(sessionUID: sessionUID, service: self) { result in
            self.fetchAuthCredentialCompletionBlockBackgroundQueue.async {
                if legacyPath {
                    self.handleRefreshingResultsInLegacyPath(result, credentialsCausing401, refreshCounter, deviceFingerprints, continuation, completion)
                } else {
                    self.handleRefreshingResults(result, credentialsCausing401, refreshCounter, deviceFingerprints, continuation, completion)
                }
            }
        }
    }

    private func handleRefreshingResults(_ result: Result<Credential, AuthErrors>,
                                         _ credentialsCausing401: AuthCredential,
                                         _ refreshCounter: Int,
                                         _ deviceFingerprints: ChallengeProperties,
                                         _ continuation: @escaping () -> Void,
                                         _ completion: @escaping (AuthCredentialRefreshingResult) -> Void) {
        debugError(result.error)

        switch result {
        case .success(let credential):
            authDelegate?.onUpdate(credential: credential, sessionUID: sessionUID)
            setSessionUID(uid: credential.UID)
            continuation()
            completion(.refreshed(credentials: AuthCredential(credential)))

        case .failure(.networkingError(let responseError))
            where credentialsCausing401.isForUnauthenticatedSession && (responseError.httpCode == 422 || responseError.httpCode == 400):

            authDelegate?.eraseUnauthSessionCredentials(sessionUID: sessionUID)

            self.aquireSessionNoSync(deviceFingerprints: deviceFingerprints, continuation: continuation) { (result: SessionAquisitionResult) in
                switch result {
                case .wrongConfigurationNoDelegate:
                    completion(.wrongConfigurationNoDelegate)
                case .aquiringError(let error):
                    completion(.refreshingError(underlyingError: .networkingError(error)))
                case .aquired(let credentials):
                    completion(.refreshed(credentials: credentials))
                }
            }

        case .failure(.networkingError(let responseError))
            where !credentialsCausing401.isForUnauthenticatedSession && (responseError.httpCode == 422 || responseError.httpCode == 400):
            authDelegate?.onLogout(sessionUID: sessionUID)

            continuation()
            completion(.logout(underlyingError: responseError))

        // should we bring this logic over? I'm really unsure
        case .failure(.networkingError(let responseError)) where responseError.underlyingError?.code == APIErrorCode.AuthErrorCode.localCacheBad:
            continuation()
            refreshAuthCredential(credentialsCausing401: credentialsCausing401,
                                  refreshCounter: refreshCounter - 1,
                                  legacyPath: false,
                                  deviceFingerprints: deviceFingerprints,
                                  completion: completion)

        // if the credentials refresh fails with error OTHER THAN 400 or 422, return error
        case .failure(let error):
            continuation()
            completion(.refreshingError(underlyingError: error))
        }
    }
    
    private func handleRefreshingResultsInLegacyPath(_ result: Result<Credential, AuthErrors>,
                                                     _ credentialsCausing401: AuthCredential,
                                                     _ refreshCounter: Int,
                                                     _ deviceFingerprints: ChallengeProperties,
                                                     _ continuation: @escaping () -> Void,
                                                     _ completion: @escaping (AuthCredentialRefreshingResult) -> Void) {
        debugError(result.error)
        
        switch result {
        case .success(let credential):
            authDelegate?.onUpdate(credential: credential, sessionUID: sessionUID)
            setSessionUID(uid: credential.UID)
            // originally, this completion block was called on the main queue, but I think it's not required anymore
            continuation()
            completion(.refreshed(credentials: AuthCredential(credential)))
            
        // according to documentation 422 indicates expired refresh token and 400 indicates invalid refresh token
        // both situations should result in user logout
        case .failure(.networkingError(let responseError)) where responseError.httpCode == 422 || responseError.httpCode == 400:
            authDelegate?.onLogout(sessionUID: sessionUID)
            continuation()
            completion(.logout(underlyingError: responseError))
        
        case .failure(.networkingError(let responseError)) where responseError.underlyingError?.code == APIErrorCode.AuthErrorCode.localCacheBad:
            // the original logic: we're just refreshing again
            continuation()
            refreshAuthCredential(credentialsCausing401: credentialsCausing401,
                                  refreshCounter: refreshCounter - 1,
                                  legacyPath: true,
                                  deviceFingerprints: deviceFingerprints,
                                  completion: completion)
        case .failure(let error):
            continuation()
            completion(.refreshingError(underlyingError: error))
        }
    }

    private func aquireSessionNoSync(deviceFingerprints: ChallengeProperties,
                                     continuation: @escaping () -> Void,
                                     completion: @escaping (SessionAquisitionResult) -> Void) {
        guard let authDelegate = authDelegate else {
            let nsError = NSError.protonMailError(0, localizedDescription: "AuthDelegate is required")
            finalize(result: .wrongConfigurationNoDelegate(nsError),
                     continuation: continuation, completion: completion)
            return
        }

        let sessionsRequest = SessionsRequest(challenge: deviceFingerprints)

        performRequestHavingFetchedCredentials(method: sessionsRequest.method,
                                               path: sessionsRequest.path,
                                               parameters: sessionsRequest.parameters,
                                               headers: sessionsRequest.header,
                                               authenticated: false,
                                               authRetry: false,
                                               authRetryRemains: 0,
                                               fetchingCredentialsResult: .notFound,
                                               nonDefaultTimeout: nil,
                                               retryPolicy: .background,
                                               completion: .right({ (task, result: Result<SessionsRequestResponse, APIError>) in
            switch result {
            case .success(let sessionsResponse):
                self.debug(task, sessionsResponse, nil)
                let credential = Credential(UID: sessionsResponse.UID,
                                            accessToken: sessionsResponse.accessToken,
                                            refreshToken: sessionsResponse.refreshToken,
                                            userName: "",
                                            userID: "",
                                            scopes: sessionsResponse.scopes)
                authDelegate.onUpdate(credential: credential, sessionUID: self.sessionUID)
                self.setSessionUID(uid: sessionsResponse.UID)
                continuation()
                completion(.aquired(AuthCredential(credential)))
            case .failure(let error):
                self.debug(task, nil, error)
                let httpCode = task.flatMap(\.response).flatMap { $0 as? HTTPURLResponse }.map(\.statusCode)
                let responseCode = error.domain == ResponseErrorDomains.withResponseCode.rawValue ? error.code : nil
                continuation()
                completion(.aquiringError(.init(
                    httpCode: httpCode, responseCode: responseCode,
                    userFacingMessage: error.localizedDescription, underlyingError: error
                )))
            }
        }))
    }
}
