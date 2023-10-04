//
//  SRPBuilder.swift
//  ProtonCore-Authentication - Created on 03.05.23.
//
//  Copyright (c) 2023 Proton Technologies AG
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import ProtonCoreCryptoGoInterface
import ProtonCoreNetworking
import ProtonCoreServices

public protocol SRPBuilderProtocol {
    func buildSRP(username: String, password: String, authInfo: AuthInfoResponse, srpAuth: SrpAuth?) throws -> Result<SRPClientInfo, AuthErrors>
}

public extension SRPBuilderProtocol {
    func buildSRP(username: String, password: String, authInfo: AuthInfoResponse) throws -> Result<SRPClientInfo, AuthErrors> {
        try buildSRP(username: username, password: password, authInfo: authInfo, srpAuth: nil)
    }
}

public struct SRPBuilder: SRPBuilderProtocol {
    public init() {}
    
    /**
     A function that provides SRP (Secure Remote Password) client information to validate the password.
     - Parameter username: The user's username.
     - Parameter password: The user's password.
     - Parameter authInfo: The users's authentication info, required to compute the SRP.
     - Parameter srpAuth: The SRP Auth object that stores byte data for the calculation of SRP proofs. It is injected here to be able to mock it in test. It is supposed to be left nil in the implementation. The SRPAuth is calculated with the previous parameters.
     - Returns: The SRP client info required to validate the password.
     */
    public func buildSRP(username: String, password: String, authInfo: AuthInfoResponse, srpAuth: SrpAuth? = nil) throws -> Result<SRPClientInfo, AuthErrors> {
        let passSlice = password.data(using: .utf8)
        guard let auth = srpAuth ?? CryptoGo.SrpAuth(authInfo.version,
                                                     username,
                                                     passSlice,
                                                     authInfo.salt,
                                                     authInfo.modulus,
                                                     authInfo.serverEphemeral) else
        {
            return .failure(AuthErrors.emptyServerSrpAuth)
        }
        
        // client SRP
        let srpClient = try auth.generateProofs(2048)
        guard let clientEphemeral = srpClient.clientEphemeral,
              let clientProof = srpClient.clientProof,
              let expectedServerProof = srpClient.expectedServerProof else
        {
            return .failure(AuthErrors.emptyClientSrpAuth)
        }
        
        return .success(SRPClientInfo(
            clientEphemeral: clientEphemeral,
            clientProof: clientProof,
            expectedServerProof: expectedServerProof
        ))
    }
}
