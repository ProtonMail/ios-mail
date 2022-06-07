//
//  APIServiceMock.swift
//  ProtonCore-TestingToolkit - Created on 03.06.2021.
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
import ProtonCore_Networking
import ProtonCore_Services

// swiftlint:disable function_parameter_count

public struct APIServiceMock: APIService {

    static let jsonSerializer = JSONSerialization()

    public init() {}

    @FuncStub(APIServiceMock.setSessionUID) public var setSessionUIDStub
    public func setSessionUID(uid: String) { setSessionUIDStub(uid) }

    @PropertyStub(\APIServiceMock.sessionUID, initialGet: .crash) public var sessionUIDStub
    public var sessionUID: String { sessionUIDStub() }
    
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
    public func request(method: HTTPMethod, path: String, parameters: Any?, headers: [String: Any]?, authenticated: Bool, autoRetry: Bool, customAuthCredential: AuthCredential?, nonDefaultTimeout: TimeInterval?, completion: CompletionBlock?) {
        requestStub(method, path, parameters, headers, authenticated, autoRetry, customAuthCredential, nonDefaultTimeout, completion)
    }

    @FuncStub(APIServiceMock.download) public var downloadStub
    public func download(byUrl url: String, destinationDirectoryURL: URL, headers: [String: Any]?, authenticated: Bool, customAuthCredential: AuthCredential?, nonDefaultTimeout: TimeInterval?, downloadTask: ((URLSessionDownloadTask) -> Void)?, completion: @escaping ((URLResponse?, URL?, NSError?) -> Void)) {
        downloadStub(url, destinationDirectoryURL, headers, authenticated, customAuthCredential, nonDefaultTimeout, downloadTask, completion)
    }

    @FuncStub(APIServiceMock.upload(byPath:parameters:keyPackets:dataPacket:signature:headers:authenticated:customAuthCredential:nonDefaultTimeout:completion:)) public var uploadStub
    public func upload(byPath path: String, parameters: [String: String], keyPackets: Data, dataPacket: Data, signature: Data?, headers: [String: Any]?, authenticated: Bool, customAuthCredential: AuthCredential?, nonDefaultTimeout: TimeInterval?, completion: @escaping CompletionBlock) {
        uploadStub(path, parameters, keyPackets, dataPacket, signature, headers, authenticated, customAuthCredential, nonDefaultTimeout, completion)
    }

    @FuncStub(APIServiceMock.uploadFromFile) public var uploadFromFileStub
    public func uploadFromFile(byPath path: String, parameters: [String: String], keyPackets: Data, dataPacketSourceFileURL: URL, signature: Data?, headers: [String: Any]?, authenticated: Bool, customAuthCredential: AuthCredential?, nonDefaultTimeout: TimeInterval?, completion: @escaping CompletionBlock) {
        uploadFromFileStub(path, parameters, keyPackets, dataPacketSourceFileURL, signature, headers, authenticated, customAuthCredential, nonDefaultTimeout, completion)
    }
    
    @FuncStub(APIServiceMock.upload(byPath:parameters:files:headers:authenticated:customAuthCredential:nonDefaultTimeout:uploadProgress:completion:)) public var uploadFilesStub
    public func upload(byPath path: String, parameters: Any?, files: [String: URL], headers: [String: Any]?, authenticated: Bool, customAuthCredential: AuthCredential?, nonDefaultTimeout: TimeInterval?, uploadProgress: ProgressCompletion?, completion: @escaping CompletionBlock) {
        uploadFilesStub(path, parameters, files, headers, authenticated, customAuthCredential, nonDefaultTimeout, uploadProgress, completion)
    }
}

public final class URLSessionDataTaskMock: URLSessionDataTask {

    @PropertyStub(\URLSessionDataTask.taskIdentifier, initialGet: 0) public var taskIdentifierStub
    override public var taskIdentifier: Int { taskIdentifierStub() }

    @PropertyStub(\URLSessionDataTask.originalRequest, initialGet: nil) public var originalRequestStub
    override public var originalRequest: URLRequest? { originalRequestStub() }

    @PropertyStub(\URLSessionDataTask.currentRequest, initialGet: nil) public var currentRequestStub
    override public var currentRequest: URLRequest? { currentRequestStub() }

    @PropertyStub(\URLSessionDataTask.response, initialGet: nil) public var responseStub
    override public var response: URLResponse? { responseStub() }

    @PropertyStub(\URLSessionDataTask.countOfBytesReceived, initialGet: 0) public var countOfBytesReceivedStub
    override public var countOfBytesReceived: Int64 { countOfBytesReceivedStub() }

    @PropertyStub(\URLSessionDataTask.countOfBytesSent, initialGet: 0) public var countOfBytesSentStub
    override public var countOfBytesSent: Int64 { countOfBytesSentStub() }

    @PropertyStub(\URLSessionDataTask.countOfBytesExpectedToSend, initialGet: 0) public var countOfBytesExpectedToSendStub
    override public var countOfBytesExpectedToSend: Int64 { countOfBytesExpectedToSendStub() }

    @PropertyStub(\URLSessionDataTask.countOfBytesExpectedToReceive, initialGet: 0) public var countOfBytesExpectedToReceiveStub
    override public var countOfBytesExpectedToReceive: Int64 { countOfBytesExpectedToReceiveStub() }

