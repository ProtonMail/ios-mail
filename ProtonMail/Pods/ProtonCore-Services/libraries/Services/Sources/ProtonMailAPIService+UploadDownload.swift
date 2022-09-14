//
//  ProtonMailAPIService+UploadDownload.swift
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

// swiftlint:disable function_parameter_count

import Foundation
import ProtonCore_Doh
import ProtonCore_Log
import ProtonCore_Networking
import ProtonCore_Utilities

// MARK: - Performing the upload and download operation

extension PMAPIService {
    
    private typealias DummyGenericsOperationAndCompletion = Either<
        JSONOperationAndCompletion, DecodableOperationAndCompletion<DummyAPIDecodableResponseOnlyForSatisfyingGenericsResolving>
    >
    
    public func upload(byPath path: String,
                       parameters: [String: String],
                       keyPackets: Data,
                       dataPacket: Data,
                       signature: Data?,
                       headers: [String: Any]?,
                       authenticated: Bool,
                       customAuthCredential: AuthCredential?,
                       nonDefaultTimeout: TimeInterval?,
                       retryPolicy: ProtonRetryPolicy.RetryMode,
                       uploadProgress: ProgressCompletion?,
                       jsonCompletion: @escaping JSONCompletion) {
        let jsonOperationAndCompletion: JSONOperationAndCompletion = (
            { request, operationCompletion in
                self.session.upload(with: request, keyPacket: keyPackets, dataPacket: dataPacket, signature: signature, completion: operationCompletion, uploadProgress: uploadProgress)
            }, transformJSONCompletion(jsonCompletion)
        )
        performUploadOperation(path: path,
                               parameters: parameters,
                               headers: headers,
                               authenticated: authenticated,
                               customAuthCredential: customAuthCredential.map(AuthCredential.init(copying:)),
                               nonDefaultTimeout: nonDefaultTimeout,
                               retryPolicy: retryPolicy,
                               operationAndCompletion: DummyGenericsOperationAndCompletion.left(jsonOperationAndCompletion))
    }
    
    public func upload<T>(byPath path: String,
                          parameters: [String: String],
                          keyPackets: Data,
                          dataPacket: Data,
                          signature: Data?,
                          headers: [String: Any]?,
                          authenticated: Bool,
                          customAuthCredential: AuthCredential?,
                          nonDefaultTimeout: TimeInterval?,
                          retryPolicy: ProtonRetryPolicy.RetryMode,
                          uploadProgress: ProgressCompletion?,
                          decodableCompletion: @escaping DecodableCompletion<T>) where T: APIDecodableResponse {
        let decodableOperationAndCompletion: DecodableOperationAndCompletion<T> = (
            { request, jsonDecoder, operationCompletion in
                self.session.upload(with: request, keyPacket: keyPackets, dataPacket: dataPacket, signature: signature, jsonDecoder: jsonDecoder, completion: operationCompletion, uploadProgress: uploadProgress)
            }, decodableCompletion
        )
        performUploadOperation(path: path,
                               parameters: parameters,
                               headers: headers,
                               authenticated: authenticated,
                               customAuthCredential: customAuthCredential.map(AuthCredential.init(copying:)),
                               nonDefaultTimeout: nonDefaultTimeout,
                               retryPolicy: retryPolicy,
                               operationAndCompletion: .right(decodableOperationAndCompletion))
    }
    
    public func upload(byPath path: String,
                       parameters: Any?,
                       files: [String: URL],
                       headers: [String: Any]?,
                       authenticated: Bool,
                       customAuthCredential: AuthCredential?,
                       nonDefaultTimeout: TimeInterval?,
                       retryPolicy: ProtonRetryPolicy.RetryMode,
                       uploadProgress: ProgressCompletion?,
                       jsonCompletion: @escaping JSONCompletion) {
        
        let jsonOperationAndCompletion: JSONOperationAndCompletion = (
            { request, operationCompletion in
                self.session.upload(with: request, files: files, completion: operationCompletion, uploadProgress: uploadProgress)
            }, transformJSONCompletion(jsonCompletion)
        )
        performUploadOperation(path: path,
                               parameters: parameters,
                               headers: headers,
                               authenticated: authenticated,
                               customAuthCredential: customAuthCredential.map(AuthCredential.init(copying:)),
                               nonDefaultTimeout: nonDefaultTimeout,
                               retryPolicy: retryPolicy,
                               operationAndCompletion: DummyGenericsOperationAndCompletion.left(jsonOperationAndCompletion))
    }
    
