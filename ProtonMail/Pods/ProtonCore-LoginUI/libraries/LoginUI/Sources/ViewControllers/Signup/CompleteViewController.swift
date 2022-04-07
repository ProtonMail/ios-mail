//
//  CompleteViewController.swift
//  ProtonCore-Login - Created on 11/03/2021.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
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

import UIKit
import ProtonCore_CoreTranslation
import ProtonCore_Foundations
import ProtonCore_UIFoundations
import ProtonCore_Login
import Lottie

protocol CompleteViewControllerDelegate: AnyObject {
    func accountCreationStart()
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
    var tokenType: String?
    private let margin: CGFloat = 8
    
    override var preferredStatusBarStyle: UIStatusBarStyle { darkModeAwarePreferredStatusBarStyle() }

    // MARK: Outlets

    @IBOutlet weak var animationView: AnimationView!
    @IBOutlet weak var completeTitleLabel: UILabel! {
        didSet {
            completeTitleLabel.text = CoreString._su_complete_view_title
            completeTitleLabel.textColor = ColorProvider.TextNorm
        }
    }
    @IBOutlet weak var completeDescriptionLabel: UILabel! {
        didSet {
            completeDescriptionLabel.text = CoreString._su_complete_view_desc
            completeDescriptionLabel.textColor = ColorProvider.TextWeak
        }
    }
    @IBOutlet weak var progressTableView: UITableView! {
        didSet {
            progressTableView.backgroundColor = ColorProvider.BackgroundNorm
        }
    }
    @IBOutlet weak var tableWidthConstraint: NSLayoutConstraint!
    
    // MARK: View controller life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.progressCompletion = { self.progressTableView.reloadData() }
        setupUI()
        if signupAccountType == .internal {
            createAccount()
        } else {
            createExternalAccount()
        }
        generateAccessibilityIdentifiers()
    }

    // MARK: Private methods
    
    private func setupUI() {
        view.backgroundColor = ColorProvider.BackgroundNorm
        navigationItem.setHidesBackButton(true, animated: false)
        animationView.animation = Animation.named("sign-up-create-account", bundle: LoginAndSignup.bundle)
        animationView.loopMode = .loop
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.play()
        progressTableView.dataSource = self
        tableWidthConstraint.constant = view.bounds.size.width - (margin * 2)
        viewModel?.initProgressWidth()
    }
    
    private func createAccount() {
        guard let userName = name, let password = password else {
            assertionFailure("Create internal account input data missing")
            return
        }
        delegate?.accountCreationStart()
        do {
            try viewModel?.createNewUser(userName: userName, password: password, email: email, phoneNumber: phoneNumber) { result in
                self.unlockUI()
                switch result {
                case .success(let loginData):
                    self.delegate?.accountCreationFinish(loginData: loginData)
                case .failure(let error):
                    self.delegate?.accountCreationError(error: error)
                }
            }
        } catch let error {
            unlockUI()
            delegate?.accountCreationError(error: error)
        }
    }

    private func createExternalAccount() {
        guard let email = name, let password = password, let verifyToken = verifyToken, let tokenType = tokenType else {
            assertionFailure("Create external account input data missing")
            return
        }
        delegate?.accountCreationStart()
        do {
            try viewModel?.createNewExternalUser(email: email, password: password, verifyToken: verifyToken, tokenType: tokenType) { result in
                self.unlockUI()
                switch result {
                case .success(let loginData):
                    self.delegate?.accountCreationFinish(loginData: loginData)
                case .failure(let error):
                    self.delegate?.accountCreationError(error: error)
                }
            }
        } catch let error {
            unlockUI()
            delegate?.accountCreationError(error: error)
        }
    }
}

extension CompleteViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.displayProgress.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SummaryProgressCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? SummaryProgressCell {
            cell.configureCell(displayProgress: viewModel.displayProgress[indexPath.row])
            viewModel.updateProgressWidth(index: indexPath.row, width: cell.getWidth)
            if let maxWidth = viewModel.getMaxProgressWidth {
                if maxWidth < tableWidthConstraint.constant {
                    tableWidthConstraint.constant = maxWidth
                }
            }
        }
        return cell
    }
}
