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

import TrustKit
import ProtonCore_Services

protocol TrustKitUIDelegate: AnyObject {
    func onTrustKitValidationError(_ alert: UIAlertController)
}

// TODO:: in the future move this to core NetworkingUI
final class TrustKitWrapper {
    typealias Delegate = TrustKitUIDelegate
    typealias Configuration = [String: Any]

    static private weak var delegate: Delegate?
    static private(set) var current: TrustKit?

    private static func configuration(hardfail: Bool = true) -> Configuration {
        return [
            kTSKSwizzleNetworkDelegates: false,
            kTSKPinnedDomains: [
                "protonmail.com": [
                    kTSKEnforcePinning: hardfail,
                    kTSKIncludeSubdomains: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKReportUris: [
                        "https://api.protonmail.ch/reports/tls"
                    ],
                    kTSKPublicKeyHashes: [
                        // verify.protonmail.com and verify-api.protonmail.com certificate chain with 3 certificates
                        "drtmcR2kFkM8qJClsuWgUzxgBkePfRCkRpqUesyDmeE=", // certificate at 0
                        "jQJTbIh0grw0/1TkHSumWb+Fs0Ggogr621gT3PvPKG0=", // certificate at 1
                        "C5+lpZ7tcVwmwQIMcRtPbsQtWLABXhQzejna0wHFr8M=", // certificate at 2
                    ]
                ],
                "protonmail.ch": [
                    kTSKEnforcePinning: hardfail,
                    kTSKIncludeSubdomains: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKReportUris: [
                        "https://api.protonmail.ch/reports/tls"
                    ],
                    kTSKPublicKeyHashes: [
                        // api.protonmail.ch certificate chain with 3 certificates
                        "drtmcR2kFkM8qJClsuWgUzxgBkePfRCkRpqUesyDmeE=", // certificate at 0
                        "jQJTbIh0grw0/1TkHSumWb+Fs0Ggogr621gT3PvPKG0=", // certificate at 1
                        "C5+lpZ7tcVwmwQIMcRtPbsQtWLABXhQzejna0wHFr8M=", // certificate at 2
                    ]
                ],
                "protonvpn.com": [
                    kTSKEnforcePinning: hardfail,
                    kTSKIncludeSubdomains: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKReportUris: [
                        "https://api.protonvpn.ch/reports/tls"
                    ],
                    kTSKPublicKeyHashes: [
                        // verify.protonvpn.com and verify-api.protonvpn.com certificate chain with 3 certificates
                        "drtmcR2kFkM8qJClsuWgUzxgBkePfRCkRpqUesyDmeE=", // certificate at 0
                        "jQJTbIh0grw0/1TkHSumWb+Fs0Ggogr621gT3PvPKG0=", // certificate at 1
                        "C5+lpZ7tcVwmwQIMcRtPbsQtWLABXhQzejna0wHFr8M=", // certificate at 2
                    ]
                ],
                "protonvpn.ch": [
                    kTSKEnforcePinning: hardfail,
                    kTSKIncludeSubdomains: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKReportUris: [
                        "https://api.protonvpn.ch/reports/tls"
                    ],
                    kTSKPublicKeyHashes: [
                        // api.protonvpn.ch certificate chain with 3 certificates
                        "drtmcR2kFkM8qJClsuWgUzxgBkePfRCkRpqUesyDmeE=", // certificate at 0
                        "jQJTbIh0grw0/1TkHSumWb+Fs0Ggogr621gT3PvPKG0=", // certificate at 1
                        "C5+lpZ7tcVwmwQIMcRtPbsQtWLABXhQzejna0wHFr8M=", // certificate at 2
                    ]
                ],
                "proton.me": [
                    kTSKEnforcePinning: hardfail,
                    kTSKIncludeSubdomains: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKReportUris: [
                        "https://api.protonmail.ch/reports/tls"
                    ],
                    kTSKPublicKeyHashes: [
                        // proton.me certificate chain with 3 certificates
                        "CT56BhOTmj5ZIPgb/xD5mH8rY3BLo/MlhP7oPyJUEDo=", // certificate at 0
                        "jQJTbIh0grw0/1TkHSumWb+Fs0Ggogr621gT3PvPKG0=", // certificate at 1
                        "C5+lpZ7tcVwmwQIMcRtPbsQtWLABXhQzejna0wHFr8M=", // certificate at 2
                    ]
                ],
                ".compute.amazonaws.com": [
                    kTSKEnforcePinning: true,
                    kTSKIncludeSubdomains: true,
                    kForceSubdomains: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKReportUris: [
                        "https://api.protonmail.ch/reports/tls"
                    ],
                    kTSKPublicKeyHashes: [
                        // api.protonmail.ch and api.protonvpn.ch proxy domains certificate chain with 2 certificates:
                        // * ec2-3-69-171-208.eu-central-1.compute.amazonaws.com <- for api.protonmail.ch
                        // * ec2-3-71-31-63.eu-central-1.compute.amazonaws.com <- for api.protonmail.ch
                        // * ec2-3-69-148-87.eu-central-1.compute.amazonaws.com <- for api.protonvpn.ch
                        // * ec2-3-67-40-189.eu-central-1.compute.amazonaws.com <- for api.protonvpn.ch
                        "EU6TS9MO0L/GsDHvVc9D5fChYLNy5JdGYpJw0ccgetM=", // certificate at 0
                        "/THbIkleufSkENbNpLOhTcWGEJOsO/vnen5EyyYkpr4=", // certificate at 1
                    ]
                ]
            ]
        ]
    }

    static func start(delegate: Delegate?, customConfiguration: Configuration? = nil) {

        let config = customConfiguration ?? self.configuration()

        let instance: TrustKit = {
            #if !APP_EXTENSION
            return TrustKit(configuration: config)
            #else
            return TrustKit(configuration: config, sharedContainerIdentifier: Constants.App.APP_GROUP)
            #endif
        }()

        instance.pinningValidatorCallback = { validatorResult, hostName, policy in
            if validatorResult.evaluationResult != .success,
                validatorResult.finalTrustDecision != .shouldAllowConnection {
                if hostName.contains(check: ".compute.amazonaws.com") {
                    let alert = UIAlertController(title: LocalString._cert_validation_failed_title, message: LocalString._cert_validation_hardfailed_message, preferredStyle: .alert)
                    alert.addAction(.init(title: LocalString._general_cancel_button, style: .cancel, handler: { _ in /* nothing */ }))
                    self.delegate?.onTrustKitValidationError(alert)
                } else {
                    let alert = UIAlertController(title: LocalString._cert_validation_failed_title, message: LocalString._cert_validation_failed_message, preferredStyle: .alert)
                    alert.addAction(.init(title: LocalString._cert_validation_failed_continue, style: .destructive, handler: { _ in
                        self.start(delegate: delegate, customConfiguration: self.configuration(hardfail: false))
                    }))
                    alert.addAction(.init(title: LocalString._general_cancel_button, style: .cancel, handler: { _ in /* nothing */ }))
                    self.delegate?.onTrustKitValidationError(alert)
                }
            }
        }

        self.delegate = delegate
        self.current = instance
        PMAPIService.trustKit = instance
    }
}
