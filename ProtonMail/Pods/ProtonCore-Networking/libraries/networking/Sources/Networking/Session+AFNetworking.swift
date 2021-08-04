//
//  Session+AFNetworking.swift
//  ProtonCore-Networking - Created on 6/24/21.
//
//  Copyright (c) 2021 Proton Technologies AG
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

#if canImport(AFNetworking)
import Foundation
import TrustKit
import AFNetworking

public class AFNetworkingSession: Session {
    
    var trustKit: TrustKit?
    var noTrustKit: Bool = false
    var sessionManager: AFHTTPSessionManager
    
    public func setChallenge(noTrustKit: Bool, trustKit: TrustKit?) {
        self.trustKit = trustKit
        self.noTrustKit = noTrustKit
    }
    
    public func request(with request: SessionRequest, completion: @escaping ResponseCompletion) throws {
        let afnRequest = try self.sessionManager.requestSerializer.request(withMethod: request.method.toString(),
                                                                           urlString: request.urlString,
                                                                           parameters: request.parameters)
        request.request = afnRequest as URLRequest
        request.updateHeader()
        var task: URLSessionDataTask?
        task = self.sessionManager.dataTask(with: request.request!, uploadProgress: { (_) in
        }, downloadProgress: { (_) in
        }, completionHandler: { (urlresponse, res, error) in
            completion(task, res, error as NSError?)
        })
        task!.resume()
    }
    
    public func upload(with request: SessionRequest,
                       keyPacket: Data,
                       dataPacket: Data,
                       signature: Data?, completion: @escaping ResponseCompletion) throws {
        let afnRequest = self.sessionManager
            .requestSerializer
            .multipartFormRequest(withMethod: request.method.toString(),
                                  urlString: request.urlString,
                                  parameters: request.parameters as? [String: Any],
                                  constructingBodyWith: { (formData) -> Void in
                                    let data: AFMultipartFormData = formData
                                    data.appendPart(withFileData: keyPacket, name: "KeyPackets", fileName: "KeyPackets.txt", mimeType: "" )
                                    data.appendPart(withFileData: dataPacket, name: "DataPacket", fileName: "DataPacket.txt", mimeType: "" )
                                    if let sign = signature {
                                        data.appendPart(withFileData: sign, name: "Signature", fileName: "Signature.txt", mimeType: "" )
                                    }
                                  }, error: nil)
        request.request = afnRequest as URLRequest
        request.updateHeader()
        var uploadTask: URLSessionDataTask?
        uploadTask = self.sessionManager.uploadTask(withStreamedRequest: request.request!, progress: { (_) in
            // nothing
        }, completionHandler: { (_, responseObject, error) in
            let resObject = responseObject as? [String: Any]
            completion(uploadTask, resObject, error as NSError?)
        })
        uploadTask?.resume()
    }

    public func uploadFromFile(with request: SessionRequest,
                               keyPacket: Data,
                               dataPacketSourceFileURL: URL,
                               signature: Data?, completion: @escaping ResponseCompletion) throws {
        let afnRequest = self.sessionManager
            .requestSerializer
            .multipartFormRequest(withMethod: request.method.toString(),
                                  urlString: request.urlString,
                                  parameters: request.parameters as? [String: Any],
                                  constructingBodyWith: { (formData) -> Void in
                                    let data: AFMultipartFormData = formData
                                    data.appendPart(withFileData: keyPacket, name: "KeyPackets", fileName: "KeyPackets.txt", mimeType: "" )
                                    try? data.appendPart(withFileURL: dataPacketSourceFileURL, name: "DataPacket", fileName: "DataPacket.txt", mimeType: "")
                                    if let sign = signature {
                                        data.appendPart(withFileData: sign, name: "Signature", fileName: "Signature.txt", mimeType: "" )
                                    }
                                  }, error: nil)
        request.request = afnRequest as URLRequest
        request.updateHeader()
        var uploadTask: URLSessionDataTask?
        uploadTask = self.sessionManager.uploadTask(withStreamedRequest: request.request!, progress: { (_) in
            // nothing
        }, completionHandler: { (_, responseObject, error) in
            let resObject = responseObject as? [String: Any]
            completion(uploadTask, resObject, error as NSError?)
        })
        uploadTask?.resume()
    }
    
    public func download(with request: SessionRequest, destinationDirectoryURL: URL, completion: @escaping DownloadCompletion) throws {
        let afnRequest = try self.sessionManager.requestSerializer.request(withMethod: request.method.toString(),
                                                                           urlString: request.urlString,
                                                                           parameters: request.parameters)
        request.request = afnRequest as URLRequest
        request.updateHeader()
        let sessionDownloadTask = self.sessionManager.downloadTask(with: request.request!, progress: { (_) in
            
        }, destination: { (_, _) -> URL in
            return destinationDirectoryURL
        }, completionHandler: { (response, url, error) in
            completion(response, url, error as NSError?)
        })
        sessionDownloadTask.resume()
    }
    
    public init(url defaultHost: String) {
        
        self.sessionManager = AFHTTPSessionManager(baseURL: URL(string: defaultHost)!)
        
        sessionManager.requestSerializer = AFJSONRequestSerializer()
        sessionManager.requestSerializer.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        sessionManager.requestSerializer.stringEncoding = String.Encoding.utf8.rawValue
        
        sessionManager.responseSerializer.acceptableContentTypes?.insert("text/html")
        sessionManager.securityPolicy.allowInvalidCertificates = false
        sessionManager.securityPolicy.validatesDomainName = false
        #if DEBUG
        sessionManager.securityPolicy.allowInvalidCertificates = true
        #endif
        
        sessionManager.setSessionDidReceiveAuthenticationChallenge { _, challenge, credential -> URLSession.AuthChallengeDisposition in
            if self.noTrustKit {
                let dispositionToReturn: URLSession.AuthChallengeDisposition = .useCredential
                // Hard force to pass all connections -- this only for testing and with charles
                guard let trust = challenge.protectionSpace.serverTrust else { return dispositionToReturn }
                let credentialOut = URLCredential(trust: trust)
                credential?.pointee = credentialOut
                return dispositionToReturn
            } else {
                var dispositionToReturn: URLSession.AuthChallengeDisposition = .performDefaultHandling
                if let validator = self.trustKit?.pinningValidator {
                    validator.handle(challenge, completionHandler: { (disposition, credentialOut) in
                        credential?.pointee = credentialOut
                        dispositionToReturn = disposition
                    })
                } else {
                    assert(false, "TrustKit not initialized correctly")
                }
                return dispositionToReturn
            }
        }
    }
}

#endif
