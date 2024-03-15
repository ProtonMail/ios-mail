//
//  Created on 14/12/23.
//
//  Copyright (c) 2023 Proton AG
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
import UIKit
import ProtonCoreDataModel
import ProtonCoreUIFoundations

extension AccountRecovery {
    public var shouldShowSettingsItem: Bool {
        if state == .none || state == .expired { return false }
        // the user cancelled manually, so they already know
        if state == .cancelled && reason == .cancelled { return false }
        // otherwise, true
        return true
    }

    public var valueForSettingsItem: String {
        switch state {
        case .none: return ""
        case .grace: return ARTranslation.graceState.l10n
        case .cancelled: return ARTranslation.cancelledState.l10n
        case .insecure: return ARTranslation.insecureState.l10n
        case .expired: return ""
        }
    }

    public var imageForSettingsItem: UIImage? {
        switch state {
        case .none, .expired: return nil
        case .grace, .cancelled: return IconProvider.exclamationCircle
        case .insecure: return IconProvider.checkmarkCircle
        }
    }
}
#endif
