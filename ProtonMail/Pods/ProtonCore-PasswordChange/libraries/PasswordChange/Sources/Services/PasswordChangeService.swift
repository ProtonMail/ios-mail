//
//  PasswordChangeService.swift
//  ProtonCore-PasswordChange - Created on 20.03.2024.
//
//  Copyright (c) 2024 Proton Technologies AG
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

#if os(iOS)

import Foundation

import ProtonCoreAPIClient
import ProtonCoreAuthentication
import ProtonCoreAuthenticationKeyGeneration
import ProtonCoreCrypto
import ProtonCoreDataModel
import ProtonCoreLog
import ProtonCoreNetworking
import ProtonCoreServices
import ProtonCorePasswordRequest

public class PasswordChangeService {
    private let apiService: APIService
    private let authService: AuthService

    // MARK: Public interface

    public init(api: APIService) {
        self.apiService = api
        self.authService = .init(api: api)
    }

    public func updateLoginPassword(auth currentAuth: AuthCredential,
                                    userInfo: UserInfo,
                                    loginPassword: String,
                                    newPassword: Passphrase,
                                    twoFACode: String?) async throws {

        let username = userInfo.userAddresses.defaultAddress()?.email ?? ""

        guard let passwordAuth = try await generatePasswordAuth(newPassword: newPassword) else {
            throw UpdatePasswordError.default
        }

        let (_, info): (URLSessionDataTask?, AuthInfoResponse) = try await apiService.perform(request: AuthAPI.Router.info(username: username))

        guard let auth = try SrpAuth(version: info.version,
                                     username: username,
                                     password: loginPassword,
                                     salt: info.salt,
                                     signedModulus: info.modulus,
                                     serverEphemeral: info.serverEphemeral) else {
            throw UpdatePasswordError.cantHashPassword
        }

        let srpClient = try auth.generateProofs(2048)
        guard let clientEphemeral = srpClient.clientEphemeral, let clientProof = srpClient.clientProof else {
            throw UpdatePasswordError.cantGenerateSRPClient
        }

        let passwordChangeRequest = PasswordChangeRequest(clientEphemeral: clientEphemeral.encodeBase64(),
                                                          clientProof: clientProof.encodeBase64(),
                                                          srpSession: info.srpSession,
                                                          twoFACode: twoFACode,
                                                          modulusID: passwordAuth.modulusID,
                                                          salt: passwordAuth.salt,
                                                          verifier: passwordAuth.verifier)

        let (_, updatePasswordResponse): (URLSessionDataTask?, DefaultResponse) = try await self.apiService.perform(
            request: passwordChangeRequest
        )
        guard updatePasswordResponse.responseCode == 1000 else {
            let responseCode = updatePasswordResponse.responseCode ?? 0
            let errorMessage = updatePasswordResponse.error?.localizedDescription ?? "Unknown"
            PMLog.error("\(responseCode): \(errorMessage)")
            throw UpdatePasswordError.default
        }
    }

    public func updateUserPassword(auth currentAuth: AuthCredential,
                                   userInfo: UserInfo,
                                   authInfo authInfoResponse: AuthInfoResponse? = nil,
                                   loginPassword: String,
                                   newPassword: Passphrase,
                                   twoFAParams: TwoFAParams? = nil,
                                   buildAuth: Bool) async throws {

        let oldPassword = Passphrase(value: currentAuth.mailboxpassword)
        let username = userInfo.userAddresses.defaultAddress()?.email ?? ""

        let resultOfKeyUpdate = try generateLocalKeys(userInfo: userInfo,
                                                      oldPassword: oldPassword,
                                                      newPassword: newPassword)

        var passwordAuth: PasswordAuth?
        if buildAuth {
            passwordAuth = try await generatePasswordAuth(newPassword: newPassword)
        }

        let authInfo: AuthInfoResponse

        if authInfoResponse != nil { authInfo = authInfoResponse! } else {
           (_, authInfo) = try await apiService.perform(request: AuthAPI.Router.info(username: username))
        }

        guard let auth = try SrpAuth(version: authInfo.version,
                                     username: username,
                                     password: loginPassword,
                                     salt: authInfo.salt,
                                     signedModulus: authInfo.modulus,
                                     serverEphemeral: authInfo.serverEphemeral) else {
            throw UpdatePasswordError.cantHashPassword
        }
        let srpClient = try auth.generateProofs(2048)

        guard let clientEphemeral = srpClient.clientEphemeral,
              let clientProof = srpClient.clientProof else {
            throw UpdatePasswordError.cantGenerateSRPClient
        }

        let updatePrivateKeyRequest = UpdatePrivateKeyRequest(
            clientEphemeral: clientEphemeral.encodeBase64(),
            clientProof: clientProof.encodeBase64(),
            SRPSession: authInfo.srpSession,
            keySalt: resultOfKeyUpdate.saltOfNewPassword.encodeBase64(),
            userlevelKeys: userInfo.isKeyV2 ? [] : resultOfKeyUpdate.updatedUserKeys,
            addressKeys: userInfo.isKeyV2 ? [] : resultOfKeyUpdate.updatedAddresses?.toKeys() ?? [],
            twoFAParams: twoFAParams,
            userKeys: resultOfKeyUpdate.updatedUserKeys,
            auth: passwordAuth,
            authCredential: currentAuth
        )

        let (_, updatePrivateKeyResponse): (URLSessionDataTask?, DefaultResponse) = try await apiService.perform(request: updatePrivateKeyRequest)

        guard updatePrivateKeyResponse.responseCode == 1000 else {
            let responseCode = updatePrivateKeyResponse.responseCode ?? 0
            let errorMessage = updatePrivateKeyResponse.error?.localizedDescription ?? "Unknown"
            PMLog.error("\(responseCode): \(errorMessage)")
            throw UpdatePasswordError.default
        }

        updateLocalKeys(authCredential: currentAuth,
                        userInfo: userInfo,
                        updatedKeyResult: resultOfKeyUpdate)
    }

