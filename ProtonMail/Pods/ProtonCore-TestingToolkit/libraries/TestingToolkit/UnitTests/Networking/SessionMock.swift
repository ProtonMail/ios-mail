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

public final class SessionMock: Session {
    
    public init() {}
    
    @ThrowingFuncStub(SessionMock.generate, initialReturn: .crash) public var generateStub
    public func generate(with method: HTTPMethod, urlString: String, parameters: Any?, timeout: TimeInterval?) throws -> SessionRequest {
        try generateStub(method, urlString, parameters, timeout)
    }
    
    @ThrowingFuncStub(SessionMock.request(with:completion:)) public var requestStub
    public func request(with request: SessionRequest, completion: @escaping ResponseCompletion) throws {
        try requestStub(request, completion)
    }
    
    @ThrowingFuncStub(SessionMock.upload(with:keyPacket:dataPacket:signature:completion:)) public var uploadStub
    public func upload(with request: SessionRequest, keyPacket: Data, dataPacket: Data, signature: Data?, completion: @escaping ResponseCompletion) throws {
        try uploadStub(request, keyPacket, dataPacket, signature, completion)
    }

    @ThrowingFuncStub(SessionMock.upload(with:keyPacket:dataPacket:signature:completion:uploadProgress:)) public var uploadWithProgressStub
    // swiftlint:disable function_parameter_count
    public func upload(with request: SessionRequest,
                       keyPacket: Data, dataPacket: Data, signature: Data?,
                       completion: @escaping ResponseCompletion,
                       uploadProgress: ProgressCompletion?) throws {
        try uploadWithProgressStub(request, keyPacket, dataPacket, signature, completion, uploadProgress)
    }
    
    @ThrowingFuncStub(SessionMock.upload(with:files:completion:uploadProgress:)) public var uploadWithFilesStub
    public func upload(with request: SessionRequest,
                       files: [String: URL],
                       completion: @escaping ResponseCompletion,
                       uploadProgress: ProgressCompletion?) throws {
        try uploadWithFilesStub(request, files, completion, uploadProgress)
    }

    @ThrowingFuncStub(SessionMock.uploadFromFile(with:keyPacket:dataPacketSourceFileURL:signature:completion:)) public var uploadFromFileStub
    public func uploadFromFile(with request: SessionRequest,
                               keyPacket: Data, dataPacketSourceFileURL: URL, signature: Data?,
                               completion: @escaping ResponseCompletion) throws {
        try uploadFromFileStub(request, keyPacket, dataPacketSourceFileURL, signature, completion)
    }

    @ThrowingFuncStub(SessionMock.uploadFromFile(with:keyPacket:dataPacketSourceFileURL:signature:completion:uploadProgress:)) public var uploadFromFileWithProgressStub
    // swiftlint:disable function_parameter_count
    public func uploadFromFile(with request: SessionRequest,
                               keyPacket: Data, dataPacketSourceFileURL: URL, signature: Data?,
                               completion: @escaping ResponseCompletion,
                               uploadProgress: ProgressCompletion?) throws {
        try uploadFromFileWithProgressStub(request, keyPacket, dataPacketSourceFileURL, signature, completion, uploadProgress)
    }

    @ThrowingFuncStub(SessionMock.download(with:destinationDirectoryURL:completion:)) public var downloadStub
    public func download(with request: SessionRequest, destinationDirectoryURL: URL, completion: @escaping DownloadCompletion) throws {
        try downloadStub(request, destinationDirectoryURL, completion)
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
