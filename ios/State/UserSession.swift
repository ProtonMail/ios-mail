// Copyright (c) 2024 Proton Technologies AG
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
import proton_mail_uniffi

/**
 Ensures that the active session is thread safe and that it is only initialised once.
 */
actor UserSession {
    private var activeSession: MailUserSession?
    private var runningTask: Task<MailUserSession?, Error>?

    /**
     Returns the existing `activeSession` if there is one, otherwise it will try to load a stored session and initialise the MailUserContext.

     This function guarantess sequential execution and therefore that MailUserContext is only initialized once no matter how many threads
     call at the same time.
     */
    func activeSession(from mailContext: MailSession) async throws -> MailUserSession? {
        guard let taskInQueue = runningTask else {
            runningTask = Task {
                try await _activeSession(from: mailContext)
            }
            return try await runningTask?.value
        }
        let newTask = Task {
            _ = try await taskInQueue.value
            return try await _activeSession(from: mailContext)
        }
        runningTask = newTask
        return try await newTask.value
    }

    private func _activeSession(from mailContext: MailSession) async throws -> MailUserSession? {
        if let activeSession {
            return activeSession
        }
        guard let firstStoredSession = try mailContext.storedSessions().first else {
            AppLogger.log(message: "no active user session found", category: .userSessions, isError: true)
            return nil
        }
        let newUserContext = try mailContext.userContextFromSession(session: firstStoredSession, cb: SessionDelegate.shared)
        try await udpateActiveSession(newUserContext, needsInitialization: false)
        return activeSession
    }
    
    /// Call this function to change the current user session
    /// - Parameters:
    ///   - needsInitialization: sessions coming from a sign in/up need to be initiliased. Sessions that
    ///   were persisted do not require to be initilized again.
    func udpateActiveSession(_ newUserSession: MailUserSession, needsInitialization: Bool) async throws {
        if needsInitialization {
            try await newUserSession.initialize(cb: UserContextInitializationDelegate.shared)
        }
        activeSession = newUserSession
    }

    func deleteActiveSession() {
        activeSession = nil
    }
}
