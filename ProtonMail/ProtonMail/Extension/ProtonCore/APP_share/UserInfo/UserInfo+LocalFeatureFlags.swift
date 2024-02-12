// Copyright (c) 2021 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import ProtonCoreDataModel
import ProtonCoreFeatureFlags

extension UserInfo {
    // Highlight body without encrypted search will give a wrong impression to user that we can search body without ES
    static var isBodySearchKeywordHighlightEnabled: Bool {
        false
    }

    static var enableSelectAll: Bool {
        true
    }

    /// The app launch refactor logic is executed before any user is loaded into memory so we can't inject the dependency
    /// with the UserContainer. To overcome this, we use the `FeatureFlagsRepository` singleton without specifying
    /// any user because it will by default use the last active user if no user has been set yet in `FeatureFlagsRepository`.
    ///
    /// Also, we want the FF value to be consistent, so to avoid potentially different values when having multiple users
    /// authenticated in the app, the feature flag should be set to ON or OFF for all users at once in the Uleash dashboard.
    /// This way we guarantee that no matter the active user the request is made with, the value is the same every time during
    /// the app lifetime.
    static var isAppAccessResolverEnabled: Bool {
        if UIApplication.isDebugOrEnterprise {
            return true
        } else {
            return FeatureFlagsRepository.shared.isEnabled(MailFeatureFlag.appLaunchRefactor)
        }
    }

    static var isAutoImportContactsEnabled: Bool {
        false
    }

    static var shareImagesAsInlineByDefault: Bool {
        return true
    }

    static var isRSVPMilestoneTwoEnabled: Bool {
        UIApplication.isDebugOrEnterprise
    }
}
