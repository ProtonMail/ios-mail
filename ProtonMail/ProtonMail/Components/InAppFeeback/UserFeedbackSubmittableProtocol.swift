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

import UIKit

protocol UserFeedbackSubmittableProtocol {
    typealias SubmitHandler = () -> Void

    func submit(_ userFeedback: UserFeedback, service: UserFeedbackServiceProtocol, successHandler: @escaping SubmitHandler, failureHandler: SubmitHandler?)
}

/// Helper to submit `UserFeedback` from any `UIViewController`.
extension UserFeedbackSubmittableProtocol where Self: UIViewController {
    func submit(_ userFeedback: UserFeedback, service: UserFeedbackServiceProtocol, successHandler: @escaping SubmitHandler, failureHandler: SubmitHandler?) {
        service.send(userFeedback) { sendError in
            if sendError != nil {
                failureHandler?()
            } else {
                successHandler()
            }
        }
    }
}
