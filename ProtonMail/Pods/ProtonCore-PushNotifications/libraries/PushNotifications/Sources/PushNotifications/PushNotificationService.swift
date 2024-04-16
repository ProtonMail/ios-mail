//
//  PushNotificationService.swift
//  proton-push-notifications - Created on 9/6/23.
//
//  Copyright (c) 2023 Proton AG
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

#if canImport(UIKit)
import UIKit
typealias Application = UIApplication
#endif
#if canImport(AppKit)
import AppKit
typealias Application = NSApplication
#endif
import UserNotifications
import ProtonCoreFeatureFlags
import ProtonCoreServices
import ProtonCoreNetworking
import ProtonCoreObservability
import ProtonCoreLog

public enum RegistrationState {
    case unregistered
    case registered
    case failed
}

enum PushNotificationError: Error {
    case unrecognizedMessageFormat
    case unhandledType
    case unavailableDelegate
}

public class PushNotificationService: NSObject, PushNotificationServiceProtocol {
    enum Key {
        static let subscription = "pushNotificationSubscription"
    }

    /// We keep this shared instance to ensure the delegate of `UNUserNotificationCenter` does not go away
    public static var shared: PushNotificationService?

    public init(apiService: APIService) {
        self.apiService = apiService
        super.init()
        Self.shared = Self.shared ?? self
    }

    var latestDeviceToken: String? {
        didSet {
            registerIfPossible()
        }
    }
    private let apiService: APIService
    public var registrationState: RegistrationState = .unregistered
    public var fallbackDelegate: UNUserNotificationCenterDelegate?

    var currentUID: String {
        apiService.sessionUID
    }

    private var handlers = [String: NotificationHandler]()
    private var notificationActionPendingUnlock: PendingNotificationAction?

    /// Sets the shared instance as delegate for the `UNUserNotificationCenter`,
    /// and tries to register the device
    public func setup() {
        guard FeatureFlagsRepository.shared.isEnabled(CoreFeatureFlagType.pushNotifications) else { return }

        fallbackDelegate = NotificationCenterFactory.current.delegate
        NotificationCenterFactory.current.delegate = Self.shared
        registerForRemoteNotifications()
    }

    private func registerForRemoteNotifications() {
        NotificationCenterFactory.current.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            ObservabilityEnv.report(.pushNotificationsPermissionsRequested(result: granted ? .accepted : .rejected))
            guard granted else {
                PMLog.error("User didn't grant permission", sendToExternal: true)
                return
            }
            DispatchQueue.main.async {
                PMLog.debug("Registering for remote notifications")
                Application.shared.registerForRemoteNotifications()
            }
        }
    }

    public func didRegisterForRemoteNotifications(withDeviceToken token: Data) {
        registrationState = .registered
        let deviceToken = token.toHexRepresentation()
        let tokenHasChanged = latestDeviceToken != deviceToken
        guard tokenHasChanged else { return }
#if DEBUG
        PMLog.debug("Received new device token \(deviceToken.redacted)")
#endif
        latestDeviceToken = deviceToken

    }

    public func didFailToRegisterForRemoteNotifications(withError error: Error) {
        registrationState = .failed
        PMLog.error("Failed to register for remote notifications. \(error.localizedDescription)", sendToExternal: true)
    }

    public func registerHandler(_ handler: NotificationHandler, forType type: String) {
        handlers[type] = handler
    }

    public func didLoginWithUID(_ uid: String) {
        registerIfPossible()
    }
}

// MARK: Notification Handling

extension PushNotificationService: UNUserNotificationCenterDelegate {
    /// Method called when receiving a Push Notification while app is in the foreground
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        do {
            try processNotification(notification)
            completionHandler([.banner, .sound, .badge])
            ObservabilityEnv.report(.pushNotificationsReceived(result: .handled, applicationStatus: .active))
        } catch {
            ObservabilityEnv.report(.pushNotificationsReceived(result: .ignored, applicationStatus: .active))
            guard let delegate = fallbackDelegate else {
                PMLog.info("Undefined fallback delegate for handling an unrecognized Push Notification")
                completionHandler([.banner, .sound, .badge])
                return
            }
            delegate.userNotificationCenter?(center,
                                            willPresent: notification,
                                            withCompletionHandler: completionHandler)
        }
    }

    /// Asks the delegate to process the user's response to a delivered notification.
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
        notificationCenter(center as NotificationCenterProtocol, 
                           didReceive: response,
                           withCompletionHandler: completionHandler)
    }
}

