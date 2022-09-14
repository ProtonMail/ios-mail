//
//  Session+Alamofirew.swift
//  ProtonCore-Networking - Created on 6/24/21.
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

#if canImport(Alamofire)
import Foundation
import TrustKit
import Alamofire
import ProtonCore_Log
import ProtonCore_CoreTranslation
import ProtonCore_Utilities

private let requestQueue = DispatchQueue(label: "ch.protonmail.alamofire")

internal class AlamofireSessionDelegate: SessionDelegate {
    var trustKit: TrustKit?
    var noTrustKit: Bool = false
    var failedTLS: ((URLRequest) -> Void)?
    
    override public func urlSession(_ session: URLSession, task: URLSessionTask,
                                    didReceive challenge: URLAuthenticationChallenge,
                                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        handleAuthenticationChallenge(
            didReceive: challenge,
            noTrustKit: noTrustKit,
            trustKit: trustKit,
            challengeCompletionHandler: completionHandler
        ) { disposition, credential, completionHandler in
            if disposition == .cancelAuthenticationChallenge, let request = task.originalRequest {
                self.failedTLS?(request)
            }
            completionHandler(disposition, credential)
        }
    }
}

public class AlamofireSession: Session {

    public let defaultJSONDecoder: JSONDecoder = .decapitalisingFirstLetter
    
    public var sessionConfiguration: URLSessionConfiguration { session.sessionConfiguration }
    
    typealias AfSession = Alamofire.Session
    var session: AfSession
    var sessionChallenge: AlamofireSessionDelegate = AlamofireSessionDelegate()
    private var tlsFailedRequests = [URLRequest]()
    
    public init() {
        self.session = AfSession(
            delegate: sessionChallenge,
            redirectHandler: Redirector.doNotFollow
        )
    }
    
    public func setChallenge(noTrustKit: Bool, trustKit: TrustKit?) {
        self.sessionChallenge.trustKit = trustKit
        self.sessionChallenge.noTrustKit = noTrustKit
        self.sessionChallenge.failedTLS = { [weak self] request in
            guard let self = self else { return }
            self.markAsFailedTLS(request: request)
        }
    }
    
    public func generate(with method: HTTPMethod, urlString: String, parameters: Any? = nil, timeout: TimeInterval? = nil, retryPolicy: ProtonRetryPolicy.RetryMode) -> SessionRequest {
        return AlamofireRequest.init(parameters: parameters, urlString: urlString, method: method, timeout: timeout ?? defaultTimeout, retryPolicy: retryPolicy)
    }
    
    public func failsTLS(request: SessionRequest) -> String? {
        if let request = request as? URLRequestConvertible, let url = try? request.asURLRequest().url,
           let index = tlsFailedRequests.firstIndex(where: { $0.url?.absoluteString == url.absoluteString }) {
            tlsFailedRequests.remove(at: index)
            return CoreString._net_insecure_connection_error
        }
        return nil
    }
    
    private func markAsFailedTLS(request: URLRequest) {
        tlsFailedRequests.append(request)
    }
}

// MARK: - common logic for network operations

extension AlamofireSession {
    private func finalizeJSONResponse(dataRequest: DataRequest, taskOut: @escaping () -> URLSessionDataTask?, completion: @escaping JSONResponseCompletion) {
        dataRequest.responseJSON(queue: requestQueue) { jsonResponse in
            switch jsonResponse.result {
            case .success(let jsonObject):
                guard let jsonDict = jsonObject as? [String: Any] else {
                    completion(taskOut(), .failure(.responseBodyIsNotAJSONDictionary(body: jsonResponse.data, response: jsonResponse.response)))
                    return
                }
                completion(taskOut(), .success(jsonDict))
                
            case .failure(let error):
                let err = error.underlyingError ?? error
                completion(taskOut(), .failure(.networkingEngineError(underlyingError: err as NSError)))
            }
        }
    }
    
    private func finalizeDecodableResponse<T>(
        dataRequest: DataRequest, taskOut: @escaping () -> URLSessionDataTask?, jsonDecoder: JSONDecoder?, completion: @escaping DecodableResponseCompletion<T>
    ) where T: SessionDecodableResponse {
        dataRequest.responseDecodable(
            of: T.self, queue: requestQueue, decoder: jsonDecoder ?? defaultJSONDecoder
        ) { (decodedResponse: AFDataResponse<T>) in
            
            switch decodedResponse.result {
            case .success(let object): completion(taskOut(), .success(object))
            case .failure(let error):
                let err = error.underlyingError ?? error
                if error.isResponseSerializationError {
                    completion(taskOut(), .failure(.responseBodyIsNotADecodableObject(body: decodedResponse.data, response: decodedResponse.response)))
                } else {
                    completion(taskOut(), .failure(.networkingEngineError(underlyingError: err as NSError)))
                }
            }
        }
    }
}

