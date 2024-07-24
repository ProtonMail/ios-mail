//
//  TrustKitConfiguration.swift
//  Proton Mail - Created on 26/08/2019.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCoreEnvironment
import UIKit

protocol TrustKitUIDelegate: TrustKitDelegate {
    func onTrustKitValidationError(_ alert: UIAlertController)
}

extension TrustKitUIDelegate {
    func onTrustKitValidationError(_ error: TrustKitError) {
        let alertMessage: String
        let canContinue: Bool

        switch error {
        case .failed:
            alertMessage = LocalString._cert_validation_failed_message
            canContinue = true
        case .hardfailed:
            alertMessage = LocalString._cert_validation_hardfailed_message
            canContinue = false
        }

        let alert = UIAlertController(
            title: LocalString._cert_validation_failed_title,
            message: alertMessage,
            preferredStyle: .alert
        )

        if canContinue {
            alert.addAction(.init(title: LocalString._cert_validation_failed_continue, style: .destructive) { _ in
                TrustKitWrapper.start(delegate: self, hardfail: false)
            })
        }

        alert.addCancelAction()

        onTrustKitValidationError(alert)
    }
}
