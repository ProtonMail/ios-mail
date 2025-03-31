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

import Foundation
import CryptoKit
import XCTest
import Security

enum LokiPushError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
}

@available(iOS 15.0, *)
@available(macOS 12.0, *)
class LokiClient {

    init(){
        self.session = URLSession(configuration: .default, delegate: CustomSessionDelegate(), delegateQueue: nil)
    }

    public static let shared = LokiClient()

    private let session: URLSession

    internal func pushToLoki(entry: String, lokiEndpoint: String) async throws {
        var request = URLRequest(url: URL(string: lokiEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = entry.data(using: .utf8)

        do {
            let (_, response) = try await session.data(for: request, delegate: nil)
            guard response is HTTPURLResponse else { throw LokiPushError.invalidResponse }
        } catch {
            throw error
        }
    }

    // Helper function to load the PKCS#12 file with a passphrase
    private func loadIdentity() -> SecIdentity? {

        let testBundle = Bundle(for: type(of: self))
        let certFileURL = testBundle.url(forResource: MeasurementConfig.lokiCertificate, withExtension: "p12")
        let p12Data = try! Data(contentsOf: certFileURL!)

        let options: [String: Any] = [kSecImportExportPassphrase as String: MeasurementConfig.lokiCertificatePassphrase]
        var items: CFArray?

        let securityError = SecPKCS12Import(p12Data as NSData, options as NSDictionary, &items)
        if securityError == errSecSuccess {
            let array = items! as NSArray
            let dictionary = array.firstObject! as! NSDictionary
            let identity = dictionary[kSecImportItemIdentity as String] as! SecIdentity
            return identity
        } else {
            print("Error importing PKCS#12 file: \(securityError)")
            return nil
        }
    }

    class CustomSessionDelegate: NSObject, URLSessionDelegate {
        func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate {
                if let identity = LokiClient().loadIdentity() {
                    let credential = URLCredential(identity: identity, certificates: nil, persistence: .forSession)
                    completionHandler(.useCredential, credential)
                } else {
                    completionHandler(.cancelAuthenticationChallenge, nil)
                }
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        }
    }
}

