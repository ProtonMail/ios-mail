//
//  LoginNavigationViewController.swift
//  ProtonCore-Login - Created on 17.06.2021.
//
//  Copyright (c) 2021 Proton Technologies AG
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

import UIKit

public final class LoginNavigationViewController: UINavigationController {

    public init(rootViewController: UIViewController, navigationBarHidden: Bool = false) {
        super.init(rootViewController: rootViewController)
        modalPresentationStyle = .fullScreen
        setUpTransparentNavigationBar()
        setNavigationBarHidden(navigationBarHidden, animated: false)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override public var childForStatusBarStyle: UIViewController? { topViewController }

    override public var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { .fade }

    public func popToRootViewController(animated: Bool, completion: @escaping () -> Void) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        self.popToRootViewController(animated: animated)
        CATransaction.commit()
    }

    public func setUpTransparentNavigationBar() {
        navigationBar.isTranslucent = false
        navigationBar.backgroundColor = .clear
        navigationBar.shadowImage = .colored(with: .clear)
    }

    public func setUpOpaqueNavigationBar() {
        navigationBar.isTranslucent = false
        navigationBar.backgroundColor = .clear
        navigationBar.shadowImage = .colored(with: UIColorManager.Shade20)
    }

    override public func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
        setNavigationBarHidden(false, animated: true)
    }
}
