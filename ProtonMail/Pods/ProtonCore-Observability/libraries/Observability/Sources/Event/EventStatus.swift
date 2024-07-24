//
//  EventStatus.swift
//  ProtonCore-Observability - Created on 31.01.23.
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

public enum SuccessOrFailureStatus: String, Encodable, CaseIterable {
    case successful
    case failed
}

public enum SuccessOrFailureOrCanceledStatus: String, Encodable, CaseIterable {
    case successful
    case failed
    case canceled
}

public enum AuthenticationState: String, Encodable, CaseIterable {
    case unauthenticated
    case authenticated
}

public enum HTTPResponseCodeStatus: String, Encodable, CaseIterable {
    case http2xx
    case http4xx
    case http5xx
    case unknown
}

public enum DynamicPlansHTTPResponseCodeStatus: String, Encodable, CaseIterable {
    case http2xx
    case http4xx
    case http409
    case http422
    case http5xx
    case unknown
}

public enum AcccountRecoveryCancellationHTTPResponseCodeStatus: String, Encodable, CaseIterable {
    case cancellation
    case connectionError
    case http1xx
    case http200
    case http2xx
    case http3xx
    case http400
    case http4xx
    case http5xx
    case notConnected
    case parseError
    case sslError
    case unknown
    case wrongPassword
    case tooManyRequests
}

public enum PushNotificationsHTTPResponseCodeStatus: String, Encodable, CaseIterable {
    case http1xx
    case http200
    case http2xx
    case http3xx
    case http400
    case http401
    case http403
    case http408
    case http421
    case http422
    case http4xx
    case http500
    case http503
    case http5xx
    case connectionError
    case sslError
    case unknown
}

public enum PushNotificationsPermissionsResponse: String, Encodable, CaseIterable {
    case accepted
    case rejected
}

public enum PushNotificationsReceivedResult: String, Encodable, CaseIterable {
    case handled
    case ignored
}

public enum ApplicationStatus: String, Encodable, CaseIterable {
    case active
    case inactive
}

public enum TwoFactorMode: String, Encodable, CaseIterable {
    case totp
    case webauthn
    case disabled
}

public enum PasswordChangeHTTPResponseCodeStatus: String, Encodable, CaseIterable {
    case http200
    case http2xx
    case http4xx
    case http401
    case http5xx
    case invalidCredentials
    case invalidUserName
    case invalidModulusID
    case invalidModulus
    case cantHashPassword
    case cantGenerateVerifier
    case cantGenerateSRPClient
    case keyUpdateFailed
    case unknown
}

public enum WebAuthnRequestStatus: String, Encodable, CaseIterable {
    case authorizedFIDO2
    case authorizedPasskey
    case authorizedUnsupportedType
    case authorizedMissingChallenge
    case errorCanceled
    case errorFailed
    case errorInvalidResponse
    case errorNotHandled
    case errorUnknown
    case errorNotInteractive
    case errorOther
}

public enum TwoFAType: String, Encodable, CaseIterable {
    case totp
    case webauthn
}
