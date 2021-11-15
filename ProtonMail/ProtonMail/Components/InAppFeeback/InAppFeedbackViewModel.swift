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

enum Rating {
    case unhappy
    case dissatisfied
    case neutral
    case satisfied
    case happy

    var associatedEmoji: String {
        switch self {
        case .unhappy:
            return "😫"
        case .dissatisfied:
            return "🙁"
        case .neutral:
            return "😐"
        case .satisfied:
            return "😊"
        case .happy:
            return "🤩"
        }
    }

    var topText: String? {
        switch self {
        case .unhappy, .dissatisfied, .neutral, .satisfied, .happy:
            return nil
        }
    }

    var bottomText: String? {
        switch self {
        case .unhappy:
            return LocalString._feedback_awful
        case .dissatisfied, .neutral, .satisfied:
            return nil
        case .happy:
            return LocalString._feedback_wonderful
        }
    }

    static var defaultScale: [Rating] {
        [.unhappy, .dissatisfied, .neutral, .satisfied, .happy]
    }
}

enum InAppFeedbackViewMode {
    case ratingOnly
    case full
}

protocol InAppFeedbackViewModelProtocol {
    var selectedRating: Rating? { get }
    var viewMode: InAppFeedbackViewMode { get }
    var userComment: String? { get }
    var updateViewCallback: (() -> Void)? { get set }
    var ratingScale: [Rating] { get }

    func select(rating: Rating)
    func updateFeedbackComment(comment: String)
    func submitFeedback()
}

final class InAppFeedbackViewModel: InAppFeedbackViewModelProtocol {

    private(set) var selectedRating: Rating?
    private(set) var viewMode: InAppFeedbackViewMode = .ratingOnly {
        didSet {
            updateViewCallback?()
        }
    }
    private(set) var userComment: String?
    var updateViewCallback: (() -> Void)?
    private let updater: InAppFeedbackSubmissionUpdater

    init(updater: InAppFeedbackSubmissionUpdater) {
        self.updater = updater
    }

    var ratingScale: [Rating] {
        Rating.defaultScale
    }

    func select(rating: Rating) {
        self.selectedRating = rating
        self.viewMode = .full
    }

    func updateFeedbackComment(comment: String) {
        self.userComment = comment
    }

    func submitFeedback() {
        updater.setFeedbackWasSubmitted()
    }
}
