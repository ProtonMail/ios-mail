//
//  WelcomeAnimationViewController.swift
//  ProtonCore-Login - Created on 23.03.2022.
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

#if os(iOS)

import UIKit
import ProtonCoreUIFoundations
import ProtonCoreDataModel
import Lottie

public final class WelcomeAnimationViewController: UIViewController {

    override public var preferredStatusBarStyle: UIStatusBarStyle { darkModeAwarePreferredStatusBarStyle() }

    public init(variant: WelcomeScreenVariant, finishHandler: (() -> Void)? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.setupUI(variant: variant, finishHandler: finishHandler)
    }

    required init?(coder: NSCoder) {
        fatalError("not designed to be created from IB")
    }

    private func setupUI(variant: WelcomeScreenVariant, finishHandler: (() -> Void)?) {
        navigationItem.setHidesBackButton(true, animated: false)
        view.backgroundColor = ColorProvider.BackgroundNorm

        let animationView = createAnimationView(variant: variant, finishHandler: finishHandler)
        view.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: animationView.topAnchor),
            view.bottomAnchor.constraint(equalTo: animationView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: animationView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: animationView.trailingAnchor)
        ])
    }

    private func createAnimationView(variant: WelcomeScreenVariant, finishHandler: (() -> Void)?) -> LottieAnimationView {
        let animationView = LottieAnimationView()
        animationView.animation = .named(welcomeAnimationFile(variant: variant), bundle: LoginAndSignup.bundle)
        animationView.loopMode = .playOnce
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.play { _ in finishHandler?() }
        return animationView
    }

    private func welcomeAnimationFile(variant: WelcomeScreenVariant) -> String {
        switch variant {
        case .mail, .custom: return "welcome_animation_mail"
        case .vpn: return "welcome_animation_vpn"
        case .calendar: return "welcome_animation_calendar"
        case .drive: return "welcome_animation_drive"
        // no animation for pass and wallet, but it's ok because we don't use the animations atm
        case .pass, .wallet: return ""
        }
    }
}

#endif
