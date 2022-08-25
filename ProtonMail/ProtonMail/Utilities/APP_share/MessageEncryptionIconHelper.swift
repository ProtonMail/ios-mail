// Copyright (c) 2022 Proton AG
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
import ProtonCore_UIFoundations
import UIKit

struct VerificationResult {
    /// If the sender is in the list of contacts, whether its contact signature has been verified
    let senderVerified: Bool
    let signatureVerificationResult: SignatureVerificationResult
}

// swiftlint:disable type_body_length
struct MessageEncryptionIconHelper {
    enum ContentEncryptionType: String, Equatable {
        case none
        case pgpInline = "pgp-inline"
        case pgpInlinePinned = "pgp-inline-pinned"
        case pgpMIME = "pgp-mime"
        case pgpMIMEPinned = "pgp-mime-pinned"
        case pgpPM = "pgp-pm"
        case pgpPMPinned = "pgp-pm-pinned"
        case pgpEO = "pgp-eo"
        case `internal` = "internal"
        /// Email encrypted by user
        case endToEnd = "end-to-end"
        /// Email is sent unencrypted, but encrypted by the server to store it
        case onCompose = "on-compose"
        /// Email encrypted by Proton e.g. Auto-reply
        case onDelivery = "on-delivery"

        static let internalTypes: [Self] = [.pgpPM, .pgpPMPinned, pgpEO]
        static let pinnedTypes: [Self] = [.pgpPMPinned, .pgpMIMEPinned, .pgpInlinePinned]
    }

    // swiftlint:disable function_body_length
    func sentStatusIconInfo(message: MessageEntity) -> EncryptionIconStatus? {
        guard !message.parsedHeaders.isEmpty else {
            return nil
        }

        let mapEncryption = getEncryptionMap(headerValue: message.parsedHeaders)
        let contentEncryptionType = getContentEncryption(headerValue: message.parsedHeaders)

        let encryptions = mapEncryption.compactMap { ContentEncryptionType(rawValue: $0.value) }
        let hasHeaderInfo = !encryptions.isEmpty

        let allPinned = hasHeaderInfo &&
            !encryptions.contains(where: { !ContentEncryptionType.pinnedTypes.contains($0) })
        let allEncrypted = hasHeaderInfo && !encryptions.contains(where: { $0 == .none })
        let allExternal = hasHeaderInfo && !encryptions
            .contains(where: { ContentEncryptionType.internalTypes.contains($0) })
        let isImported = getOrigin(headerValue: message.parsedHeaders) == "import"

        if allPinned {
            if contentEncryptionType == .endToEnd {
                if allExternal {
                    return .init(
                        iconColor: .blue,
                        icon: IconProvider.lockCheckFilled,
                        text: LocalString._end_to_send_verified_recipient_of_sent
                    )
                } else {
                    return .init(
                        iconColor: .blue,
                        icon: IconProvider.lockCheckFilled,
                        text: LocalString._end_to_send_verified_recipient_of_sent
                    )
                }
            } else {
                if allExternal {
                    return .init(
                        iconColor: .blue,
                        icon: IconProvider.lockCheckFilled,
                        text: LocalString._zero_access_verified_recipient_of_sent
                    )
                } else {
                    return .init(
                        iconColor: .blue,
                        icon: IconProvider.lockCheckFilled,
                        text: LocalString._zero_access_verified_recipient_of_sent
                    )
                }
            }
        }
        if allEncrypted {
            if contentEncryptionType == .endToEnd {
                if allExternal {
                    return .init(
                        iconColor: .green,
                        icon: IconProvider.lockFilled,
                        text: LocalString._end_to_end_encryption_of_sent
                    )
                } else {
                    return .init(
                        iconColor: .blue,
                        icon: IconProvider.lockFilled,
                        text: LocalString._end_to_end_encryption_of_sent
                    )
                }
            } else {
                if allExternal {
                    return .init(
                        iconColor: .blue,
                        icon: IconProvider.lockFilled,
                        text: LocalString._zero_access_by_pm_of_sent
                    )
                } else {
                    return .init(
                        iconColor: .blue,
                        icon: IconProvider.lockFilled,
                        text: LocalString._zero_access_by_pm_of_sent
                    )
                }
            }
        }

        if isImported {
            return .init(
                iconColor: .black,
                icon: IconProvider.lockFilled,
                text: LocalString._zero_access_of_msg
            )
        } else {
            return .init(
                iconColor: .black,
                icon: IconProvider.lockFilled,
                text: LocalString._zero_access_of_msg
            )
        }
    }

