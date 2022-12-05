//
//  SessionMock.swift
//  ProtonCore-TestingToolkit - Created on 16.02.2022.
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

import TrustKit
import ProtonCore_Networking

public typealias AnyDecodableResponseCompletion = (_ task: URLSessionDataTask?, _ result: Result<Any, SessionResponseError>) -> Void

public final class SessionMock: Session {

    public init() {}
    
    private func eraseGenerics<T>(from completion: @escaping DecodableResponseCompletion<T>) -> AnyDecodableResponseCompletion where T: SessionDecodableResponse {
        { task, result in completion(task, result.map { $0 as! T }) }
    }
    
    @PropertyStub(\Session.sessionConfiguration, initialGet: .default) public var sessionConfigurationStub
    public var sessionConfiguration: URLSessionConfiguration { sessionConfigurationStub() }
    
    @ThrowingFuncStub(SessionMock.generate, initialReturn: .crash) public var generateStub
    public func generate(with method: HTTPMethod, urlString: String, parameters: Any?, timeout: TimeInterval?, retryPolicy: ProtonRetryPolicy.RetryMode) throws -> SessionRequest {
        try generateStub(method, urlString, parameters, timeout, retryPolicy)
    }
    
    @FuncStub(SessionMock.request(with:completion:)) public var requestJSONStub
    public func request(with request: SessionRequest, completion: @escaping JSONResponseCompletion) {
        requestJSONStub(request, completion)
    }
    
    private func genericRequestErased(with request: SessionRequest, jsonDecoder: JSONDecoder?, completion: @escaping AnyDecodableResponseCompletion) {}
    @FuncStub(SessionMock.genericRequestErased(with:jsonDecoder:completion:)) public var requestDecodableStub
    public func request<T>(with request: SessionRequest,
                           jsonDecoder: JSONDecoder?,
                           completion: @escaping DecodableResponseCompletion<T>) where T: SessionDecodableResponse {
        requestDecodableStub(request, jsonDecoder, eraseGenerics(from: completion))
    }
    
    @FuncStub(SessionMock.download(with:destinationDirectoryURL:completion:)) public var downloadStub
    public func download(with request: SessionRequest, destinationDirectoryURL: URL, completion: @escaping DownloadCompletion) {
        downloadStub(request, destinationDirectoryURL, completion)
    }
    
    @FuncStub(SessionMock.upload(with:keyPacket:dataPacket:signature:completion:uploadProgress:)) public var uploadJSONStub
    // swiftlint:disable function_parameter_count
    public func upload(with request: SessionRequest, keyPacket: Data, dataPacket: Data, signature: Data?,
                       completion: @escaping JSONResponseCompletion, uploadProgress: ProgressCompletion?) {
        uploadJSONStub(request, keyPacket, dataPacket, signature, completion, uploadProgress)
    }
    
    // swiftlint:disable function_parameter_count
    private func uploadNoGenerics(with: SessionRequest, keyPacket: Data, dataPacket: Data, signature: Data?, jsonDecoder: JSONDecoder?,
                                  completion: @escaping AnyDecodableResponseCompletion, uploadProgress: ProgressCompletion?) {}
    @FuncStub(SessionMock.uploadNoGenerics(with:keyPacket:dataPacket:signature:jsonDecoder:completion:uploadProgress:)) public var uploadDecodableStub
    // swiftlint:disable function_parameter_count
    public func upload<T>(with request: SessionRequest,
                          keyPacket: Data,
                          dataPacket: Data,
                          signature: Data?,
                          jsonDecoder: JSONDecoder?,
                          completion: @escaping DecodableResponseCompletion<T>,
                          uploadProgress: ProgressCompletion?) where T: SessionDecodableResponse {
        uploadDecodableStub(request, keyPacket, dataPacket, signature, jsonDecoder, eraseGenerics(from: completion), uploadProgress)
    }
    
    @FuncStub(SessionMock.upload(with:files:completion:uploadProgress:)) public var uploadWithFilesJSONStub
    public func upload(with request: SessionRequest, files: [String: URL], completion: @escaping JSONResponseCompletion, uploadProgress: ProgressCompletion?) {
        uploadWithFilesJSONStub(request, files, completion, uploadProgress)
    }
    
    private func uploadNoGenerics(with: SessionRequest, files: [String: URL], jsonDecoder: JSONDecoder?, completion: @escaping AnyDecodableResponseCompletion, uploadProgress: ProgressCompletion?) {}
    @FuncStub(SessionMock.uploadNoGenerics(with:files:jsonDecoder:completion:uploadProgress:)) public var uploadWithFilesDecodableStub
    public func upload<T>(with request: SessionRequest,
                          files: [String: URL],
                          jsonDecoder: JSONDecoder?,
                          completion: @escaping DecodableResponseCompletion<T>,
                          uploadProgress: ProgressCompletion?) where T: SessionDecodableResponse {
        uploadWithFilesDecodableStub(request, files, jsonDecoder, eraseGenerics(from: completion), uploadProgress)
    }

    @FuncStub(SessionMock.uploadFromFile(with:keyPacket:dataPacketSourceFileURL:signature:completion:uploadProgress:)) public var uploadFromFileJSONStub
    // swiftlint:disable function_parameter_count
    public func uploadFromFile(with request: SessionRequest,
                               keyPacket: Data,
                               dataPacketSourceFileURL: URL,
                               signature: Data?,
                               completion: @escaping JSONResponseCompletion,
                               uploadProgress: ProgressCompletion?) {
        uploadFromFileJSONStub(request, keyPacket, dataPacketSourceFileURL, signature, completion, uploadProgress)
    }
    
    private func uploadFromFileNoGenerics(with request: SessionRequest, keyPacket: Data, dataPacketSourceFileURL: URL, signature: Data?,
                                          jsonDecoder: JSONDecoder?, completion: @escaping AnyDecodableResponseCompletion,
                                          uploadProgress: ProgressCompletion?) {}
    @FuncStub(SessionMock.uploadFromFileNoGenerics(with:keyPacket:dataPacketSourceFileURL:signature:jsonDecoder:completion:uploadProgress:)) public var uploadFromFileDecodableStub
    // swiftlint:disable function_parameter_count
    public func uploadFromFile<T>(with request: SessionRequest,
                                  keyPacket: Data,
                                  dataPacketSourceFileURL: URL,
                                  signature: Data?,
                                  jsonDecoder: JSONDecoder?,
                                  completion: @escaping DecodableResponseCompletion<T>,
                                  uploadProgress: ProgressCompletion?) where T: SessionDecodableResponse {
        uploadFromFileDecodableStub(request, keyPacket, dataPacketSourceFileURL, signature, jsonDecoder, eraseGenerics(from: completion), uploadProgress)
    }
    
    @FuncStub(SessionMock.setChallenge) public var setChallengeStub
    public func setChallenge(noTrustKit: Bool, trustKit: TrustKit?) {
        setChallengeStub(noTrustKit, trustKit)
    }

    @FuncStub(SessionMock.failsTLS, initialReturn: nil) public var failsTLSStub
    public func failsTLS(request: SessionRequest) -> String? {
        failsTLSStub(request)
    }
    
}