    public func upload<T>(byPath path: String,
                          parameters: Any?,
                          files: [String: URL],
                          headers: [String: Any]?,
                          authenticated: Bool,
                          customAuthCredential: AuthCredential?,
                          nonDefaultTimeout: TimeInterval?,
                          retryPolicy: ProtonRetryPolicy.RetryMode,
                          uploadProgress: ProgressCompletion?,
                          decodableCompletion: @escaping DecodableCompletion<T>) where T: APIDecodableResponse {
        let decodableOperationAndCompletion: DecodableOperationAndCompletion<T> = (
            { request, jsonDecoder, operationCompletion in
                self.session.upload(with: request, files: files, jsonDecoder: jsonDecoder, completion: operationCompletion, uploadProgress: uploadProgress)
            }, decodableCompletion
        )
        performUploadOperation(path: path,
                               parameters: parameters,
                               headers: headers,
                               authenticated: authenticated,
                               customAuthCredential: customAuthCredential.map(AuthCredential.init(copying:)),
                               nonDefaultTimeout: nonDefaultTimeout,
                               retryPolicy: retryPolicy,
                               operationAndCompletion: .right(decodableOperationAndCompletion))
    }
    
    public func uploadFromFile(byPath path: String,
                               parameters: [String: String],
                               keyPackets: Data,
                               dataPacketSourceFileURL: URL,
                               signature: Data?,
                               headers: [String: Any]?,
                               authenticated: Bool,
                               customAuthCredential: AuthCredential?,
                               nonDefaultTimeout: TimeInterval?,
                               retryPolicy: ProtonRetryPolicy.RetryMode,
                               uploadProgress: ProgressCompletion?,
                               jsonCompletion: @escaping JSONCompletion) {
        
        let jsonOperationAndCompletion: JSONOperationAndCompletion = (
            { request, operationCompletion in
                self.session.uploadFromFile(
                    with: request, keyPacket: keyPackets, dataPacketSourceFileURL: dataPacketSourceFileURL, signature: signature, completion: operationCompletion, uploadProgress: uploadProgress
                )
            }, transformJSONCompletion(jsonCompletion)
        )
        
        performUploadOperation(path: path,
                               parameters: parameters,
                               headers: headers,
                               authenticated: authenticated,
                               customAuthCredential: customAuthCredential.map(AuthCredential.init(copying:)),
                               nonDefaultTimeout: nonDefaultTimeout,
                               retryPolicy: retryPolicy,
                               operationAndCompletion: DummyGenericsOperationAndCompletion.left(jsonOperationAndCompletion))
    }
    
    public func uploadFromFile<T>(byPath path: String,
                                  parameters: [String: String],
                                  keyPackets: Data,
                                  dataPacketSourceFileURL: URL,
                                  signature: Data?,
                                  headers: [String: Any]?,
                                  authenticated: Bool,
                                  customAuthCredential: AuthCredential?,
                                  nonDefaultTimeout: TimeInterval?,
                                  retryPolicy: ProtonRetryPolicy.RetryMode,
                                  uploadProgress: ProgressCompletion?,
                                  decodableCompletion: @escaping DecodableCompletion<T>) where T: APIDecodableResponse {
        
        let decodableOperationAndCompletion: DecodableOperationAndCompletion<T> = (
            { request, jsonDecoder, operationCompletion in
                self.session.uploadFromFile(with: request, keyPacket: keyPackets, dataPacketSourceFileURL: dataPacketSourceFileURL,
                                            signature: signature, jsonDecoder: jsonDecoder, completion: operationCompletion, uploadProgress: uploadProgress)
            }, decodableCompletion
        )
        
        performUploadOperation(path: path,
                               parameters: parameters,
                               headers: headers,
                               authenticated: authenticated,
                               customAuthCredential: customAuthCredential.map(AuthCredential.init(copying:)),
                               nonDefaultTimeout: nonDefaultTimeout,
                               retryPolicy: retryPolicy,
                               operationAndCompletion: .right(decodableOperationAndCompletion))
    }
    
    typealias JSONOperationAndCompletion = (
        (_ request: SessionRequest, _ completion: @escaping Session.JSONResponseCompletion) -> Void,
        JSONCompletion
    )
    
    typealias DecodableOperationAndCompletion<T> = (
        (_ request: SessionRequest,
         _ jsonDecoder: JSONDecoder?,
         _ completion: @escaping (_ task: URLSessionDataTask?, _ result: Result<T, SessionResponseError>) -> Void) -> Void,
        DecodableCompletion<T>
    ) where T: APIDecodableResponse
    
