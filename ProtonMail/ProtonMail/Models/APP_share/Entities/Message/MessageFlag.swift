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

struct MessageFlag: OptionSet, Equatable, Hashable {
    let rawValue: Int

    /// whether a message is received
    ///
    /// const FLAG_RECEIVED = 1;
    ///
    /// this it TYPE:INBOXS
    static let received = MessageFlag(rawValue: 1 << 0 )
    /// whether a message is sent
    ///
    /// const FLAG_SENT = 2;
    ///
    /// this is TYPE:SENT
    static let sent = MessageFlag(rawValue: 1 << 1 )
    /// whether the message is between ProtonMail recipients
    ///
    /// const FLAG_INTERNAL = 4;
    static let `internal` = MessageFlag(rawValue: 1 << 2 )
    /// whether the message is end-to-end encrypted
    ///
    /// const FLAG_E2E = 8;
    static let e2e = MessageFlag(rawValue: 1 << 3 )
    /// whether the message is an auto response
    ///
    /// const FLAG_AUTO = 16;
    static let auto = MessageFlag(rawValue: 1 << 4 )
    /// whether the message is replied to
    ///
    /// const FLAG_REPLIED = 32;
    static let replied = MessageFlag(rawValue: 1 << 5 )
    /// whether the message is replied all to
    ///
    /// const FLAG_REPLIEDALL = 64;
    static let repliedAll = MessageFlag(rawValue: 1 << 6 )
    /// whether the message is forwarded
    ///
    /// const FLAG_FORWARDED = 128;
    static let forwarded = MessageFlag(rawValue: 1 << 7 )
    /// whether the message has been responded to with an auto response
    ///
    /// const FLAG_AUTOREPLIED = 256;
    static let autoReplied = MessageFlag(rawValue: 1 << 8 )
    /// whether the message is an import
    ///
    /// const FLAG_IMPORTED = 512;
    static let imported = MessageFlag(rawValue: 1 << 9 )
    /// whether the message has ever been opened by the user
    ///
    /// const FLAG_OPENED = 1024;
    static let opened = MessageFlag(rawValue: 1 << 10)
    /// whether a read receipt has been sent in response to the message
    ///
    /// const FLAG_RECEIPT_SENT = 2048;
    static let receiptSent = MessageFlag(rawValue: 1 << 11)
    static let notified = MessageFlag(rawValue: 1 << 12)
    static let touched = MessageFlag(rawValue: 1 << 13)
    static let receipt = MessageFlag(rawValue: 1 << 14)
    static let proton = MessageFlag(rawValue: 1 << 15)
    /// whether to request a read receipt for the message
    ///
    /// const RECEIPT_REQUEST = 65536
    static let receiptRequest = MessageFlag(rawValue: 1 << 16)
    /// whether to attach the public key
    ///
    /// const PUBLIC_KEY = 131072
    static let publicKey = MessageFlag(rawValue: 1 << 17)
    /// whether to sign the message
    ///
    /// const FLAG_SIGN = 262144
    static let sign = MessageFlag(rawValue: 1 << 18)

    /// const FLAG_UNSUBSCRIBED = 524288
    static let unsubscribed = MessageFlag(rawValue: 1 << 19)

    static let scheduledSend = MessageFlag(rawValue: 1 << 20)

    static let spfFail = MessageFlag(rawValue: 1 << 24)
    static let dkimFail = MessageFlag(rawValue: 1 << 25)

    /// Incoming mail failed DMARC authentication.
    ///
    /// const FLAG_DMARC_FAILED = 67_108_864
    static let dmarcFailed = MessageFlag(rawValue: 1 << 26)

    /// The message is in spam and the user moves it to a new location that is not spam or trash
    /// (e.g. inbox or archive).
    ///
    /// const FLAG_HAM_MANUAL = 134_217_728
    static let hamManual = MessageFlag(rawValue: 1 << 27)

    static let spamAuto = MessageFlag(rawValue: 1 << 28)
    static let spamManual = MessageFlag(rawValue: 1 << 29)

    /// Incoming mail is marked as phishing by anti-spam filters.
    ///
    /// const FLAG_AUTO_PHISHING = 1_073_741_824
    static let autoPhishing = MessageFlag(rawValue: 1 << 30)
    static let manualPhishing = MessageFlag(rawValue: 1 << 31)

    var description: String {
        var out = "Raw: \(rawValue), contains:"
        if self.contains(.received) {
            out += "FLAG_RECEIVED, "
        }
        if self.contains(.sent) {
            out += "FLAG_SENT, "
        }
        if self.contains(.internal) {
            out += "FLAG_INTERNAL, "
        }
        if self.contains(.e2e) {
            out += "FLAG_E2E, "
        }
        if self.contains(.auto) {
            out += "FLAG_AUTO, "
        }
        if self.contains(.replied) {
            out += "FLAG_REPLIED, "
        }
        if self.contains(.repliedAll) {
            out += "FLAG_REPLIEDALL, "
        }
        if self.contains(.forwarded) {
            out += "FLAG_FORWARDED, "
        }
        if self.contains(.autoReplied) {
            out += "FLAG_AUTOREPLIED, "
        }
        if self.contains(.imported) {
            out += "FLAG_IMPORTED, "
        }
        if self.contains(.opened) {
            out += "FLAG_OPENED, "
        }
        if self.contains(.receiptSent) {
            out += "FLAG_RECEIPT_SENT, "
        }
        if self.contains(.notified) {
            out += "FLAG_NOTIFIED, "
        }
        if self.contains(.touched) {
            out += "FLAG_TOUCHED, "
        }
        if self.contains(.receipt) {
            out += "FLAG_RECEIPT, "
        }
        if self.contains(.proton) {
            out += "FLAG_PROTON, "
        }
        if self.contains(.receiptRequest) {
            out += "FLAG_RECEIPT_REQUEST, "
        }
        if self.contains(.publicKey) {
            out += "FLAG_PUBLIC_KEY, "
        }
        if self.contains(.sign) {
            out += "FLAG_SIGN, "
        }
        if self.contains(.unsubscribed) {
            out += "FLAG_UNSUBSCRIBED, "
        }
        if self.contains(.scheduledSend) {
            out += "FLAG_SCHEDULED_SEND, "
        }
        if self.contains(.spfFail) {
            out += "FLAG_SPF_FAIL, "
        }
        if self.contains(.dkimFail) {
            out += "FLAG_DKIM_FAIL, "
        }
        if self.contains(.dmarcFailed) {
            out += "FLAG_DMARC_FAILED, "
        }
        if self.contains(.hamManual) {
            out += "FLAG_HAM_MANUAL, "
        }
        if self.contains(.spamAuto) {
            out += "FLAG_SPAM_AUTO, "
        }
        if self.contains(.spamManual) {
            out += "FLAG_SPAM_MANUAL, "
        }
        if self.contains(.autoPhishing) {
            out += "FLAG_AUTO_PHISHING, "
        }
        if self.contains(.manualPhishing) {
            out += "FLAG_MANUAL_PHISHING"
        }
        return out
    }
}
