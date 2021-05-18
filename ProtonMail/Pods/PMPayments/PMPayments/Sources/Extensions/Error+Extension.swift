//
//  Error+Extension.swift
//  PMPayments - Created on 1/12/20.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

extension Error {

    var isNoSubscriptionError: Bool {
        return (self as NSError).code == 22110
    }

    var isSandboxReceiptError: Bool {
        return (self as NSError).code == 22914
    }

    var isApplePaymentAlreadyRegisteredError: Bool {
        return (self as NSError).code == 22916
    }

   var isPaymentAmmountMismatchError: Bool {
        return (self as NSError).code == 22101
    }

    var isNetworkIssueError: Bool {
        let nsError = self as NSError
        switch nsError.code {
        case 3500,  // tls
             NSURLErrorTimedOut,
             NSURLErrorCannotConnectToHost,
             NSURLErrorNetworkConnectionLost,
             NSURLErrorNotConnectedToInternet,
             NSURLErrorDNSLookupFailed,
             NSURLErrorCannotFindHost,
             -1200,
             451,
             310,
             8 // No internet
             : return true
        default: return false
        }
    }
}