    public func fetchAuthInfo() async throws -> AuthInfoResponse {
        return try await withCheckedThrowingContinuation { continuation in
            authService.info { response in
                switch response {
                case .success(let eitherResponse):
                    switch eitherResponse {
                    case .left(let authInfoResponse):
                        continuation.resume(returning: authInfoResponse)
                    case .right:
                        assertionFailure("SSO challenge response should never be returned if the intent is nil")
                        continuation.resume(throwing: AuthErrors.switchToSSOError)
                    }
                case .failure(let error):
                    continuation.resume(throwing: AuthErrors.networkingError(error))
                }
            }
        }
    }

    public func unlockPasswordWithFidoSignature(_ signature: Fido2Signature, userInfo: UserInfo,
                                                authInfo: AuthInfoResponse, loginPassword: String) async throws {
        guard let username = userInfo.userAddresses.defaultAddress()?.email else {
            PMLog.error("Attempted to change password of user without username.")
            throw UpdatePasswordError.invalidUserName
        }

        guard let auth = try SrpAuth(version: authInfo.version,
                                     username: username,
                                     password: loginPassword,
                                     salt: authInfo.salt,
                                     signedModulus: authInfo.modulus,
                                     serverEphemeral: authInfo.serverEphemeral) else {
            throw UpdatePasswordError.cantHashPassword
        }
        let srpClient = try auth.generateProofs(2048)

        guard let clientEphemeral = srpClient.clientEphemeral,
              let clientProof = srpClient.clientProof else {
            throw UpdatePasswordError.cantGenerateSRPClient
        }

        let authEndpointData = AuthEndpointData(username: username,
                                                ephemeral: clientEphemeral,
                                                proof: clientProof,
                                                srpSession: authInfo.srpSession)

        let request = UnlockPasswordEndpoint(authData: authEndpointData, signature: signature)
        try await apiService.perform(request: request)

    }

    private func generateLocalKeys(
        userInfo: UserInfo,
        oldPassword: Passphrase,
        newPassword: Passphrase
    ) throws -> PasswordChangeServiceKeyHelper.UpdatedKeyResult {
        let helper = PasswordChangeServiceKeyHelper()
        if userInfo.isKeyV2 {
            /// Key v1.2 logic
            /// v1.2. update the mailboxpassword or single-login password. We only need to update userkeys and org keys.
            return try helper.updatePasswordV2(userKeys: userInfo.userKeys,
                                               oldPassword: oldPassword,
                                               newPassword: newPassword)
        } else {
            return try helper.updatePassword(userKeys: userInfo.userKeys,
                                             addressKeys: userInfo.userAddresses,
                                             oldPassword: oldPassword,
                                             newPassword: newPassword)
        }
    }

    private func updateLocalKeys(
        authCredential: AuthCredential,
        userInfo: UserInfo,
        updatedKeyResult: PasswordChangeServiceKeyHelper.UpdatedKeyResult
    ) {
        if userInfo.isKeyV2 {
            userInfo.userKeys = updatedKeyResult.updatedUserKeys + updatedKeyResult.originalUserKeys
        } else {
            userInfo.userKeys = updatedKeyResult.updatedUserKeys + updatedKeyResult.originalUserKeys
            userInfo.userAddresses = updatedKeyResult.updatedAddresses ?? []
        }
        authCredential.update(password: updatedKeyResult.hashedNewPassword.value)
    }

    private func generatePasswordAuth(newPassword: Passphrase) async throws -> PasswordAuth? {
        let (_, authModulus): (URLSessionDataTask?, AuthModulusResponse) = try await apiService.perform(request: AuthAPI.Router.modulus)
        guard let modulusID = authModulus.modulusID else { throw UpdatePasswordError.invalidModulusID }
        guard let newModulus = authModulus.modulus else { throw UpdatePasswordError.invalidModulus }

        // generate new verifier
        guard let newSalt = try SrpRandomBits(PasswordSaltSize.login.IntBits) else {
            throw UpdatePasswordError.cantGenerateVerifier
        }

        guard let auth = try SrpAuthForVerifier(newPassword.value, newModulus, newSalt) else {
            throw UpdatePasswordError.cantHashPassword
        }

        let verifier = try auth.generateVerifier(2048)

        return PasswordAuth(modulusID: modulusID,
                            salt: newSalt.encodeBase64(),
                            verifier: verifier.encodeBase64())
    }
}

#endif
