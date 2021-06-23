//
//  CompleteViewController.swift
//  PMLogin - Created on 11/03/2021.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

#if canImport(UIKit)
import UIKit
import ProtonCore_CoreTranslation
import ProtonCore_Foundations
import ProtonCore_UIFoundations

protocol CompleteViewControllerDelegate: AnyObject {
    func accountCreationFinish(loginData: LoginData)
    func accountCreationError(error: Error)
}

class CompleteViewController: UIViewController, AccessibleView {

    weak var delegate: CompleteViewControllerDelegate?
    var viewModel: CompleteViewModel!
    var signupAccountType: SignupAccountType!
    var name: String?
    var password: String?
    var email: String?
    var phoneNumber: String?
    var verifyToken: String?

    // MARK: Outlets

    @IBOutlet weak var waitingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var completeTitleLabel: UILabel! {
        didSet {
            completeTitleLabel.text = CoreString._su_complete_view_title
            completeTitleLabel.textColor = UIColorManager.TextNorm
        }
    }
    @IBOutlet weak var completeDescriptionLabel: UILabel! {
        didSet {
            completeDescriptionLabel.text = CoreString._su_complete_view_desc
            completeDescriptionLabel.textColor = UIColorManager.TextWeak
        }
    }

    // MARK: View controller life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColorManager.BackgroundNorm
        waitingActivityIndicator.startAnimating()
        if signupAccountType == .internal {
            createAccount()
        } else {
            createExternalAccount()
        }
        generateAccessibilityIdentifiers()
    }

    // MARK: Private methods
    
    private func createAccount() {
        guard let userName = name, let password = password else {
            assertionFailure("Create internal account input data missing")
            return
        }
        do {
            try viewModel?.createNewUser(userName: userName, password: password, email: email, phoneNumber: phoneNumber) { result in
                switch result {
                case .success(let loginData):
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.delegate?.accountCreationFinish(loginData: loginData)
                    }
                case .failure(let error):
                    self.delegate?.accountCreationError(error: error)
                }
            }
        } catch let error {
            delegate?.accountCreationError(error: error)
        }
    }

    private func createExternalAccount() {
        guard let email = name, let password = password, let verifyToken = verifyToken else {
            assertionFailure("Create external account input data missing")
            return
        }
        do {
            try viewModel?.createNewExternalUser(email: email, password: password, verifyToken: verifyToken) { result in
                switch result {
                case .success(let loginData):
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.delegate?.accountCreationFinish(loginData: loginData)
                    }
                case .failure(let error):
                    self.delegate?.accountCreationError(error: error)
                }
            }
        } catch let error {
            delegate?.accountCreationError(error: error)
        }
    }
}

#endif