    // swiftlint:disable function_body_length
    func receivedStatusIconInfo(_ message: MessageEntity,
                                verifyResult: VerificationResult) -> EncryptionIconStatus? {
        let isInternal = getOrigin(headerValue: message.parsedHeaders) == "internal"
        let encryption = getContentEncryption(headerValue: message.parsedHeaders)

        if isInternal {
            if encryption == .endToEnd {
                switch verifyResult.signatureVerificationResult {
                case .success:
                    return .init(
                        iconColor: .blue,
                        icon: IconProvider.lockCheckFilled,
                        text: LocalString._end_to_end_encryption_verified_of_received
                    )
                case .messageNotSigned:
                    return .init(
                        iconColor: .blue,
                        icon: IconProvider.lockExclamationFilled,
                        text: LocalString._end_to_end_encrypted_message
                    )
                case .signatureVerificationSkipped:
                    return .init(
                        iconColor: .blue,
                        icon: IconProvider.lockFilled,
                        text: LocalString._end_to_end_encryption_signed_of_received
                    )
                case .failure:
                    return .init(
                        iconColor: .blue,
                        icon: IconProvider.lockExclamationFilled,
                        text: LocalString._sender_verification_failed
                    )
                }
            }
            if encryption == .onDelivery {
                return .init(
                    iconColor: .blue,
                    icon: IconProvider.lockFilled,
                    text: LocalString._zero_access_by_pm_of_sent
                )
            }
            return .init(
                iconColor: .blue,
                icon: IconProvider.lockFilled,
                text: LocalString._end_to_end_encrypted_message
            )
        } else {
            if encryption == .endToEnd {
                switch verifyResult.signatureVerificationResult {
                case .success:
                    if verifyResult.senderVerified {
                        return .init(
                            iconColor: .green,
                            icon: IconProvider.lockCheckFilled,
                            text: LocalString._pgp_encrypted_verified_of_received
                        )
                    } else {
                        return .init(
                            iconColor: .green,
                            icon: IconProvider.lockPenFilled,
                            text: LocalString._pgp_encrypted_signed_of_received
                        )
                    }
                case .messageNotSigned:
                    return .init(
                        iconColor: .green,
                        icon: IconProvider.lockFilled,
                        text: LocalString._pgp_encrypted_of_received
                    )
                case .signatureVerificationSkipped:
                    return .init(
                        iconColor: .green,
                        icon: IconProvider.lockPenFilled,
                        text: LocalString._pgp_encrypted_signed_of_received
                    )
                case .failure:
                    return .init(
                        iconColor: .green,
                        icon: IconProvider.lockExclamationFilled,
                        text: LocalString._sender_verification_failed
                    )
                }
            }
            if encryption == .onDelivery {
                switch verifyResult.signatureVerificationResult {
                case .success:
                    if verifyResult.senderVerified {
                        return .init(
                            iconColor: .green,
                            icon: IconProvider.lockOpenCheckFilled,
                            text: LocalString._pgp_signed_verified_of_received
                        )
                    } else {
                        return .init(
                            iconColor: .green,
                            icon: IconProvider.lockOpenPenFilled,
                            text: LocalString._pgp_encrypted_signed_of_received
                        )
                    }
                case .messageNotSigned:
                    return .init(
                        iconColor: .black,
                        icon: IconProvider.lockFilled,
                        text: LocalString._zero_access_of_msg
                    )
                case .signatureVerificationSkipped:
                    return .init(
                        iconColor: .black,
                        icon: IconProvider.lockFilled,
                        text: LocalString._zero_access_of_msg
                    )
                case .failure:
                    return .init(
                        iconColor: .green,
                        icon: IconProvider.lockOpenExclamationFilled,
                        text: LocalString._pgp_signed_verification_failed_of_received
                    )
                }
            }
            return .init(
                iconColor: .black,
                icon: IconProvider.lockFilled,
                text: LocalString._zero_access_of_msg
            )
        }
    }