    private func performUploadOperation<T>(
        path: String,
        parameters: Any?,
        headers: [String: Any]?,
        authenticated: Bool,
        customAuthCredential: AuthCredential?,
        nonDefaultTimeout: TimeInterval?,
        retryPolicy: ProtonRetryPolicy.RetryMode,
        operationAndCompletion: Either<JSONOperationAndCompletion, DecodableOperationAndCompletion<T>>
    ) where T: APIDecodableResponse {
        let url = self.doh.getCurrentlyUsedHostUrl() + path
        
        let operation = operationAndCompletion.mapLeft(f: \.0).mapRight(f: \.0)
        let completion = operationAndCompletion.mapLeft(f: \.1).mapRight(f: \.1)
        
        let sessionRequestCall: (SessionRequest, @escaping (URLSessionDataTask?, ResponseFromSession<T>) -> Void) -> Void
        switch operation {
        case .left(let jsonOperation):
            sessionRequestCall = { request, continuation in
                jsonOperation(request) { task, result in continuation(task, .left(result)) }
            }
        case .right(let decodableOperation):
            let decoder = jsonDecoder
            sessionRequestCall = { request, continuation in
                decodableOperation(request, decoder) { task, result in continuation(task, .right(result)) }
            }
        }

        performNetworkOperation(url: url,
                                method: .post,
                                parameters: parameters,
                                headers: headers,
                                authenticated: authenticated,
                                customAuthCredential: customAuthCredential,
                                nonDefaultTimeout: nonDefaultTimeout,
                                retryPolicy: retryPolicy,
                                errorOut: { completion.call(task: nil, error: $0) }) { request in
            
            sessionRequestCall(request) { task, responseFromSession in
                self.debugError(responseFromSession.possibleError())
                self.updateServerTime(task?.response)
                
                // reachability temporarily failed because was switching from WiFi to Cellular
                if responseFromSession.possibleError()?.underlyingError.code == -1005,
                   self.serviceDelegate?.isReachable() == true {
                    // retry task asynchonously
                    DispatchQueue.global(qos: .utility).async {
                        self.performUploadOperation(path: path,
                                                    parameters: parameters,
                                                    headers: headers,
                                                    authenticated: authenticated,
                                                    customAuthCredential: customAuthCredential,
                                                    nonDefaultTimeout: nonDefaultTimeout,
                                                    retryPolicy: retryPolicy,
                                                    operationAndCompletion: operationAndCompletion)
                    }
                    return
                }
                
                let response = responseFromSession
                    .mapLeft { $0.mapError { $0.underlyingError } }
                    .mapRight { $0.mapError { $0.underlyingError } }
                    .sequence()
                
                switch response {
                case .success(let value): completion.call(task: task, response: value)
                case .failure(let error): completion.call(task: task, error: error)
                }
            }
        }
    }
    
    private func performNetworkOperation(url: String,
                                         method: HTTPMethod,
                                         parameters: Any?,
                                         headers: [String: Any]?,
                                         authenticated: Bool,
                                         customAuthCredential: AuthCredential?,
                                         nonDefaultTimeout: TimeInterval?,
                                         retryPolicy: ProtonRetryPolicy.RetryMode,
                                         errorOut: @escaping (APIError) -> Void,
                                         operation: @escaping (_ request: SessionRequest) -> Void) {
        
        let authBlock: (String?, String?, NSError?) -> Void = { token, userID, error in
            
            if let error = error {
                self.debugError(error)
                errorOut(error)
                return
            }
            
            do {
                
                let request = try self.createRequest(url: url,
                                                     method: method,
                                                     parameters: parameters,
                                                     nonDefaultTimeout: nonDefaultTimeout,
                                                     headers: headers,
                                                     UID: userID,
                                                     accessToken: token,
                                                     retryPolicy: retryPolicy)
                // the meat of this method
                operation(request)
                
            } catch {
                self.debugError(error)
                errorOut(error as NSError)
            }
        }
        
        if let customAuthCredential = customAuthCredential {
            authBlock(customAuthCredential.accessToken, customAuthCredential.sessionID, nil)
        } else {
            fetchAuthCredentials { result in
                switch result {
                case .found(let credentials):
                    authBlock(credentials.accessToken, credentials.sessionID, nil)
                case .notFound where !authenticated, .wrongConfigurationNoDelegate where !authenticated:
                    authBlock(nil, nil, nil)
                case .notFound, .wrongConfigurationNoDelegate:
                    authBlock(nil, nil, result.toNSError)
                }
            }
        }
    }

    public func download(byUrl url: String,
                         destinationDirectoryURL: URL,
                         headers: [String: Any]?,
                         authenticated: Bool = true,
                         customAuthCredential: AuthCredential? = nil,
                         nonDefaultTimeout: TimeInterval?,
                         retryPolicy: ProtonRetryPolicy.RetryMode,
                         downloadTask: ((URLSessionDownloadTask) -> Void)?,
                         downloadCompletion: @escaping ((URLResponse?, URL?, NSError?) -> Void)) {
        
        performNetworkOperation(url: url,
                                method: .get,
                                parameters: nil,
                                headers: headers,
                                authenticated: authenticated,
                                customAuthCredential: customAuthCredential.map(AuthCredential.init(copying:)),
                                nonDefaultTimeout: nonDefaultTimeout,
                                retryPolicy: retryPolicy) { error in
            
            downloadCompletion(nil, nil, error)
            
        } operation: { request in
            
            self.session.download(with: request, destinationDirectoryURL: destinationDirectoryURL) { response, url, error in
                downloadCompletion(response, url, error)
            }
        }
    }
}