// More abstract methods for simpler testing
extension PushNotificationService {
    func notificationCenter(_ center: NotificationCenterProtocol,
                            didReceive response: UNNotificationResponse,
                            withCompletionHandler completionHandler: @escaping () -> Void) {
        do {
            try processNotification(response.notification)
            completionHandler()
            ObservabilityEnv.report(.pushNotificationsReceived(result: .handled, applicationStatus: .inactive))
        } catch {
            ObservabilityEnv.report(.pushNotificationsReceived(result: .ignored, applicationStatus: .inactive))
            guard let delegate = fallbackDelegate else {
                PMLog.info("Undefined fallback delegate for handling an unrecognized Push Notification")
                completionHandler()
                return
            }

            /*
             We use `NotificationCenterProtocol` to allow spying on the notification mechanism, as
             there is no public constructor for `UNUserNotificationCenter` to subclass and mock.
             But to forward the call to a different delegate which may not be instrumented for testing,
             the notification needs to come from a real `UNUserNotificationCenter`, as that is the signature
             that they implement. The following cast would therefore only fail during testing with
             a mock – which is ok, as we already know and we don't want to pass a Mock to something that
             doesn't expect it.
             */

            guard let center = center as? UNUserNotificationCenter else {
                completionHandler()
                return
            }
            delegate.userNotificationCenter?(center,
                                            didReceive: response,
                                            withCompletionHandler: completionHandler)
        }
    }

    // Central method for handling notifications from background and foreground,
    // the difference being the options in the completion handler
    private func processNotification(_ notification: UNNotification) throws {
        let content = notification.request.content
        let userInfo = content.userInfo as? [String: Any]

        guard let message = userInfo?["unencryptedMessage"] as? [String: Any],
              let type = message["type"] as? String else {
            PMLog.debug("Unknown message format, forwarding…", sendToExternal: true)
            throw PushNotificationError.unrecognizedMessageFormat
        }

        guard let handler = handlers[type] else {
            PMLog.error("Unknown message type \(type), possibly from the future", sendToExternal: true)
            throw PushNotificationError.unhandledType
        }

        handler.handle(notification: notification.request.content)
    }

    // MARK: TOKEN REGISTRATION

    private func registerIfPossible() {
        // swiftlint:disable:next empty_string
        guard currentUID != "",
              let token = latestDeviceToken
        else { return }
        Task {
            await prepareSettingsAndReport(token: token, uid: currentUID)
        }
    }

    private func prepareSettingsAndReport(token: String, uid: String) async {
        guard let deviceToken = latestDeviceToken else { return }
        guard let kit = generateEncryptionKit() else { return }
        let sessionID = uid

        await register(sessionUID: sessionID, token: deviceToken, encryptionKit: kit)
    }

    private func generateEncryptionKit() -> EncryptionKit? {
        do {
            let keyPair = try MailCrypto.generateRandomKeyPair()
            return EncryptionKit(
                passphrase: keyPair.passphrase,
                privateKey: keyPair.privateKey,
                publicKey: keyPair.publicKey
            )
        } catch {
            return nil
        }
    }

    private func register(sessionUID: String, token: String, encryptionKit: EncryptionKit) async {
        let publicKey = encryptionKit.publicKey

        let request = DeviceRegistrationEndpoint(deviceToken: token,
                                                 publicKey: publicKey)

        do {
           let dictionary = try await withCheckedThrowingContinuation { continuation in
                apiService.request(method: request.method,
                                   path: request.path,
                                   parameters: request.parameters,
                                   headers: request.header,
                                   authenticated: request.isAuth,
                                   authRetry: request.authRetry,
                                   customAuthCredential: request.authCredential,
                                   nonDefaultTimeout: request.nonDefaultTimeout,
                                   retryPolicy: request.retryPolicy,
                                   onDataTaskCreated: { _ in }) { task, result in
                    if let httpResponse = task?.response as? HTTPURLResponse {
                        let statusCode = httpResponse.statusCode
                        let status: PushNotificationsHTTPResponseCodeStatus
                        switch statusCode {
                        case 200: status = .http200
                        case 201...299: status = .http2xx
                        case 300...399: status = .http3xx
                        case 400: status = .http400
                        case 401: status = .http401
                        case 403: status = .http403
                        case 408: status = .http408
                        case 421: status = .http421
                        case 422: status = .http422
                        case 402, 404...407, 409...420, 423...499: status = .http4xx
                        case 500: status = .http500
                        case 503: status = .http503
                        case 501, 502, 504...599: status = .http5xx
                        default: status = .unknown
                        }
                        ObservabilityEnv.report(.pushNotificationsTokenRegistered(status: status))
                    }
                    continuation.resume(with: result)
                }
           }
        } catch {
            PMLog.error("Couldn't register APNS token: \(error.localizedDescription)", sendToExternal: true)
        }
    }

}

private extension PushNotificationService {

    struct PendingNotificationAction {
        let payload: NotificationActionPayload
        let completionHandler: () -> Void
    }

    struct NotificationActionPayload {
        let sessionId: String
        let messageId: String
        let actionIdentifier: String
    }
}

extension APIErrorCode {
    static let resourceDoesNotExist = 2501
    static let deviceTokenIsInvalid = 11210
}

fileprivate extension String {

    /// Hides all characters except the last 6.
    var redacted: String {
        "****\(suffix(6))"
    }
}
