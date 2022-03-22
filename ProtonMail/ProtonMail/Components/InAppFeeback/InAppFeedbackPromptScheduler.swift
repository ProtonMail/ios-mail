// Copyright (c) 2021 Proton AG
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

protocol InAppFeedbackStorageProtocol {
    var feedbackWasSubmitted: Bool { get set }
    var feedbackPromptWasShown: Bool { get set }
    var numberOfForegroundEnteringRegistered: Int { get set }

    func reset()
}

extension UserDefaults: InAppFeedbackStorageProtocol {
    private enum DefaultKeys: String {
        case feedbackWasSubmittedKey = "IAFeedbackWasSubmitted"
        case feedbackWasShownKey = "IAFeedbackWasShown"
        case numOfForegroundEnteringRegisteredKey = "IAFeedbackForegroundEnteringRegistered"
    }

    var feedbackWasSubmitted: Bool {
        get {
            bool(forKey: DefaultKeys.feedbackWasSubmittedKey.rawValue)
        }
        set {
            set(newValue, forKey: DefaultKeys.feedbackWasSubmittedKey.rawValue)
        }
    }

    var feedbackPromptWasShown: Bool {
        get {
            bool(forKey: DefaultKeys.feedbackWasShownKey.rawValue)
        }
        set {
            set(newValue, forKey: DefaultKeys.feedbackWasShownKey.rawValue)
        }
    }

    var numberOfForegroundEnteringRegistered: Int {
        get {
            integer(forKey: DefaultKeys.numOfForegroundEnteringRegisteredKey.rawValue)
        }
        set {
            set(newValue, forKey: DefaultKeys.numOfForegroundEnteringRegisteredKey.rawValue)
        }
    }

    func reset() {
        feedbackPromptWasShown = false
        numberOfForegroundEnteringRegistered = 0
        feedbackWasSubmitted = false
    }
}

final class InAppFeedbackPromptScheduler {
    /// Used as a feedback channel for the scheduler to notify whether
    /// the feedback was submitted or not after the prompt was shown
    /// to the user
    typealias CompletedHandler = (Bool) -> Void

    typealias PromptAllowedHandler = () -> Bool

    typealias ShowPromptHandler = (CompletedHandler?) -> Void

    private var storage: InAppFeedbackStorageProtocol

    static let numberOfTimesToIgnore = 0

    /// The time that has to pass in seconds before the user sees the prompt
    static let defaultPromptDelayTime: TimeInterval = 1.0

    private let promptDelayTime: TimeInterval

    /// Check if the context outside of `InAppFeedbackPromptScheduler`s control are ready to show the in-app
    /// feedback prompt. The handler will return `true` if this is the case.
    private var promptAllowedHandler: PromptAllowedHandler?

    private var showPromptHandler: ShowPromptHandler?

    private(set) var timer: Timer?

    private var isTimerScheduled: Bool {
        if let timer = timer, timer.isValid {
            // We scheduled already a call
            return true
        }
        return false
    }

    /// Checks the internal preconditions for displaying the prompt
    var areShowingPromptPreconditionsMet: Bool {
        if storage.feedbackWasSubmitted || storage.feedbackPromptWasShown {
            return false
        }
        if isTimerScheduled {
            return false
        }
        if storage.numberOfForegroundEnteringRegistered <= Self.numberOfTimesToIgnore {
            return false
        }
        return true
    }

    init(storage: InAppFeedbackStorageProtocol = UserDefaults.standard,
         promptDelayTime: TimeInterval = InAppFeedbackPromptScheduler.defaultPromptDelayTime,
         promptAllowedHandler: PromptAllowedHandler?,
         showPromptHandler: ShowPromptHandler?) {
        self.storage = storage
        self.promptDelayTime = promptDelayTime
        self.promptAllowedHandler = promptAllowedHandler
        self.showPromptHandler = showPromptHandler
    }

    /// Records being in foreground and reacts accordingly
    func markAsInForeground() {
        storage.numberOfForegroundEnteringRegistered += 1
        self.checkIfPromptShouldSchedule()
    }

    func cancelScheduledPrompt() {
        timer?.invalidate()
        timer = nil
    }

    /// Notifies the scheduler that the feedback was submitted. Used internally
    /// and can be used by an external party to notify the scheduler about a
    /// submit outside of its control.
    func markAsFeedbackSubmitted() {
        storage.feedbackPromptWasShown = true
        storage.feedbackWasSubmitted = true
    }

    // MARK: - Private methods

    /// Checks only for internal conditions only and schedules a prompt if is needed
    private func checkIfPromptShouldSchedule() {
        if areShowingPromptPreconditionsMet {
            schedulePromptTimer()
        }
    }

    private func schedulePromptTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: promptDelayTime, repeats: false, block: { [weak self] _ in
            if let isPromptAllowed = self?.promptAllowedHandler, isPromptAllowed() {
                self?.showPrompt()
            }
        })
    }

    private func showPrompt() {
        guard let showPrompt = showPromptHandler else {
            return
        }
        storage.feedbackPromptWasShown = true
        showPrompt({ [weak self] completed in
            self?.storage.feedbackWasSubmitted = completed
        })
    }
}
