//
//  Created on 15/7/23.
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

import Foundation
import ProtonCoreUtilities

private class Handler {}

public enum ARTranslation: TranslationsExposing {

    public static var bundle: Bundle {
        #if SPM
        return Bundle.module
        #else
        return Bundle(path: Bundle(for: Handler.self).path(forResource: "Resources-AccountRecovery", ofType: "bundle")!)!
        #endif
    }

    #if DEBUG
    public static var prefixForMissingValue: String = "zzz"
    #else
    public static var prefixForMissingValue: String = ""
    #endif

    case settingsItem
    case expiredViewTitle
    case inactiveViewTitle
    case insecureViewTitle
    case insecureViewCancelButtonCTA
    case cancelledViewTitle
    case graceViewTitle
    case graceViewCancelButtonCTA
    case graceViewUndefinedTimeLeft
    case cancelledState
    case expiredState
    case graceState
    case insecureState

    public var l10n: String {
        switch self {
        case .settingsItem:
            return localized(key: "Settings_Item", comment: "Settings item for opening the Account Recovery screen")
        case .cancelledViewTitle:
            return localized(key: "Cancelled_View_Title", comment: "Title for cancelled state")
        case .expiredViewTitle:
            return localized(key: "Recovery process expired", comment: "Title for expired recovery process")
        case .inactiveViewTitle:
            return localized(key: "Recovery process not started", comment: "Title for no password reset in progress. This is screen is currently only shown in development, as a placeholder")
        case .insecureViewTitle:
            return localized(key: "Insecure_View_Title", comment: "Title for insecure state")
        case .insecureViewCancelButtonCTA:
            return localized(key: "Insecure_View_Cancel_Button_CTA", comment: "Button for cancelling reset during insecure state")
        case .graceViewTitle:
            return localized(key: "Grace_View_Title", comment: "Title for grace period state")
        case .graceViewCancelButtonCTA:
            return localized(key: "Grace_View_Cancel_Button_CTA", comment: "Button for cancelling reset during grace period (active) state")
        case .graceViewUndefinedTimeLeft:
            return localized(key: "Grace_View_Undefined_Time_Left", comment: "Text for undefined time left, used as fallback if it can't be calculated")
        case .cancelledState: return localized(key: "Settings_Item_Value_Cancelled", comment: "account recovery settings item value for cancelled state")
        case .expiredState: return localized(key: "Settings_Item_Value_Expired", comment: "account recovery settings item value for cancelled state")
        case .graceState: return localized(key: "Settings_Item_Value_Grace", comment: "account recovery settings item value for grace state")
        case .insecureState: return localized(key: "Settings_Item_Value_Insecure", comment: "account recovery settings item value for insecure state")
        }
    }
}
