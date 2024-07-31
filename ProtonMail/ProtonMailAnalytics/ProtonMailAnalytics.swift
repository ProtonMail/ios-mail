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
import Sentry

public protocol ProtonMailAnalyticsProtocol: AnyObject {
    func setup(environment: String, debug: Bool, reportCrashes: Bool, telemetry: Bool)
    func assignUser(userID: String?)
    func track(event: MailAnalyticsEvent, trace: String?)
    func track(error: MailAnalyticsErrorEvent, trace: String?, fingerprint: Bool)
}

public final class ProtonMailAnalytics: ProtonMailAnalyticsProtocol {
    private let endPoint: String
    private(set) var isEnabled = false
    private var telemetry = false
    private var reportCrashes = false

    required public init(endPoint: String) {
        self.endPoint = endPoint
    }

    public func setup(
        environment: String,
        debug: Bool = false,
        reportCrashes: Bool,
        telemetry: Bool
    ) {
        guard reportCrashes != self.reportCrashes || telemetry != self.telemetry else { return }
        self.telemetry = telemetry
        self.reportCrashes = reportCrashes
        if reportCrashes == false, telemetry == false {
            SentrySDK.close()
        } else {
            SentrySDK.close()
            SentrySDK.start { options in
                options.dsn = self.endPoint
                options.debug = debug
                options.environment = environment
                options.enableAutoPerformanceTracing = false
                options.enableAppHangTracking = false
                options.enableCaptureFailedRequests = false
                options.enableTracing = false

                options.enableNetworkTracking = reportCrashes
                options.enableNetworkBreadcrumbs = reportCrashes
                options.enableAutoSessionTracking = reportCrashes
                options.enableAutoBreadcrumbTracking = reportCrashes
                options.enableWatchdogTerminationTracking = reportCrashes

                options.enableCrashHandler = reportCrashes
            }
            isEnabled = true
        }
    }

    public func assignUser(userID: String?) {
        if let userID {
            let user = User(userId: userID)
            SentrySDK.setUser(user)
        } else {
            SentrySDK.setUser(nil)
        }
    }

    public func track(event: MailAnalyticsEvent, trace: String?) {
        guard isEnabled, telemetry else { return }
        let eventToSend = Sentry.Event(level: .info)
        let formattedMessage: String
        if let description = event.description {
            formattedMessage = "\(event.name) - \(description)"
        } else {
            formattedMessage = "\(event.name)"
        }
        eventToSend.message = SentryMessage(formatted: formattedMessage)
        // From the Sentry dashboard it is not possible to query using the `extra` field.
        eventToSend.extra = combinedExtra(extraInfo: nil, trace: trace)
        SentrySDK.capture(event: eventToSend)
    }

    public func track(error errorEvent: MailAnalyticsErrorEvent, trace: String?, fingerprint: Bool) {
        guard isEnabled, telemetry else { return }
        let eventToSend = Sentry.Event(level: .error)
        eventToSend.message = SentryMessage(formatted: errorEvent.name)
        if fingerprint {
            /*
             The event name stablishes the grouping of the events in Sentry.
             Otherwise the automatic Sentry fingerprinting could group Sentry.events
             together even if they have different `message` values.
             **/
            eventToSend.fingerprint = [errorEvent.name]
        }
        // From the Sentry dashboard it is not possible to query using the `extra` field.
        eventToSend.extra = combinedExtra(extraInfo: errorEvent.extraInfo, trace: trace)
        SentrySDK.capture(event: eventToSend)
    }

    func combinedExtra(extraInfo: [String: Any]?, trace: String?) -> [String: Any]? {
        var extraInfo: [String: Any] = extraInfo ?? [:]
        extraInfo["Custom Trace"] = trace.map(replacePotentiallyRedactedWords)
        return extraInfo.isEmpty ? nil : extraInfo
    }

    /// To avoid Sentry redacting our data for PII compliance policies, we replace some strings. For clarification
    /// the strings being replaced are references to function names.
    private func replacePotentiallyRedactedWords(trace: String) -> String {
        var tmpTrace = trace
        tmpTrace = tmpTrace.replacingOccurrences(of: "auth", with: "autth", options: .caseInsensitive)
        tmpTrace = tmpTrace.replacingOccurrences(of: "credential", with: "creddential", options: .caseInsensitive)
        return tmpTrace
    }
}

// MARK: Events

public enum MailAnalyticsEvent {

    /// The user session has been terminated and the user has to authenticate again
    case userKickedOut(reason: UserKickedOutReason)

    /// A message saying Proton is unreachable has been shown
    case protonUnreachableBannerShown
}

