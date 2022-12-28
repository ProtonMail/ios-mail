//
//  TrustKitConfiguration.swift
//  ProtonCore-Doh - Created on 24/03/22.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCore_Doh
import TrustKit

public typealias Configuration = [String: Any]

extension TrustKitWrapper {
    static public func configuration(hardfail: Bool) -> Configuration {
        [
            kTSKSwizzleNetworkDelegates: false,
            kTSKPinnedDomains: [
                "protonmail.ch": [
                    kTSKEnforcePinning: hardfail,
                    kTSKIncludeSubdomains: true,
                    kTSKForceSubdomainMatch: true,
                    kTSKNoSSLValidation: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKReportUris: [
                        "https://api.protonmail.ch/reports/tls"
                    ],
                    kTSKPublicKeyHashes: [
                        // api.protonmail.ch certificate
                        "drtmcR2kFkM8qJClsuWgUzxgBkePfRCkRpqUesyDmeE=", // Current
                        "YRGlaY0jyJ4Jw2/4M8FIftwbDIQfh8Sdro96CeEel54=", // Hot backup
                        "AfMENBVvOS8MnISprtvyPsjKlPooqh8nMB/pvCrpJpw=", // Cold backup
                    ]
                ],
                "protonvpn.ch": [
                    kTSKEnforcePinning: hardfail,
                    kTSKIncludeSubdomains: true,
                    kTSKForceSubdomainMatch: true,
                    kTSKNoSSLValidation: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKReportUris: [
                        "https://api.protonvpn.ch/reports/tls"
                    ],
                    kTSKPublicKeyHashes: [
                        // api.protonvpn.ch certificate
                        "drtmcR2kFkM8qJClsuWgUzxgBkePfRCkRpqUesyDmeE=", // Current
                        "YRGlaY0jyJ4Jw2/4M8FIftwbDIQfh8Sdro96CeEel54=", // Hot backup
                        "AfMENBVvOS8MnISprtvyPsjKlPooqh8nMB/pvCrpJpw=", // Cold backup
                    ]
                ],
                "verify.protonmail.com": [
                    kTSKEnforcePinning: hardfail,
                    kTSKIncludeSubdomains: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKReportUris: [
                        "https://api.protonvpn.ch/reports/tls"
                    ],
                    kTSKPublicKeyHashes: [
                        // api.protonvpn.ch certificate
                        "drtmcR2kFkM8qJClsuWgUzxgBkePfRCkRpqUesyDmeE=", // Current
                        "YRGlaY0jyJ4Jw2/4M8FIftwbDIQfh8Sdro96CeEel54=", // Hot backup
                        "AfMENBVvOS8MnISprtvyPsjKlPooqh8nMB/pvCrpJpw=", // Cold backup
                    ]
                ],
                "verify-api.protonmail.com": [
                    kTSKEnforcePinning: hardfail,
                    kTSKIncludeSubdomains: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKReportUris: [
                        "https://api.protonvpn.ch/reports/tls"
                    ],
                    kTSKPublicKeyHashes: [
                        // api.protonvpn.ch certificate
                        "drtmcR2kFkM8qJClsuWgUzxgBkePfRCkRpqUesyDmeE=", // Current
                        "YRGlaY0jyJ4Jw2/4M8FIftwbDIQfh8Sdro96CeEel54=", // Hot backup
                        "AfMENBVvOS8MnISprtvyPsjKlPooqh8nMB/pvCrpJpw=", // Cold backup
                    ]
                ],
                "verify.protonvpn.com": [
                    kTSKEnforcePinning: hardfail,
                    kTSKIncludeSubdomains: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKReportUris: [
                        "https://api.protonvpn.ch/reports/tls"
                    ],
                    kTSKPublicKeyHashes: [
                        // api.protonvpn.ch certificate
                        "drtmcR2kFkM8qJClsuWgUzxgBkePfRCkRpqUesyDmeE=", // Current
                        "YRGlaY0jyJ4Jw2/4M8FIftwbDIQfh8Sdro96CeEel54=", // Hot backup
                        "AfMENBVvOS8MnISprtvyPsjKlPooqh8nMB/pvCrpJpw=", // Cold backup
                    ]
                ],
                "verify-api.protonvpn.com": [
                    kTSKEnforcePinning: hardfail,
                    kTSKIncludeSubdomains: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKReportUris: [
                        "https://api.protonvpn.ch/reports/tls"
                    ],
                    kTSKPublicKeyHashes: [
                        // api.protonvpn.ch certificate
                        "drtmcR2kFkM8qJClsuWgUzxgBkePfRCkRpqUesyDmeE=", // Current
                        "YRGlaY0jyJ4Jw2/4M8FIftwbDIQfh8Sdro96CeEel54=", // Hot backup
                        "AfMENBVvOS8MnISprtvyPsjKlPooqh8nMB/pvCrpJpw=", // Cold backup
                    ]
                ],
                "account.protonmail.com": [
                    kTSKEnforcePinning: hardfail,
                    kTSKIncludeSubdomains: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKReportUris: [
                        "https://api.protonvpn.ch/reports/tls"
                    ],
                    kTSKPublicKeyHashes: [
                        // api.protonvpn.ch certificate
                        "drtmcR2kFkM8qJClsuWgUzxgBkePfRCkRpqUesyDmeE=", // Current
                        "YRGlaY0jyJ4Jw2/4M8FIftwbDIQfh8Sdro96CeEel54=", // Hot backup
                        "AfMENBVvOS8MnISprtvyPsjKlPooqh8nMB/pvCrpJpw=", // Cold backup
                    ]
                ],
                "account.protonvpn.com": [
                    kTSKEnforcePinning: hardfail,
                    kTSKIncludeSubdomains: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKReportUris: [
                        "https://api.protonvpn.ch/reports/tls"
                    ],
                    kTSKPublicKeyHashes: [
                        // verify.protonvpn.com and verify-api.protonvpn.com
                        "8joiNBdqaYiQpKskgtkJsqRxF7zN0C0aqfi8DacknnI=", // Current
                        "JMI8yrbc6jB1FYGyyWRLFTmDNgIszrNEMGlgy972e7w=", // Hot backup
                        "Iu44zU84EOCZ9vx/vz67/MRVrxF1IO4i4NIa8ETwiIY=", // Cold backup
                    ]
                ],
                "protonmail.com": [
                    kTSKEnforcePinning: hardfail,
                    kTSKIncludeSubdomains: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKReportUris: [
                        "https://api.protonmail.ch/reports/tls"
                    ],
                    kTSKPublicKeyHashes: [
                        // verify.protonmail.com and verify-api.protonmail.com certificate
                        "8joiNBdqaYiQpKskgtkJsqRxF7zN0C0aqfi8DacknnI=", // Current
                        "JMI8yrbc6jB1FYGyyWRLFTmDNgIszrNEMGlgy972e7w=", // Hot backup
                        "Iu44zU84EOCZ9vx/vz67/MRVrxF1IO4i4NIa8ETwiIY=", // Cold backup
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
                        // verify.protonvpn.com and verify-api.protonvpn.com
                        "8joiNBdqaYiQpKskgtkJsqRxF7zN0C0aqfi8DacknnI=", // Current
                        "JMI8yrbc6jB1FYGyyWRLFTmDNgIszrNEMGlgy972e7w=", // Hot backup
                        "Iu44zU84EOCZ9vx/vz67/MRVrxF1IO4i4NIa8ETwiIY=", // Cold backup
                    ]
                ],
                "proton.me": [
                    kTSKEnforcePinning: hardfail,
                    kTSKIncludeSubdomains: true,
                    kTSKForceSubdomainMatch: true,
                    kTSKNoSSLValidation: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKReportUris: [
                        "https://api.protonmail.ch/reports/tls"
                    ],
                    kTSKPublicKeyHashes: [
                        // proton.me certificate
                        "CT56BhOTmj5ZIPgb/xD5mH8rY3BLo/MlhP7oPyJUEDo=", // Current
                        "35Dx28/uzN3LeltkCBQ8RHK0tlNSa2kCpCRGNp34Gxc=", // Hot backup
                        "qYIukVc63DEITct8sFT7ebIq5qsWmuscaIKeJx+5J5A=", // Cold backup
                    ]
                ],
                ".compute.amazonaws.com": [
                    kTSKEnforcePinning: true,
                    kTSKIncludeSubdomains: true,
                    kTSKForceSubdomainMatch: true,
                    kTSKNoSSLValidation: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKReportUris: [
                        "https://api.protonmail.ch/reports/tls"
                    ],
                    kTSKPublicKeyHashes: [
                        // api.protonmail.ch and api.protonvpn.ch proxy domains certificates
                        "EU6TS9MO0L/GsDHvVc9D5fChYLNy5JdGYpJw0ccgetM=", // Current
                        "iKPIHPnDNqdkvOnTClQ8zQAIKG0XavaPkcEo0LBAABA=", // Backup 1
                        "MSlVrBCdL0hKyczvgYVSRNm88RicyY04Q2y5qrBt0xA=", // Backup 2
                        "C2UxW0T1Ckl9s+8cXfjXxlEqwAfPM4HiW2y3UdtBeCw=", // Backup 3
                    ]
                ],
                kTSKCatchallPolicy: [
                    kTSKEnforcePinning: true,
                    kTSKNoSSLValidation: true,
                    kTSKNoHostnameValidation: true,
                    kTSKAllowIPsOnly: true,
                    kTSKDisableDefaultReportUri: true,
                    kTSKReportUris: [
                        "https://api.protonmail.ch/reports/tls"
                    ],
                    kTSKPublicKeyHashes: [
                        // api.protonmail.ch and api.protonvpn.ch proxy domains certificates
                        "EU6TS9MO0L/GsDHvVc9D5fChYLNy5JdGYpJw0ccgetM=", // Current
                        "iKPIHPnDNqdkvOnTClQ8zQAIKG0XavaPkcEo0LBAABA=", // Backup 1
                        "MSlVrBCdL0hKyczvgYVSRNm88RicyY04Q2y5qrBt0xA=", // Backup 2
                        "C2UxW0T1Ckl9s+8cXfjXxlEqwAfPM4HiW2y3UdtBeCw=", // Backup 3
                    ]
                ],
            ]
        ]
    }
}
