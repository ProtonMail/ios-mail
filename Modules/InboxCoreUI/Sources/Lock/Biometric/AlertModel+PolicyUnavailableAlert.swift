// Copyright (c) 2025 Proton Technologies AG
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

import InboxCore
import LocalAuthentication
import SwiftUI

extension AlertModel {
    static func policyUnavailableAlert(
        action: @escaping (PolicyUnavailableAlertAction) async -> Void,
        laContext: @escaping () -> LAContext
    ) -> Self {
        let message =
            switch SupportedBiometry.availableOnDevice(context: laContext()) {
            case .faceID:
                L10n.BiometricLock.BiometricsNotAvailableAlert.messageFaceID
            case .touchID:
                L10n.BiometricLock.BiometricsNotAvailableAlert.messageTouchID
            case .none:
                L10n.BiometricLock.BiometricsNotAvailableAlert.defaultMessage
            }
        let ok = AlertAction(details: PolicyUnavailableAlertAction.ok, action: { await action(.ok) })
        let signInAgain = AlertAction(details: PolicyUnavailableAlertAction.signInAgain) {
            await action(.signInAgain)
        }
        return AlertModel(
            title: L10n.BiometricLock.BiometricsNotAvailableAlert.title,
            message: message,
            actions: [signInAgain, ok]
        )
    }
}

enum PolicyUnavailableAlertAction: AlertActionInfo {
    case ok
    case signInAgain

    var info: (title: LocalizedStringResource, buttonRole: ButtonRole?) {
        switch self {
        case .ok:
            (CommonL10n.ok, .cancel)
        case .signInAgain:
            (L10n.BiometricLock.BiometricsNotAvailableAlert.signInAgainAction, .destructive)
        }
    }
}
