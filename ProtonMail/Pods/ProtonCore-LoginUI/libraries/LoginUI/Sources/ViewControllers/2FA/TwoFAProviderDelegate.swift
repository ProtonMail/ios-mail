//
//  Created on 23/5/24.
//
//  Copyright (c) 2024 Proton AG
//
//  ProtonVPN is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonVPN is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonVPN.  If not, see <https://www.gnu.org/licenses/>.

#if os(iOS)

import Foundation
import ProtonCoreAuthentication
import ProtonCoreLogin

/// Protocol conformed to by the invoker of the 2FA UI
public protocol TwoFAProviderDelegate: AnyObject, NavigationDelegate {
    /// notifies the delegate about the obtained 1-time code. After verification, if it was wrong, an error is thrown.
    /// Depending on the error type, the 2FA View is expected to allow the user to retry, or to cancel completely
    func providerDidObtain(factor: String) async throws
    /// notifies the delegate about the obtained FIDO2 signature. After verification, if it was wrong, an error is thrown.
    /// Depending on the error type, the 2FA View is expected to allow the user to retry, or to cancel completely
    func providerDidObtain(factor: Fido2Signature) async throws

}

#endif
