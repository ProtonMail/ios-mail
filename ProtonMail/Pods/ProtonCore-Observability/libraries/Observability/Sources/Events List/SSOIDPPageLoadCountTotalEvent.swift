//
//  SSOIDPPageLoadCountTotalEvent.swift
//  ProtonCore-Observability - Created on 16.12.22.
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

import ProtonCoreNetworking
import ProtonCoreUtilities

public struct SSPIDPPageLoadLabels: Encodable, Equatable {
    let status: HTTPResponseCodeStatus

    enum CodingKeys: String, CodingKey {
        case status
    }
}

extension ObservabilityEvent where Payload == PayloadWithLabels<SSPIDPPageLoadLabels> {
    public static func ssoIDPPageLoadCountTotal(status: HTTPResponseCodeStatus) -> Self {
        .init(name: "ios_core_login_ssoIdentityProvider_pageLoad_total", labels: .init(status: status))
    }
    
    public static func ssoIDPPageLoadCountTotal(error: ResponseError) -> Self {
        let name = "ios_core_login_ssoIdentityProvider_pageLoad_total"
        if let httpCode = error.httpCode {
            switch httpCode {
            case 400...499:
                return .init(name: name, labels: .init(status: .http4xx))
            case 500...599:
                return .init(name: name, labels: .init(status: .http5xx))
            default:
                break
            }
        }
        
        return .init(name: name, labels: .init(status: .unknown))
    }
}

// it doesn't matter that payload is PayloadWithLabels<SSPIDPPageLoadLabels>, it just have to be something
extension ObservabilityEvent where Payload == PayloadWithLabels<SSPIDPPageLoadLabels> {
    public static func ssoWebPageLoadCountTotal(
        responseStatusCode: Int, isProtonPage: Bool
    ) -> Either<ObservabilityEvent<PayloadWithLabels<SSOProtonPageLoadLabels>>,
                ObservabilityEvent<PayloadWithLabels<SSPIDPPageLoadLabels>>>? {
        switch responseStatusCode {
        case 200...299:
            if isProtonPage {
                return .left(.ssoProtonPageLoadCountTotal(status: .http2xx))
            } else {
                return .right(.ssoIDPPageLoadCountTotal(status: .http2xx))
            }
        case 400...499:
            if isProtonPage {
                return .left(.ssoProtonPageLoadCountTotal(status: .http4xx))
            } else {
                return .right(.ssoIDPPageLoadCountTotal(status: .http4xx))
            }
        case 500...599:
            if isProtonPage {
                return .left(.ssoProtonPageLoadCountTotal(status: .http5xx))
            } else {
                return .right(.ssoIDPPageLoadCountTotal(status: .http5xx))
            }
        default:
            return nil
        }
    }
}
