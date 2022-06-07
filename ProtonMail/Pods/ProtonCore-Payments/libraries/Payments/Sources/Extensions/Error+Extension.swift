//
//  Error+Extension.swift
//  ProtonCore-Payments - Created on 1/12/20.
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
import ProtonCore_Networking

extension Error {

    var isSandboxReceiptError: Bool {
        return responseCode == 22914
    }

    var isApplePaymentAlreadyRegisteredError: Bool {
        return responseCode == 22916
    }

    var isPaymentAmmountMismatchOrUnavailablePlanError: Bool {
       // 2001 "Unsupported plan selection, please select a plan that is currently available"
        return responseCode == 22101 || responseCode == 2001
    }

    var accessTokenDoesNotHaveSufficientScopeToAccessResource: Bool {
        return httpCode == 403
    }

    var isNetworkIssueError: Bool {
        guard let responseError = self as? ResponseError else { return false }
        if responseError.responseCode == 3500 { // tls
            return true
        }
        if responseError.httpCode == 451 || responseError.httpCode == 310 {
            return true
        }
        switch responseError.underlyingError?.code {
        case NSURLErrorTimedOut,
             NSURLErrorCannotConnectToHost,
             NSURLErrorNetworkConnectionLost,
             NSURLErrorNotConnectedToInternet,
             NSURLErrorDNSLookupFailed,
             NSURLErrorCannotFindHost,
             310,
             -1200,
             8 // No internet
             :
            return true
        default:
            return false
        }
    }
}
