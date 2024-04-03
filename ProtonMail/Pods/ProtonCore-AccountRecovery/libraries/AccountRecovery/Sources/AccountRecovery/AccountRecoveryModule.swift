//
//  Created on 3/7/23.
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

import ProtonCoreFeatureFlags
import ProtonCoreServices
import SwiftUI
import ProtonCoreDataModel

#if os(iOS)
public typealias AccountRecoveryViewController = UIHostingController<AccountRecoveryView>

/// Usefult parameters to have handy
public enum AccountRecoveryModule {
    /// Feature switch that governs whether Account Recovery code is active
    public static let feature = CoreFeatureFlagType.accountRecovery
    /// Resource bundle for the Account Recovery module
    public static var resourceBundle: Bundle {
        #if SWIFT_PACKAGE
        let resourceBundle = Bundle.module
        return resourceBundle
        #else
        let podBundle = Bundle(for: AccountRecoveryClass.self)
        if let bundleURL = podBundle.url(forResource: "Resources-AccountRecovery", withExtension: "bundle") {
            if let bundle = Bundle(url: bundleURL) {
                return bundle
            }
        }
        return podBundle
        #endif
    }
    /// Localized name of the settings item for Account Recovery
    public static let settingsItem = ARTranslation.settingsItem.l10n
    /// closure to obtain the Account Recovery View Controller in Settings
    /// which accepts an APIService and another closure to update the Account Recovery state with the latest fetched value
    public static let settingsViewController: (APIService, ((AccountRecovery) -> Void)?) -> AccountRecoveryViewController = { apiService, externalSetter in
        let accountRepository = AccountRecoveryRepository(apiService: apiService)
        let viewModel = AccountRecoveryView.ViewModel(accountRepository: accountRepository)
        viewModel.externalAccountRecoverySetter = externalSetter
        return UIHostingController(rootView: AccountRecoveryView(viewModel: viewModel))
    }
}
#endif

private class AccountRecoveryClass {}