// MARK: - Request methods

extension AlamofireSession {
    
    public func request(with sessionRequest: SessionRequest, completion: @escaping JSONResponseCompletion) {
        guard let alamofireRequest = sessionRequest as? AlamofireRequest else {
            completion(nil, .failure(.configurationError))
            return
        }
        let (taskOut, dataRequest) = request(alamofireRequest: alamofireRequest)
        finalizeJSONResponse(dataRequest: dataRequest, taskOut: taskOut, completion: completion)
    }
    
    public func request<T>(
        with sessionRequest: SessionRequest, jsonDecoder: JSONDecoder?, completion: @escaping DecodableResponseCompletion<T>
    ) where T: SessionDecodableResponse {
        guard let alamofireRequest = sessionRequest as? AlamofireRequest else {
            completion(nil, .failure(.configurationError))
            return
        }
        let (taskOut, dataRequest) = request(alamofireRequest: alamofireRequest)
        finalizeDecodableResponse(dataRequest: dataRequest, taskOut: taskOut, jsonDecoder: jsonDecoder, completion: completion)
    }
    
    private func request(alamofireRequest: AlamofireRequest) -> (() -> URLSessionDataTask?, DataRequest) {
        alamofireRequest.updateHeader()
        var taskOut: URLSessionDataTask?
        let dataRequest = self.session.request(alamofireRequest, interceptor: alamofireRequest.interceptor).onURLSessionTaskCreation { task in
            taskOut = task as? URLSessionDataTask
        }
        return ({ taskOut }, dataRequest)
    }
}

// MARK: - Download methods

extension AlamofireSession {
    
