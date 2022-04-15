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
import ProtonCore_Networking
import ProtonCore_Services

/// See https://protonmail.gitlab-pages.protontech.ch/Slim-API/core_legacy/#tag/Feedback
struct UserFeedbackRequest: Request {
    enum ParamKeys: String {
        case feedbackType = "FeedbackType"
        case score = "Score"
        case feedback = "Feedback"
    }

    static let apiPath = "/core/v4/feedback"

    static let responseSuccessCode = 1000

    let path = Self.apiPath

    let method: HTTPMethod = .post

    let feedbackType: String

    let score: Int

    let feedback: String

    var parameters: [String: Any]? {
        let params: [String: Any] = [
            ParamKeys.feedbackType.rawValue: self.feedbackType,
            ParamKeys.score.rawValue: self.score,
            ParamKeys.feedback.rawValue: self.feedback
        ]
        return params
    }

    init(with feedback: UserFeedback) {
        self.feedbackType = feedback.type
        self.feedback = feedback.text
        self.score = feedback.score
    }
}

struct UserFeedback {
    let type: String

    let score: Int

    let text: String
}

final class UserFeedbackResponse: Response {}

enum UserFeedbackServiceError: Error {
    case feedbackTypeIsTooLong
    case service(ResponseError?)
    /// Sent out in case of unexpected response code
    case unexpectedCode(Int?)
}

protocol UserFeedbackServiceProtocol: Service {
    func send(_ feedback: UserFeedback, handler: @escaping (UserFeedbackServiceError?) -> Void)
}

final class UserFeedbackService: UserFeedbackServiceProtocol {
    static let feedbackTypeMaxLength = 100

    let apiService: APIService

    init(apiService: APIService) {
        self.apiService = apiService
    }

    func send(_ feedback: UserFeedback, handler: @escaping (UserFeedbackServiceError?) -> Void) {
        guard feedback.type.count <= Self.feedbackTypeMaxLength else {
            handler(.feedbackTypeIsTooLong)
            return
        }
        let request = UserFeedbackRequest(with: feedback)
        apiService.exec(route: request, responseObject: UserFeedbackResponse()) { task, response in
            guard response.error == nil else {
                handler(.service(response.error))
                return
            }
            guard response.responseCode == UserFeedbackRequest.responseSuccessCode else {
                handler(.unexpectedCode(response.httpCode))
                return
            }

            handler(nil)
        }
    }
}
