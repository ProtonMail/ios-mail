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
