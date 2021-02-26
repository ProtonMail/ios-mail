//
//  TrustKitConfiguration.swift
//  ProtonMail - Created on 26/08/2019.
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


import TrustKit
import PMCommon

protocol TrustKitUIDelegate: class {
    func onTrustKitValidationError(_ alert: UIAlertController)
}

//TODO:: in the future move this to core NetworkingUI
final class TrustKitWrapper {
    typealias Delegate = TrustKitUIDelegate
    typealias Configuration = [String: Any]
    
    static private weak var delegate: Delegate?
    
    private static func configuration(hardfail: Bool = true) -> Configuration {
        return [
            kTSKSwizzleNetworkDelegates: false,
            kTSKPinnedDomains: [
                "protonmail.com": [
                    kTSKEnforcePinning : hardfail,
                    kTSKIncludeSubdomains : true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKReportUris: [
                        "https://api.protonmail.ch/reports/tls"
                    ],
                    kTSKPublicKeyHashes: [
                        "+0dMG0qG2Ga+dNE8uktwMm7dv6RFEXwBoBjQ43GqsQ0=",
                        "8joiNBdqaYiQpKskgtkJsqRxF7zN0C0aqfi8DacknnI=",
                        "JMI8yrbc6jB1FYGyyWRLFTmDNgIszrNEMGlgy972e7w=",
                        "Iu44zU84EOCZ9vx/vz67/MRVrxF1IO4i4NIa8ETwiIY="
                    ]
                ],
                "protonmail.ch": [
                    kTSKEnforcePinning : hardfail,
                    kTSKIncludeSubdomains : true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKReportUris: [
                        "https://api.protonmail.ch/reports/tls"
                    ],
                    kTSKPublicKeyHashes: [
                        "+0dMG0qG2Ga+dNE8uktwMm7dv6RFEXwBoBjQ43GqsQ0=",
                        "drtmcR2kFkM8qJClsuWgUzxgBkePfRCkRpqUesyDmeE=",
                        "YRGlaY0jyJ4Jw2/4M8FIftwbDIQfh8Sdro96CeEel54=",
                        "AfMENBVvOS8MnISprtvyPsjKlPooqh8nMB/pvCrpJpw="
                    ]
                ],
                ".compute.amazonaws.com": [
                    kTSKEnforcePinning : true,
                    kTSKIncludeSubdomains : true,
                    kForceSubdomains : true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKReportUris: [
                        "https://api.protonmail.ch/reports/tls"
                    ],
                    kTSKPublicKeyHashes: [
                        "EU6TS9MO0L/GsDHvVc9D5fChYLNy5JdGYpJw0ccgetM=",
                        "iKPIHPnDNqdkvOnTClQ8zQAIKG0XavaPkcEo0LBAABA=",
                        "MSlVrBCdL0hKyczvgYVSRNm88RicyY04Q2y5qrBt0xA=",
                        "C2UxW0T1Ckl9s+8cXfjXxlEqwAfPM4HiW2y3UdtBeCw="
                    ]
                ],
            ]
        ]
    }
    
    static func start(delegate: Delegate, customConfiguration: Configuration? = nil) {
        
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
                validatorResult.finalTrustDecision != .shouldAllowConnection
            {
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
        PMAPIService.trustKit = instance
    }
}