    public func download(with request: SessionRequest,
                         destinationDirectoryURL: URL,
                         completion: @escaping DownloadCompletion) {
        guard let alamofireRequest = request as? AlamofireRequest else {
            completion(nil, nil, nil)
            return
        }
        alamofireRequest.updateHeader()
        let destination: Alamofire.DownloadRequest.Destination = { _, _ in
            return (destinationDirectoryURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        self.session.download(alamofireRequest, interceptor: alamofireRequest.interceptor, to: destination)
            .response { response in
                let urlResponse = response.response
                switch response.result {
                case let .success(value):
                    completion(urlResponse, value, nil)
                case let .failure(error):
                    let err = error.underlyingError ?? error
                    completion(urlResponse, nil, err as NSError)
                }
            }
    }
}

// MARK: - Upload methods

// MARK: upload key data packets with signature

extension AlamofireSession {
    
    // swiftlint:disable function_parameter_count
    public func upload(with request: SessionRequest,
                       keyPacket: Data,
                       dataPacket: Data,
                       signature: Data?,
                       completion: @escaping JSONResponseCompletion,
                       uploadProgress: ProgressCompletion?) {
        
        guard let alamofireRequest = request as? AlamofireRequest,
              let parameters = alamofireRequest.parameters as? [String: String] else {
            completion(nil, .failure(.configurationError))
            return
        }
        
        let (taskOut, uploadRequest) = upload(with: alamofireRequest, parameters: parameters, keyPacket: keyPacket,
                                              dataPacket: dataPacket, signature: signature, uploadProgress: uploadProgress)
        finalizeJSONResponse(dataRequest: uploadRequest, taskOut: taskOut, completion: completion)
    }
    
    // swiftlint:disable function_parameter_count
    public func upload<T>(with request: SessionRequest,
                          keyPacket: Data,
                          dataPacket: Data,
                          signature: Data?,
                          jsonDecoder: JSONDecoder? = nil,
                          completion: @escaping DecodableResponseCompletion<T>,
                          uploadProgress: ProgressCompletion?) where T: SessionDecodableResponse {
        guard let alamofireRequest = request as? AlamofireRequest,
              let parameters = alamofireRequest.parameters as? [String: String] else {
            completion(nil, .failure(.configurationError))
            return
        }
        
        let (taskOut, uploadRequest) = upload(with: alamofireRequest, parameters: parameters, keyPacket: keyPacket,
                                              dataPacket: dataPacket, signature: signature, uploadProgress: uploadProgress)
        
        finalizeDecodableResponse(dataRequest: uploadRequest, taskOut: taskOut, jsonDecoder: jsonDecoder, completion: completion)
    }
    
    // swiftlint:disable function_parameter_count
    private func upload(with alamofireRequest: AlamofireRequest,
                        parameters: [String: String],
                        keyPacket: Data,
                        dataPacket: Data,
                        signature: Data?,
                        uploadProgress: ProgressCompletion?) -> (() -> URLSessionDataTask?, UploadRequest) {
        alamofireRequest.updateHeader()
        var taskOut: URLSessionDataTask?
        let uploadRequest = self.session.upload(multipartFormData: { (formData) -> Void in
            let data: MultipartFormData = formData
            if let value = parameters["Filename"], let fileName = value.data(using: .utf8) {
                data.append(fileName, withName: "Filename")
            }
            if let value = parameters["MIMEType"], let mimeType = value.data(using: .utf8) {
                data.append(mimeType, withName: "MIMEType")
            }
            if let value = parameters["MessageID"], let id = value.data(using: .utf8) {
                data.append(id, withName: "MessageID")
            }
            if let value = parameters["ContentID"],
               let id = value.data(using: .utf8) {
                data.append(id, withName: "ContentID")
            }
            if let value = parameters["Disposition"],
               let position = value.data(using: .utf8) {
                data.append(position, withName: "Disposition")
            }
            data.append(keyPacket, withName: "KeyPackets", fileName: "KeyPackets.txt", mimeType: "" )
            data.append(dataPacket, withName: "DataPacket", fileName: "DataPacket.txt", mimeType: "" )
            if let sign = signature {
                data.append(sign, withName: "Signature", fileName: "Signature.txt", mimeType: "" )
            }
        }, with: alamofireRequest, interceptor: alamofireRequest.interceptor)
        .onURLSessionTaskCreation { task in
            taskOut = task as? URLSessionDataTask
        }
        .uploadProgress { (progress) in
            uploadProgress?(progress)
        }
        return ({ taskOut }, uploadRequest)
    }
}

// MARK: upload files on disk

extension AlamofireSession {
    
    public func upload(with request: SessionRequest,
                       files: [String: URL],
                       completion: @escaping JSONResponseCompletion,
                       uploadProgress: ProgressCompletion?) {
        guard let alamofireRequest = request as? AlamofireRequest,
              let parameters = alamofireRequest.parameters as? [String: String] else {
            completion(nil, .failure(.configurationError))
            return
        }
        let (taskOut, uploadRequest) = upload(with: alamofireRequest, parameters: parameters, files: files, uploadProgress: uploadProgress)
        finalizeJSONResponse(dataRequest: uploadRequest, taskOut: taskOut, completion: completion)
    }
    
    public func upload<T>(with request: SessionRequest,
                          files: [String: URL],
                          jsonDecoder: JSONDecoder?,
                          completion: @escaping DecodableResponseCompletion<T>,
                          uploadProgress: ProgressCompletion?) where T: SessionDecodableResponse {
        guard let alamofireRequest = request as? AlamofireRequest,
              let parameters = alamofireRequest.parameters as? [String: String] else {
            completion(nil, .failure(.configurationError))
            return
        }
        let (taskOut, uploadRequest) = upload(with: alamofireRequest, parameters: parameters, files: files, uploadProgress: uploadProgress)
        finalizeDecodableResponse(dataRequest: uploadRequest, taskOut: taskOut, jsonDecoder: jsonDecoder, completion: completion)
    }
    
    private func upload(with alamofireRequest: AlamofireRequest,
                        parameters: [String: String],
                        files: [String: URL],
                        uploadProgress: ProgressCompletion?) -> (() -> URLSessionDataTask?, UploadRequest) {
        alamofireRequest.updateHeader()
        var taskOut: URLSessionDataTask?
        let uploadRequest = self.session.upload(multipartFormData: { (formData) -> Void in
            let data: MultipartFormData = formData
            for (key, value) in parameters {
                if let valueData = value.data(using: .utf8) {
                    data.append(valueData, withName: key)
                }
            }
            
            for (name, file) in files {
                data.append(file, withName: name)
            }
        }, with: alamofireRequest, interceptor: alamofireRequest.interceptor)
        .onURLSessionTaskCreation { task in
            taskOut = task as? URLSessionDataTask
        }
        .uploadProgress { (progress) in
            uploadProgress?(progress)
        }
        return ({ taskOut }, uploadRequest)
    }
}

// MARK: upload data packet from disk

extension AlamofireSession {
    
    // swiftlint:disable function_parameter_count
    public func uploadFromFile(with request: SessionRequest,
                               keyPacket: Data,
                               dataPacketSourceFileURL: URL,
                               signature: Data?,
                               completion: @escaping JSONResponseCompletion,
                               uploadProgress: ProgressCompletion?) {
        
        guard let alamofireRequest = request as? AlamofireRequest,
              let parameters = alamofireRequest.parameters as? [String: String] else {
            completion(nil, .failure(.configurationError))
            return
        }
        let (taskOut, uploadRequest) = uploadFromFile(
            alamofireRequest: alamofireRequest, parameters: parameters, keyPacket: keyPacket,
            dataPacketSourceFileURL: dataPacketSourceFileURL, signature: signature, uploadProgress: uploadProgress
        )
        finalizeJSONResponse(dataRequest: uploadRequest, taskOut: taskOut, completion: completion)
    }
    
    // swiftlint:disable function_parameter_count
    public func uploadFromFile<T>(with request: SessionRequest,
                                  keyPacket: Data,
                                  dataPacketSourceFileURL: URL,
                                  signature: Data?,
                                  jsonDecoder: JSONDecoder? = nil,
                                  completion: @escaping DecodableResponseCompletion<T>,
                                  uploadProgress: ProgressCompletion?) where T: SessionDecodableResponse {
        
        guard let alamofireRequest = request as? AlamofireRequest,
              let parameters = alamofireRequest.parameters as? [String: String] else {
            completion(nil, .failure(.configurationError))
            return
        }
        let (taskOut, uploadRequest) = uploadFromFile(
            alamofireRequest: alamofireRequest, parameters: parameters, keyPacket: keyPacket,
            dataPacketSourceFileURL: dataPacketSourceFileURL, signature: signature, uploadProgress: uploadProgress
        )
        finalizeDecodableResponse(dataRequest: uploadRequest, taskOut: taskOut, jsonDecoder: jsonDecoder, completion: completion)
    }
    
    // swiftlint:disable function_parameter_count
    private func uploadFromFile(alamofireRequest: AlamofireRequest,
                                parameters: [String: String],
                                keyPacket: Data,
                                dataPacketSourceFileURL: URL,
                                signature: Data?,
                                uploadProgress: ProgressCompletion?) -> (() -> URLSessionDataTask?, UploadRequest) {
        
        alamofireRequest.updateHeader()
        var taskOut: URLSessionDataTask?
        let uploadRequest = self.session.upload(multipartFormData: { (formData) -> Void in
            let data: MultipartFormData = formData
            if let value = parameters["Filename"], let fileName = value.data(using: .utf8) {
                data.append(fileName, withName: "Filename")
            }
            if let value = parameters["MIMEType"], let mimeType = value.data(using: .utf8) {
                data.append(mimeType, withName: "MIMEType")
            }
            if let value = parameters["MessageID"], let id = value.data(using: .utf8) {
                data.append(id, withName: "MessageID")
            }
            if let value = parameters["ContentID"],
               let id = value.data(using: .utf8) {
                data.append(id, withName: "ContentID")
            }
            if let value = parameters["Disposition"],
               let position = value.data(using: .utf8) {
                data.append(position, withName: "Disposition")
            }
            data.append(keyPacket, withName: "KeyPackets", fileName: "KeyPackets.txt", mimeType: "" )
            data.append(dataPacketSourceFileURL, withName: "DataPacket", fileName: "DataPacket.txt", mimeType: "")
            if let sign = signature {
                data.append(sign, withName: "Signature", fileName: "Signature.txt", mimeType: "" )
            }
        }, with: alamofireRequest, interceptor: alamofireRequest.interceptor)
        .onURLSessionTaskCreation { task in
            taskOut = task as? URLSessionDataTask
        }
        .uploadProgress { (progress) in
            uploadProgress?(progress)
        }
        return ({ taskOut }, uploadRequest)
    }
}

class AlamofireRequest: SessionRequest, URLRequestConvertible {
    
    var parameterEncoding: ParameterEncoding {
        switch method {
        case .get:
            return URLEncoding.default
        default:
            return JSONEncoding.default
        }
    }
    
    override init(parameters: Any?, urlString: String, method: HTTPMethod, timeout: TimeInterval, retryPolicy: ProtonRetryPolicy.RetryMode) {
        // super.init(parameters: parameters, urlString: urlString, method: method, timeout: 1, retryPolicy: retryPolicy)
        super.init(parameters: parameters, urlString: urlString, method: method, timeout: timeout, retryPolicy: retryPolicy)
        // TODO: this url need to add a validation and throws
        let url = URL.init(string: urlString)!
        self.request = URLRequest(url: url)
        self.request?.timeoutInterval = timeout
        self.request?.httpMethod = self.method.rawValue
    }
    
    func asURLRequest() throws -> URLRequest {
        return try parameterEncoding.encode(request!, with: parameters as? [String: Any])
    }
}

#endif
