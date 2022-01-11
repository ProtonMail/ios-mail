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

extension Rating {
    var intValue: Int {
        let mapping: [Rating: Int] = [.unhappy: 1, .dissatisfied: 2, .neutral: 3, .satisfied: 4, .happy: 5]
        if let value = mapping[self] {
            return value
        }
        assert(false)
        // Caught undefined value
        return 0
    }
}

enum InAppFeedbackViewMode {
    case ratingOnly
    case full
}

enum InAppFeedbackViewModelError: Error {
    case validation(String)
    case canceled
}

protocol InAppFeedbackViewModelProtocol {
    var selectedRating: Rating? { get }
    var userComment: String? { get }
    var viewMode: InAppFeedbackViewMode { get }
    var updateViewCallback: (() -> Void)? { get set }
    var ratingScale: [Rating] { get }

    func select(rating: Rating)
    func updateFeedbackComment(comment: String)
    func submitFeedback()
    func cancelFeedback()
    func makeFeedback() -> Swift.Result<UserFeedback, InAppFeedbackViewModelError>
}

final class InAppFeedbackViewModel: InAppFeedbackViewModelProtocol {
    typealias SubmissionHandler = (Swift.Result<UserFeedback, InAppFeedbackViewModelError>) -> Void

    static let defaultFeedbackType = "mail_ios_v4_launch"

    private(set) var submissionHandler: SubmissionHandler

    private(set) var selectedRating: Rating?

    private(set) var viewMode: InAppFeedbackViewMode = .ratingOnly {
        didSet {
            updateViewCallback?()
        }
    }

    private(set) var userComment: String?

    var updateViewCallback: (() -> Void)?

    init(submissionHandler: @escaping SubmissionHandler) {
        self.submissionHandler = submissionHandler
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
        submissionHandler(makeFeedback())
    }

    func cancelFeedback() {
        submissionHandler(.failure(.canceled))
    }

    func makeFeedback() -> Swift.Result<UserFeedback, InAppFeedbackViewModelError> {
        return Self.makeUserFeedback(type: Self.defaultFeedbackType, rating: selectedRating, comment: userComment)
    }

    /// Used by `makeFeedback` function and is exposed for testing.
    static func makeUserFeedback(type: String,
                                 rating: Rating?,
                                 comment: String?) -> Swift.Result<UserFeedback, InAppFeedbackViewModelError> {
        guard let rating = rating else {
            return .failure(.validation("Undefined rating"))
        }
        guard !type.isEmpty else {
            return .failure(.validation("Undefined feedback type"))
        }
        let userFeedback = UserFeedback(type: type, score: rating.intValue, text: comment ?? "")
        return .success(userFeedback)
    }
}
