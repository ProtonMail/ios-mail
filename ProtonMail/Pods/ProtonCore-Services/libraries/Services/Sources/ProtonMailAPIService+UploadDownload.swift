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
    
    public func upload(byPath path: String,
                       parameters: [String: String],
                       keyPackets: Data,
                       dataPacket: Data,
                       signature: Data?,
                       headers: [String: Any]?,
                       authenticated: Bool = true,
                       customAuthCredential: AuthCredential? = nil,
                       nonDefaultTimeout: TimeInterval?,
                       completion: @escaping CompletionBlock) {
        performUploadOperation(path: path,
                               parameters: parameters,
                               headers: headers,
                               authenticated: authenticated,
                               customAuthCredential: customAuthCredential.map(AuthCredential.init(copying:)),
                               nonDefaultTimeout: nonDefaultTimeout,
                               completion: completion) { request, operationCompletion in
            try self.session.upload(with: request, keyPacket: keyPackets, dataPacket: dataPacket, signature: signature, completion: operationCompletion)
        }
    }
    
    public func upload(byPath path: String,
                       parameters: Any?,
                       files: [String: URL],
                       headers: [String: Any]?,
                       authenticated: Bool,
                       customAuthCredential: AuthCredential?,
                       nonDefaultTimeout: TimeInterval?,
                       uploadProgress: ProgressCompletion?,
                       completion: @escaping CompletionBlock) {
        
        performUploadOperation(path: path,
                               parameters: parameters,
                               headers: headers,
                               authenticated: authenticated,
                               customAuthCredential: customAuthCredential.map(AuthCredential.init(copying:)),
                               nonDefaultTimeout: nonDefaultTimeout,
                               completion: completion) { request, operationCompletion in
            try self.session.upload(with: request, files: files, completion: operationCompletion, uploadProgress: uploadProgress)
        }
    }
    
    public func uploadFromFile(byPath path: String,
                               parameters: [String: String],
                               keyPackets: Data,
                               dataPacketSourceFileURL: URL,
                               signature: Data?,
                               headers: [String: Any]?,
                               authenticated: Bool = true,
                               customAuthCredential: AuthCredential? = nil,
                               nonDefaultTimeout: TimeInterval?,
                               completion: @escaping CompletionBlock) {
        
        performUploadOperation(path: path,
                               parameters: parameters,
                               headers: headers,
                               authenticated: authenticated,
                               customAuthCredential: customAuthCredential.map(AuthCredential.init(copying:)),
                               nonDefaultTimeout: nonDefaultTimeout,
                               completion: completion) { request, operationCompletion in
            try self.session.uploadFromFile(with: request,
                                            keyPacket: keyPackets,
                                            dataPacketSourceFileURL: dataPacketSourceFileURL,
                                            signature: signature, completion: operationCompletion)
        }
    }
    
    private func performUploadOperation(path: String,
                                        parameters: Any?,
                                        headers: [String: Any]?,
                                        authenticated: Bool,
                                        customAuthCredential: AuthCredential?,
                                        nonDefaultTimeout: TimeInterval?,
                                        completion: @escaping CompletionBlock,
                                        operation: @escaping (_ request: SessionRequest, _ completion: @escaping ResponseCompletion) throws -> Void) {
        let url = self.doh.getCurrentlyUsedHostUrl() + path
        
        performNetworkOperation(url: url,
                                method: .post,
                                parameters: parameters,
                                headers: headers,
                                authenticated: authenticated,
                                customAuthCredential: customAuthCredential,
                                nonDefaultTimeout: nonDefaultTimeout,
                                completion: completion) { request in
            try operation(request) { task, response, error in
                self.debugError(error)
                self.updateServerTime(task?.response)
                
                // reachability temporarily failed because was switching from WiFi to Cellular
                if (error as NSError?)?.code == -1005,
                   self.serviceDelegate?.isReachable() == true {
                    // retry task asynchonously
                    DispatchQueue.global(qos: .utility).async {
                        self.performUploadOperation(path: path,
                                                    parameters: parameters,
                                                    headers: headers,
                                                    authenticated: authenticated,
                                                    customAuthCredential: customAuthCredential,
                                                    nonDefaultTimeout: nonDefaultTimeout,
                                                    completion: completion,
                                                    operation: operation)
                    }
                    return
                }
                let resObject = response as? [String: Any]
                completion(task, resObject, error as NSError?)
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
                                         completion: @escaping CompletionBlock,
                                         operation: @escaping (_ request: SessionRequest) throws -> Void) {
        
        let authBlock: (String?, String?, NSError?) -> Void = { token, userID, error in
            
            guard error == nil else {
                self.debugError(error)
                completion(nil, nil, error)
                return
            }
            
            do {
                
                let request = try self.createRequest(url: url,
                                                     method: method,
                                                     parameters: parameters,
                                                     nonDefaultTimeout: nonDefaultTimeout,
                                                     headers: headers,
                                                     UID: userID,
                                                     accessToken: token)
                // the meat of this method
                try operation(request)
                
            } catch {
                self.debugError(error)
                completion(nil, nil, error as NSError)
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
                         downloadTask: ((URLSessionDownloadTask) -> Void)?,
                         completion: @escaping ((URLResponse?, URL?, NSError?) -> Void)) {
        
        performNetworkOperation(url: url,
                                method: .get,
                                parameters: nil,
                                headers: headers,
                                authenticated: authenticated,
                                customAuthCredential: customAuthCredential.map(AuthCredential.init(copying:)),
                                nonDefaultTimeout: nonDefaultTimeout) { task, _, error in
            
            completion(task?.response, task?.currentRequest?.urlRequest?.url, error)
            
        } operation: { request in
            
            try self.session.download(with: request, destinationDirectoryURL: destinationDirectoryURL) { response, url, error in
                completion(response, url, error)
            }
        }
    }
}
