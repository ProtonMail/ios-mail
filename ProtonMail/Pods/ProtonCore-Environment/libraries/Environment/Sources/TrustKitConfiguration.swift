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
import ProtonCoreDoh
import TrustKit

public typealias Configuration = [String: Any]

extension TrustKitWrapper {
    // The value of `ignoreMacUserDefinedTrustAnchors` is ignored on iOS, it's macOS-only
    // However, to make it easier to share the TrustKit configuration between iOS and macOS,
    // we expose the same API on both platforms
    public static func configuration(hardfail: Bool, ignoreMacUserDefinedTrustAnchors: Bool = false) -> Configuration {
        let propertiesForAllPlatforms: Configuration = [
            kTSKSwizzleNetworkDelegates: false,
            kTSKPinnedDomains: pinnedDomains(hardfail: hardfail)
        ]
        let platformSpecificConfiguration = platformSpecificTrustKitProperties(ignoreMacUserDefinedTrustAnchors)
        return propertiesForAllPlatforms.merging(platformSpecificConfiguration, uniquingKeysWith: { lhs, rhs in rhs })
    }

    private static func pinnedDomains(hardfail: Bool) -> [String: [String: Any]] {
        let primaryConfiguration = protonPrimary(hardfail: hardfail, publicKeyHashes: ProtonPublicKeyHashes.main)
        let verifyConfiguration = protonSecondary(hardfail: hardfail, publicKeyHashes: ProtonPublicKeyHashes.main)
        let vpnConfiguration = protonSecondary(hardfail: hardfail, publicKeyHashes: ProtonPublicKeyHashes.vpn)
        let protonMeConfiguration = protonMe(hardfail: hardfail)

        return [
            "protonmail.ch": primaryConfiguration,
            "protonvpn.ch": primaryConfiguration,
            "verify.protonmail.com": verifyConfiguration,
            "verify-api.protonmail.com": verifyConfiguration,
            "verify.protonvpn.com": verifyConfiguration,
            "verify-api.protonvpn.com": verifyConfiguration,
            "account.protonmail.com": verifyConfiguration,
            "account.protonvpn.com": vpnConfiguration,
            "protonmail.com": vpnConfiguration,
            "protonvpn.com": vpnConfiguration,
            "proton.me": protonMeConfiguration,
            ".compute.amazonaws.com": [
                kTSKEnforcePinning: true,
                kTSKIncludeSubdomains: true,
                kTSKForceSubdomainMatch: true,
                kTSKNoSSLValidation: true,
                kTSKDisableDefaultReportUri: true,
                kTSKReportUris: reportURIs,
                kTSKPublicKeyHashes: ExternalDomainPublicKeyHashes.main
            ],
            kTSKCatchallPolicy: [
                kTSKEnforcePinning: true,
                kTSKNoSSLValidation: true,
                kTSKNoHostnameValidation: true,
                kTSKAllowIPsOnly: true,
                kTSKDisableDefaultReportUri: true,
                kTSKReportUris: reportURIs,
                kTSKPublicKeyHashes: ExternalDomainPublicKeyHashes.main
            ]
        ]
    }

    private static func protonPrimary(hardfail: Bool, publicKeyHashes: [String]) -> Configuration {
        [
            kTSKEnforcePinning: hardfail,
            kTSKIncludeSubdomains: true,
            kTSKForceSubdomainMatch: true,
            kTSKNoSSLValidation: true,
            kTSKDisableDefaultReportUri: true,
            kTSKReportUris: reportURIs,
            kTSKPublicKeyHashes: publicKeyHashes
        ]
    }

    private static func protonSecondary(hardfail: Bool, publicKeyHashes: [String]) -> Configuration {
        [
            kTSKEnforcePinning: hardfail,
            kTSKIncludeSubdomains: true,
            kTSKDisableDefaultReportUri: true,
            kTSKReportUris: reportURIs,
            kTSKPublicKeyHashes: publicKeyHashes
        ]
    }

    private static func protonMe(hardfail: Bool) -> Configuration {
        [
            kTSKEnforcePinning: hardfail,
            kTSKIncludeSubdomains: true,
            kTSKForceSubdomainMatch: true,
            kTSKNoSSLValidation: true,
            kTSKDisableDefaultReportUri: true,
            kTSKReportUris: reportURIs,
            kTSKPublicKeyHashes: ProtonPublicKeyHashes.protonMe
        ]
    }

    private static let reportURIs: [String] = ["https://reports.proton.me/reports/tls"]
}

private struct ProtonPublicKeyHashes {
    let current: String
    let hotBackup: String
    let coldBackup: String

    static var main: [String] {
        let main = Self(
            current: "drtmcR2kFkM8qJClsuWgUzxgBkePfRCkRpqUesyDmeE=",
            hotBackup: "YRGlaY0jyJ4Jw2/4M8FIftwbDIQfh8Sdro96CeEel54=",
            coldBackup: "AfMENBVvOS8MnISprtvyPsjKlPooqh8nMB/pvCrpJpw="
        )

        return main.all
    }

    static var vpn: [String] {
        let vpn = Self(
            current: "8joiNBdqaYiQpKskgtkJsqRxF7zN0C0aqfi8DacknnI=",
            hotBackup: "JMI8yrbc6jB1FYGyyWRLFTmDNgIszrNEMGlgy972e7w=",
            coldBackup: "Iu44zU84EOCZ9vx/vz67/MRVrxF1IO4i4NIa8ETwiIY="
        )

        return vpn.all
    }

    static var protonMe: [String] {
        let protonMe = Self(
            current: "CT56BhOTmj5ZIPgb/xD5mH8rY3BLo/MlhP7oPyJUEDo=",
            hotBackup: "35Dx28/uzN3LeltkCBQ8RHK0tlNSa2kCpCRGNp34Gxc=",
            coldBackup: "qYIukVc63DEITct8sFT7ebIq5qsWmuscaIKeJx+5J5A="
        )

        return protonMe.all
    }

    // MARK: - Private

    private var all: [String] {
        [current, hotBackup, coldBackup]
    }
}

private struct ExternalDomainPublicKeyHashes {
    let current: String
    let firstBackup: String
    let secondBackup: String
    let thirdBackup: String

    static var main: [String] {
        let main = Self(
            current: "EU6TS9MO0L/GsDHvVc9D5fChYLNy5JdGYpJw0ccgetM=",
            firstBackup: "iKPIHPnDNqdkvOnTClQ8zQAIKG0XavaPkcEo0LBAABA=",
            secondBackup: "MSlVrBCdL0hKyczvgYVSRNm88RicyY04Q2y5qrBt0xA=",
            thirdBackup: "C2UxW0T1Ckl9s+8cXfjXxlEqwAfPM4HiW2y3UdtBeCw="
        )

        return main.all
    }

    // MARK: - Private

    private var all: [String] {
        [current, firstBackup, secondBackup, thirdBackup]
    }
}
