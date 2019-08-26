//
//  TrustKitConfiguration.swift
//  ProtonMail - Created on 26/08/2019.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

import TrustKit

final class TrustKitConfiguration {
    static let trustKitConfig = [
        kTSKSwizzleNetworkDelegates: false,
        kTSKPinnedDomains: [
            "protonmail.com": [
                kTSKEnforcePinning : false,
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
                kTSKEnforcePinning : false,
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
            ]
        ]
    ] as [String : Any]
    
    static func start() {
        TrustKit.initSharedInstance(withConfiguration: self.trustKitConfig)
    }
}