    @PropertyStub(\URLSessionDataTask.taskDescription, initialGet: nil) public var taskDescriptionStub
    override public var taskDescription: String? { get { taskDescriptionStub() } set { taskDescriptionStub.fixture = newValue } }

    @FuncStub(URLSessionDataTask.cancel) public var cancelStub
    override public func cancel() { cancelStub() }

    @PropertyStub(\URLSessionDataTask.state, initialGet: .crash) public var stateStub
    override public var state: URLSessionTask.State { stateStub() }

    @PropertyStub(\URLSessionDataTask.error, initialGet: nil) public var errorStub
    override public var error: Error? { errorStub() }

    @FuncStub(URLSessionDataTask.suspend) public var suspendStub
    override public func suspend() { suspendStub() }

    @FuncStub(URLSessionDataTask.resume) public var resumeStub
    override public func resume() { resumeStub() }

    @PropertyStub(\URLSessionDataTask.priority, initialGet: 0) public var priorityStub
    override public var priority: Float { get { priorityStub() } set { priorityStub.fixture = newValue } }

    @available(iOS 11.0, macOS 10.13, *)
    public final class macOS10_13 {
        public static let shared = macOS10_13()

        @PropertyStub(\URLSessionDataTask.progress, initialGet: .crash) public var progressStub

        @PropertyStub(\URLSessionDataTask.earliestBeginDate, initialGet: nil) public var earliestBeginDateStub

        @PropertyStub(\URLSessionDataTask.countOfBytesClientExpectsToSend, initialGet: 0) public var countOfBytesClientExpectsToSendStub

        @PropertyStub(\URLSessionDataTask.countOfBytesClientExpectsToReceive, initialGet: 0) public var countOfBytesClientExpectsToReceiveStub
    }

    @available(iOS 11.0, macOS 10.13, *)
    override public var progress: Progress { macOS10_13.shared.progressStub() }

    @available(iOS 11.0, macOS 10.13, *)
    override public var earliestBeginDate: Date? {
        get { macOS10_13.shared.earliestBeginDateStub() }
        set { macOS10_13.shared.earliestBeginDateStub.fixture = newValue }
    }

    @available(iOS 11.0, macOS 10.13, *)
    override public var countOfBytesClientExpectsToSend: Int64 {
        get { macOS10_13.shared.countOfBytesClientExpectsToSendStub() }
        set { macOS10_13.shared.countOfBytesClientExpectsToSendStub.fixture = newValue }
    }

    @available(iOS 11.0, macOS 10.13, *)
    override public var countOfBytesClientExpectsToReceive: Int64 {
        get { macOS10_13.shared.countOfBytesClientExpectsToReceiveStub() }
        set { macOS10_13.shared.countOfBytesClientExpectsToReceiveStub.fixture = newValue }
    }

    @available(iOS 14.5, macOS 11.3, *)
    public final class iOS14_5 {
        public static let shared = iOS14_5()
        @PropertyStub(\URLSessionDataTask.prefersIncrementalDelivery, initialGet: false) public var prefersIncrementalDeliveryStub
    }

    @available(iOS 14.5, macOS 11.3, *)
    override public var prefersIncrementalDelivery: Bool {
        get { iOS14_5.shared.prefersIncrementalDeliveryStub() }
        set { iOS14_5.shared.prefersIncrementalDeliveryStub.fixture = newValue }
    }

    override public init() {}

    public convenience init(response: HTTPURLResponse) {
        self.init()
        responseStub.fixture = response
    }
}

public extension HTTPURLResponse {
    convenience init(statusCode: Int) {
        self.init(url: URL(string: "https://example.com")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}

public extension APIServiceMock {

    enum PathRequirement {
        case startsWith(String)
        case contains(String)
        case endsWith(String)
    }

    func stubResponse(statusCode: Int, body: String?, error: NSError?, whenPath: PathRequirement, method: HTTPMethod? = nil) {
        let responseDict: [String: Any]?
        if let body = body {
            let jsonObject = try! JSONSerialization.jsonObject(with: body.data(using: .utf8)!, options: [])
            responseDict = (jsonObject as! [String: Any])
        } else {
            responseDict = nil
        }
        let forPath: (String) -> Bool
        switch whenPath {
        case .startsWith(let path): forPath = { $0.hasPrefix(path) }
        case .contains(let path): forPath = { $0.contains(path) }
        case .endsWith(let path): forPath = { $0.hasSuffix(path) }
        }
        stubResponse(task: .init(response: .init(statusCode: statusCode)), responseDict: responseDict, error: error, forPath: forPath)
    }

    func stubResponse(task: URLSessionDataTaskMock?,
                      responseDict: [String: Any]?,
                      error: NSError?,
                      forPath: @escaping (String) -> Bool,
                      method requiredMethod: HTTPMethod? = nil) {
        requestStub.addToBody { counter, method, path, parameters, headers, authenticated, autoRetry, customAuthCredential, nonDefaultTimeout, completion in
            let pathFits = forPath(path)
            let methodFits = requiredMethod.map { method == $0 } ?? true
            if pathFits && methodFits {
                completion?(task, responseDict, error)
            }
        }
    }
}
