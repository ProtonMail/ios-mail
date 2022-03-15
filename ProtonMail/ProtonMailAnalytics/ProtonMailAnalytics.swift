// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation
import Sentry

public protocol ProtonMailAnalyticsProtocol: AnyObject {
    init(endPoint: String)
    func setup(environment: String?, debug: Bool)
    func debug(event: ProtonMailAnalytics.Events,
               extra: [String: Any],
               file: String,
               function: String,
               line: Int,
               colum: Int)

    func error(event: ProtonMailAnalytics.Events,
               error: Error,
               extra: [String: Any],
               file: String,
               function: String,
               line: Int,
               colum: Int)
}

public final class ProtonMailAnalytics: ProtonMailAnalyticsProtocol {

    public enum Events: String {
        case keychainError = "Keychain Error"
        case notificationError = "Notification Error"
        case sendMessageError = "Send Message Error"
        case saveDraftError = "Save Draft Error"
        case uploadAttachmentError = "Upload Att Error"
        case fetchMetadata = "FetchMetadata"
        case grtJSONSerialization = "GRTJSONSerialization"
        case vcard = "vcard"
        case authError = "AuthError"
        case updateAddressIDError = "UpdateAddressID Error"
        case purgeOldMessages = "Purge Old Messages"
        case queueError = "Queue Error"
        case updateLoginPassword = "Update Login Password"
        case updateMailBoxPassword = "Update MailBox Password"
        case fetchSubscriptionData = "Fetch Subscription Data"
        case coreDataError = "Core Data Error"
        case menuSetupFailed = "Menu Failed to setup"
        case usersRestoreFailed = "Users Restore Failed"
        case coredataIssue = "CoreData Issue"
        case decryptedMessageBodyFailed = "Decrypted Message Body Failed"
        case paymentGetProductsListError = "Payment get products list error"
    }

    private(set) var endPoint: String
    private(set) var isEnabled = false

    required public init(endPoint: String) {
        self.endPoint = endPoint
    }

    public func setup(environment: String? = nil,
                      debug: Bool = false) {
        SentrySDK.start { options in
            options.dsn = self.endPoint
            options.debug = debug
            options.environment = environment
        }
        isEnabled = true
    }

    public func debug(event: Events,
                      extra: [String: Any],
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line,
                      colum: Int = #column) {
        guard isEnabled else {
            return
        }
        let eventToSend = Sentry.Event(level: .debug)
        eventToSend.message = SentryMessage(formatted: event.rawValue)
        eventToSend.extra = extra
        SentrySDK.capture(event: eventToSend)
    }

    public func error(event: Events,
                      error: Error,
                      extra: [String: Any],
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line,
                      colum: Int = #column) {
        guard isEnabled else {
            return
        }
        let eventToSend = Sentry.Event(error: error)
        eventToSend.message = SentryMessage(formatted: event.rawValue)
        eventToSend.extra = extra
        SentrySDK.capture(event: eventToSend)
    }
}
