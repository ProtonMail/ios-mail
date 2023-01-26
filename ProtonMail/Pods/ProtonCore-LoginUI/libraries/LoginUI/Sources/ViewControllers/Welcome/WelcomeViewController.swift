//
//  WelcomeViewController.swift
//  ProtonCore-Login - Created on 17.06.2021.
//
//  Copyright (c) 2022 Proton Technologies AG
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
import func AVFoundation.AVMakeRect

public typealias WelcomeScreenVariant = ScreenVariant<WelcomeScreenTexts, WelcomeScreenCustomData>

public protocol WelcomeViewControllerDelegate: AnyObject {
    func userWantsToLogIn(username: String?)
    func userWantsToSignUp()
}

public final class WelcomeViewController: UIViewController, AccessibleView {

    private let variant: WelcomeScreenVariant
    private let username: String?
    private let signupAvailable: Bool
    private weak var delegate: WelcomeViewControllerDelegate?

    override public var preferredStatusBarStyle: UIStatusBarStyle { darkModeAwarePreferredStatusBarStyle() }

    public init(variant: WelcomeScreenVariant,
                delegate: WelcomeViewControllerDelegate,
                username: String?,
                signupAvailable: Bool) {
        self.variant = variant
        self.delegate = delegate
        self.username = username
        self.signupAvailable = signupAvailable
        super.init(nibName: nil, bundle: nil)
        self.extendedLayoutIncludesOpaqueBars = true
    }

    required init?(coder: NSCoder) { fatalError("not designed to be created from IB") }

    override public func loadView() {
        let loginAction = #selector(WelcomeViewController.loginActionWasPerformed)
        let signupAction = #selector(WelcomeViewController.signupActionWasPerformed)
        view = WelcomeView(variant: variant,
                           target: self,
                           loginAction: loginAction,
                           signupAction: signupAction,
                           signupAvailable: signupAvailable)
        generateAccessibilityIdentifiers()
    }

    @objc private func loginActionWasPerformed() {
        delegate?.userWantsToLogIn(username: username)
    }

    @objc private func signupActionWasPerformed() {
        delegate?.userWantsToSignUp()
    }
}
