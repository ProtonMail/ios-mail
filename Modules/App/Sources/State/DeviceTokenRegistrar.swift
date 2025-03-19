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

import Combine
import Foundation
import InboxCore
import proton_app_uniffi

final class DeviceTokenRegistrar {
    lazy var uploadDeviceToken: (String, [StoredSession]) -> Void = { deviceToken, storedSessions in
        let device = Self.prepareDeviceRegistrationRequest(deviceToken: deviceToken)

        for storedSession in storedSessions {
            Task {
                do {
                    let mailUserSession = try await AppContext.shared.mailSession.userContextFromSession(
                        session: storedSession
                    ).get()

                    try await registerAndSaveDevice(session: mailUserSession, device: device).get()

                    AppLogger.log(message: "Subscribed \(storedSession.sessionId()) to APNS", category: .notifications)
                } catch {
                    AppLogger.log(error: error, category: .notifications)
                }
            }
        }
    }

    private let deviceTokenSubject = PassthroughSubject<String, Never>()
    private let sessionsSubject = PassthroughSubject<[StoredSession], Never>()

    private var cancellables: Set<AnyCancellable> = .init()
    private var sessionsWatchHandle: WatchHandle? {
        didSet {
            oldValue?.disconnect()
        }
    }

    init() {
        let newlyAuthenticatedSessionsPublisher: AnyPublisher<[StoredSession], Never> = sessionsSubject
            .map { $0.filter { $0.state() == .authenticated }}
            .removeDuplicates { Set($0.map { $0.sessionId() }) == Set($1.map { $0.sessionId() }) }
            .scan([], Self.onlyNewlyAuthenticatedSessions)
            .filter { !$0.isEmpty }
            .eraseToAnyPublisher()

        deviceTokenSubject
            .combineLatest(newlyAuthenticatedSessionsPublisher)
            .sink { [weak self] in
                self?.uploadDeviceToken($0, $1)
            }
            .store(in: &cancellables)
    }

    deinit {
        sessionsWatchHandle?.disconnect()
    }

    func onDeviceTokenReceived(_ deviceToken: Data) {
        let stringToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        AppLogger.log(message: "APS token: \(stringToken)", category: .notifications)

        deviceTokenSubject.send(stringToken)
    }

    func startWatchingMailSessionForSessions(_ mailSession: MailSessionProtocol) async throws {
        let callback = AsyncLiveQueryCallbackWrapper { [weak mailSession, weak sessionsSubject] in
            guard let mailSession, let sessionsSubject else { return }

            switch await mailSession.getSessions() {
            case .ok(let sessions):
                sessionsSubject.send(sessions)
            case .error(let error):
                AppLogger.log(error: error, category: .notifications)
            }
        }

        let watchedSessions = try await mailSession.watchSessionsAsync(callback: callback).get()
        sessionsWatchHandle = watchedSessions.handle
        sessionsSubject.send(watchedSessions.sessions)
    }

    private static func onlyNewlyAuthenticatedSessions(
        previousNewlyAuthenticatedSessions: [StoredSession],
        currentlyAuthenticatedSessions: [StoredSession]
    ) -> [StoredSession] {
        currentlyAuthenticatedSessions.filter { currentlyAuthenticatedSession in
            !previousNewlyAuthenticatedSessions.map { $0.sessionId() }.contains(currentlyAuthenticatedSession.sessionId())
        }
    }

    private static func prepareDeviceRegistrationRequest(deviceToken: String) -> RegisteredDevice {
        let environment: DeviceEnvironment

#if DEBUG
        environment = .appleDev
#else
        environment = .appleProd
#endif

        return RegisteredDevice(
            deviceToken: deviceToken,
            environment: environment,
            pingNotificationStatus: nil,
            pushNotificationStatus: nil
        )
    }
}
