// Copyright (c) 2021 Proton Technologies AG
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

protocol InAppFeedbackStorageProtocol {
    var feedbackWasSubmitted: Bool { get set }
    var feedbackPromptWasShown: Bool { get set }
    var numberOfForegroundEnteringRegistered: Int { get set }
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
}

protocol InAppFeedbackSubmissionUpdater {
    func setFeedbackWasSubmitted()
}

final class InAppFeedbackPromptScheduler {
    private var storage: InAppFeedbackStorageProtocol
    
    private(set) var feedbackWasSubmitted: Bool {
        didSet {
            storage.feedbackWasSubmitted = feedbackWasSubmitted
        }
    }
    
    private(set) var feedbackPromptWasShown: Bool {
        didSet {
            storage.feedbackPromptWasShown = feedbackPromptWasShown
        }
    }
    
    private(set) var numberOfForegroundEnteringRegistered: Int {
        didSet {
            storage.numberOfForegroundEnteringRegistered = numberOfForegroundEnteringRegistered
        }
    }

    static let numberOfTimesToIgnore = 1
    static let pausePrePrompt = 1.0
    private var onPrompt: (() -> Bool)?

    init(storage: InAppFeedbackStorageProtocol = UserDefaults.standard, onPrompt: (() -> Bool)?) {
        self.storage = storage
        self.onPrompt = onPrompt
        feedbackWasSubmitted = self.storage.feedbackWasSubmitted
        feedbackPromptWasShown = self.storage.feedbackPromptWasShown
        numberOfForegroundEnteringRegistered = self.storage.numberOfForegroundEnteringRegistered
    }

    var shouldShowFeedbackPrompt: Bool {
        if feedbackWasSubmitted || feedbackPromptWasShown {
            return false
        }
        if numberOfForegroundEnteringRegistered <= Self.numberOfTimesToIgnore {
            return false
        }
        return true
    }

    func didEnterForeground() {
        numberOfForegroundEnteringRegistered += 1
        if shouldShowFeedbackPrompt {
            delay(1.0) {
                if self.onPrompt?() == true {
                    self.feedbackPromptWasShown = true
                }
            }
        }
    }
}

extension InAppFeedbackPromptScheduler: InAppFeedbackSubmissionUpdater {
    func setFeedbackWasSubmitted() {
        feedbackWasSubmitted = true
    }
}