    func sendStatusIconInfo(email: String, sendPreferences: SendPreferences) -> EncryptionIconStatus? {
        if let error = sendPreferences.error {
            return .init(iconColor: .error,
                         icon: IconProvider.lockExclamationFilled,
                         text: error.message)
        }
        if sendPreferences.pgpScheme == .proton {
            if sendPreferences.isPublicKeyPinned {
                return .init(iconColor: .blue,
                             icon: IconProvider.lockCheckFilled,
                             text: LocalString._end_to_end_encrypted_to_verified_recipient,
                             isPGPPinned: false,
                             isNonePM: false)

            } else {
                return .init(iconColor: .blue,
                             icon: IconProvider.lockFilled,
                             text: LocalString._end_to_end_encrypted_of_recipient,
                             isPGPPinned: false,
                             isNonePM: false)
            }
        }
        if sendPreferences.pgpScheme == .encryptOutside {
            return .init(iconColor: .blue,
                         icon: IconProvider.lockFilled,
                         text: LocalString._end_to_end_encrypted_of_recipient,
                         isPGPPinned: false,
                         isNonePM: true)
        }

        if [PGPScheme.pgpInline, PGPScheme.pgpMIME]
            .contains(sendPreferences.pgpScheme) {
            if sendPreferences.encrypt {
                if sendPreferences.isPublicKeyPinned {
                    if sendPreferences.hasApiKeys {
                        return
                            .init(iconColor: .green,
                                  icon: IconProvider.lockCheckFilled,
                                  text: LocalString._end_to_end_encrypted_to_verified_recipient,
                                  isPGPPinned: true,
                                  isNonePM: false)

                    } else {
                        return
                            .init(iconColor: .green,
                                  icon: IconProvider.lockCheckFilled,
                                  text: LocalString._pgp_encrypted_to_verified_recipient,
                                  isPGPPinned: true,
                                  isNonePM: false)
                    }
                } else if sendPreferences.hasApiKeys {
                    return
                        .init(iconColor: .green,
                              icon: IconProvider.lockFilled,
                              text: LocalString._end_to_end_encrypted_of_recipient,
                              isPGPPinned: true,
                              isNonePM: false)
                } else {
                    return
                        .init(iconColor: .green,
                              icon: IconProvider.lockPenFilled,
                              text: LocalString._pgp_encrypted_to_recipient,
                              isPGPPinned: true,
                              isNonePM: false)
                }
            } else {
                return
                    .init(iconColor: .green,
                          icon: IconProvider.lockOpenPenFilled,
                          text: LocalString._pgp_signed_to_recipient,
                          isPGPPinned: false,
                          isNonePM: true)
            }
        }
        return nil
    }
}

extension MessageEncryptionIconHelper {
    func getAuthenticationMap(headerValue: [String: Any]) -> [String: String] {
        return getHeaderMap(headerValue: headerValue, headerKey: MessageHeaderKey.pmRecipientAuthentication)
    }

    func getEncryptionMap(headerValue: [String: Any]) -> [String: String] {
        return getHeaderMap(headerValue: headerValue, headerKey: MessageHeaderKey.pmRecipientEncryption)
    }

    func getOrigin(headerValue: [String: Any]) -> String? {
        return getHeaderValue(headerValue: headerValue, headerKey: MessageHeaderKey.pmOrigin)
    }

    func getContentEncryption(headerValue: [String: Any]) -> ContentEncryptionType {
        guard let value = getHeaderValue(headerValue: headerValue,
                                         headerKey: MessageHeaderKey.pmContentEncryption)
        else {
            return .none
        }
        return ContentEncryptionType(rawValue: value) ?? .none
    }

    func getHeaderMap(headerValue: [String: Any], headerKey: String) -> [String: String] {
        guard let rawValue = headerValue[headerKey] as? String,
              let normalBody = rawValue.removingPercentEncoding else { return [:] }
        // key1=value1;key2=value2
        var result: [String: String] = [:]
        let components = normalBody.components(separatedBy: ";")
        for component in components {
            // key1=value1
            let pieces = component.components(separatedBy: "=")
            guard pieces.count == 2,
                  let key = pieces.first,
                  let data = pieces.last else { continue }
            result[key] = data
        }
        return result
    }

    func getHeaderValue(headerValue: [String: Any], headerKey: String) -> String? {
        guard let rawValue = headerValue[headerKey] as? String else {
            return nil
        }
        return rawValue
    }
}