extension MailAnalyticsEvent: Equatable {

    public static func == (lhs: MailAnalyticsEvent, rhs: MailAnalyticsEvent) -> Bool {
        lhs.name == rhs.name && lhs.description == rhs.description
    }
}

private extension MailAnalyticsEvent {

    var name: String {
        let message: String
        switch self {
        case .userKickedOut:
            message = "User unwanted log out"
        case .protonUnreachableBannerShown:
            message = "Proton unreachable banner shown"
        }
        return message
    }

    var description: String? {
        switch self {
        case .userKickedOut(let reason):
            return "reason: \(reason.description)"
        case .protonUnreachableBannerShown:
            return nil
        }
    }
}

public enum UserKickedOutReason {
    case apiAccessTokenInvalid

    var description: String {
        let description: String
        switch self {
        case .apiAccessTokenInvalid:
            description = "user access token is not valid anymore"
        }
        return description
    }
}

// MARK: Error Events

public enum MailAnalyticsErrorEvent: Error {

    /// An error occurred during Core Data initial set up
    case coreDataInitialisation(error: String)

    /// used to track when the app sends a conversation request without a conversation ID.
    case abortedConversationRequest

    // called MenuViewModel.menuItem(indexPath:) method with a nonexistent index path
    case invalidMenuItemRequested(section: String, row: Int, itemCount: Int, caller: StaticString)
    case coreDataSavingError(error: Error, caller: StaticString, file: StaticString, line: UInt)

    // send message
    case sendMessageFail(error: String)
    case sendMessageResponseError(responseCode: Int?)

    // contacts
    case contactCreateFailInBatch(error: NSError)
    case contactUpdateFail(error: NSError)

    case userObjectsJsonEncodingError(Error, String)
    case userObjectsJsonDecodingError(Error, String)

    case appLockInconsistency(error: String)

    case assertionFailure(
        message: String,
        caller: StaticString,
        file: StaticString,
        line: UInt
    )

    var name: String {
        switch self {
        case .coreDataInitialisation:
            return "Core Data initialisation error"
        case .abortedConversationRequest:
            return "Aborted request without conversation ID"
        case .invalidMenuItemRequested:
            return "Invalid menu item requested"
        case .coreDataSavingError:
            return "Core Data saving error"
        case .sendMessageFail(let error):
            return "Send fail - \(error)"
        case .sendMessageResponseError(let responseCode):
            let code = "\(responseCode?.description ?? "n/a" )"
            return "Send response error - responseCode: \(code)"
        case .contactCreateFailInBatch(let error):
            return "Create contact fail in batch - code: \(error.code)"
        case .contactUpdateFail(let error):
            return "Update contact fail - code: \(error.code)"
        case let .assertionFailure(message, _, _, _):
            return "Assertion failure: \(message)"
        case .userObjectsJsonDecodingError(_, let type):
            return "Error while decoding user object: \(type)"
        case .userObjectsJsonEncodingError(_, let type):
            return "Error while encoding user object: \(type)"
        case .appLockInconsistency(let error):
            return "Unlock inconsistency: \(error)"
        }
    }

    var extraInfo: [String: Any]? {
        let info: [String: Any]?
        switch self {
        case let .coreDataInitialisation(error):
            info = [
                "Custom Error": error
            ]
        case .abortedConversationRequest,
                .sendMessageFail, .sendMessageResponseError,
                .appLockInconsistency:
            info = nil
        case let .invalidMenuItemRequested(section, row, itemCount, caller):
            info = [
                "Section": section,
                "Row": row,
                "ItemCount": itemCount,
                "Caller": caller
            ]
        case let .coreDataSavingError(error, caller, file, line):
            info = [
                "Caller": caller,
                "Error": error,
                "File": file,
                "Line": line
            ]
        case .contactCreateFailInBatch(let error), .contactUpdateFail(let error):
            info = ["Error": "\(error)"]
        case let .assertionFailure(message, caller, file, line):
            info = [
                "Caller": caller,
                "File": file,
                "Line": line,
                "Message": message
            ]
        case let .userObjectsJsonDecodingError(error, type):
            info = [
                "Error": error,
                "Type": type
            ]
        case let .userObjectsJsonEncodingError(error, type):
            info = [
                "Error": error,
                "Type": type
            ]
        }
        return info
    }
}

extension MailAnalyticsErrorEvent: Equatable {

    public static func == (lhs: MailAnalyticsErrorEvent, rhs: MailAnalyticsErrorEvent) -> Bool {
        lhs.name == rhs.name
    }
}
