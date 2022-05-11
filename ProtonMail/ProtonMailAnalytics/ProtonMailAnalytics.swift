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
    func track(event: MailAnalyticsEvent)
    func track(error: MailAnalyticsError)
}

public final class ProtonMailAnalytics: ProtonMailAnalyticsProtocol {
    private let endPoint: String
    private(set) var isEnabled = false

    required public init(endPoint: String) {
        self.endPoint = endPoint
    }

    public func setup(environment: String? = nil, debug: Bool = false) {
        SentrySDK.start { options in
            options.dsn = self.endPoint
            options.debug = debug
            options.environment = environment

            // Disabling some options to make the report work. Otherwise it does not show in Sentry,
            // probably because the size limit in Proton's backend is 65kb for each event.
            // See: https://jira.protontech.ch/browse/INFSUP-682
            options.enableAutoSessionTracking = false
            options.attachStacktrace = false
            options.maxBreadcrumbs = 10
        }
        isEnabled = true
    }

    public func track(event: MailAnalyticsEvent) {
        guard isEnabled else { return }
        let eventToSend = Sentry.Event(level: .info)
        eventToSend.message = SentryMessage(formatted: "\(event.name) - \(event.description)")
        // eventToSend.extra = error.extraInfo <- extra does not allow to query in the Sentry dashboard
        SentrySDK.capture(event: eventToSend)
    }

    public func track(error: MailAnalyticsError) {
        guard isEnabled else { return }
        let eventToSend = Sentry.Event(error: error)
        eventToSend.message = SentryMessage(formatted: "\(error.name) - \(error.description)")
        SentrySDK.capture(event: eventToSend)
    }
}

// MARK: Events

public enum MailAnalyticsEvent {

    /// The user session has been terminated and the user has to authenticate again
    case userKickedOut(reason: UserKickedOutReason)

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
            message = "User kicked out"
        }
        return message
    }

    var description: String {
        switch self {
        case .userKickedOut(let reason):
            return "reason: \(reason.description)"
        }
    }
}

public enum UserKickedOutReason {
    case apiAccessTokenInvalid
    case afterLockScreen(description: String)
    case noUsersFoundInUsersManager(action: String)
    case unexpected(description: String)

    var description: String {
        let description: String
        switch self {
        case .apiAccessTokenInvalid:
            description = "user access token is not valid anymore"
        case .afterLockScreen(let message):
            description = "after lock screen (\(message))"
        case .noUsersFoundInUsersManager(let action):
            description = "no users found for action (\(action))"
        case .unexpected(let message):
            description = "unexpected (\(message))"
        }
        return description
    }
}

// MARK: Error Events

public enum MailAnalyticsError: Error {
    /// An error occurred during Core Data initial set up
    case coreDataInitialisation(error: String)

    var name: String {
        let name: String
        switch self {
        case .coreDataInitialisation:
            name = "Core Data initialisation error"
        }
        return name
    }

    var description: String {
        let description: String
        switch self {
        case .coreDataInitialisation(let error):
            description = error
        }
        return description
    }
}

extension MailAnalyticsError: Equatable {

    public static func == (lhs: MailAnalyticsError, rhs: MailAnalyticsError) -> Bool {
        lhs.name == rhs.name && lhs.description == rhs.description
    }
}
