//
//  APIServiceMock.swift
//  ProtonCore-TestingToolkit - Created on 03.06.2021.
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

import ProtonCore_Doh
import ProtonCore_Networking
import ProtonCore_Services

// swiftlint:disable function_parameter_count

public struct APIServiceMock: APIService {

    public init() {}

    @FuncStub(APIServiceMock.setSessionUID) public var setSessionUIDStub
    public func setSessionUID(uid: String) { setSessionUIDStub(uid) }

    @PropertyStub(\APIServiceMock.serviceDelegate, initialGet: .crash) public var serviceDelegateStub
    public var serviceDelegate: APIServiceDelegate? { get { serviceDelegateStub() } set { serviceDelegateStub(newValue) } }

    @PropertyStub(\APIServiceMock.authDelegate, initialGet: .crash) public var authDelegateStub
    public var authDelegate: AuthDelegate? { get { authDelegateStub() } set { authDelegateStub(newValue) } }

    @PropertyStub(\APIServiceMock.humanDelegate, initialGet: .crash) public var humanDelegateStub
    public var humanDelegate: HumanVerifyDelegate? { get { humanDelegateStub() } set { humanDelegateStub(newValue) } }

    @PropertyStub(\APIServiceMock.doh, initialGet: .crash) public var dohStub
    public var doh: DoH & ServerConfig { get { dohStub() } set { dohStub(newValue) } }

    @PropertyStub(\APIServiceMock.signUpDomain, initialGet: .crash) public var signUpDomainStub
    public var signUpDomain: String { signUpDomainStub() }

    @FuncStub(APIServiceMock.request) public var requestStub
    public func request(method: HTTPMethod, path: String, parameters: Any?, headers: [String: Any]?, authenticated: Bool, autoRetry: Bool, customAuthCredential: AuthCredential?, completion: CompletionBlock?) {
        requestStub(method, path, parameters, headers, authenticated, autoRetry, customAuthCredential, completion)
    }

    @FuncStub(APIServiceMock.download) public var downloadStub
    public func download(byUrl url: String, destinationDirectoryURL: URL, headers: [String: Any]?, authenticated: Bool, customAuthCredential: AuthCredential?, downloadTask: ((URLSessionDownloadTask) -> Void)?, completion: @escaping ((URLResponse?, URL?, NSError?) -> Void)) {
        downloadStub(url, destinationDirectoryURL, headers, authenticated, customAuthCredential, downloadTask, completion)
    }

//    @FuncStub(APIServiceMock.upload) public var uploadStub
    public func upload(byPath path: String, parameters: [String: String], keyPackets: Data, dataPacket: Data, signature: Data?, headers: [String: Any]?, authenticated: Bool, customAuthCredential: AuthCredential?, completion: @escaping CompletionBlock) {
//        uploadStub(path, parameters, keyPackets, dataPacket, signature, headers, authenticated, customAuthCredential, completion)
    }

    @FuncStub(APIServiceMock.uploadFromFile) public var uploadFromFileStub
    public func uploadFromFile(byPath path: String, parameters: [String: String], keyPackets: Data, dataPacketSourceFileURL: URL, signature: Data?, headers: [String: Any]?, authenticated: Bool, customAuthCredential: AuthCredential?, completion: @escaping CompletionBlock) {
        uploadFromFileStub(path, parameters, keyPackets, dataPacketSourceFileURL, signature, headers, authenticated, customAuthCredential, completion)
    }
    
    public func upload(byPath path: String, parameters: Any?, files: [String : URL], headers: [String : Any]?, authenticated: Bool, customAuthCredential: AuthCredential?, uploadProgress: ProgressCompletion?, completion: @escaping CompletionBlock) {
    }
}
