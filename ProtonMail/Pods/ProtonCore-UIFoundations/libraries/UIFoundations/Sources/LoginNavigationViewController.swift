//
//  LoginNavigationViewController.swift
//  ProtonCore-UIFoundations - Created on 17.06.2021.
//
//  Copyright (c) 2021 Proton Technologies AG
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

public final class LoginNavigationViewController: UINavigationController {

    public enum TransitionStyle {
        case systemDefault
        case modalLike
    }

    public var autoresettingNextTransitionStyle: TransitionStyle = .systemDefault

    public init(rootViewController: UIViewController, navigationBarHidden: Bool = false) {
        super.init(rootViewController: rootViewController)
        delegate = self
        modalPresentationStyle = .fullScreen
        setUpShadowLessNavigationBar()
        setNavigationBarHidden(navigationBarHidden, animated: false)
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
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

    public func setUpShadowLessNavigationBar() {
        baseNavigationBarConfiguration()
        if #available(iOS 13.0, *) {
            navigationBar.standardAppearance.shadowImage = .colored(with: .clear)
        } else {
            navigationBar.shadowImage = .colored(with: .clear)
        }
    }

    public func setUpNavigationBarWithShadow() {
        baseNavigationBarConfiguration()
        if #available(iOS 13.0, *) {
            navigationBar.standardAppearance.shadowImage = .colored(with: ColorProvider.Shade20)
        } else {
            navigationBar.shadowImage = .colored(with: ColorProvider.Shade20)
        }
    }

    private func baseNavigationBarConfiguration() {
        let color = topViewController?.view.backgroundColor ?? .clear
        navigationBar.isTranslucent = false
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = color
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = navigationBar.standardAppearance
        } else {
            navigationBar.setBackgroundImage(.colored(with: color), for: .default)
            navigationBar.backgroundColor = .clear
        }
    }
}

extension LoginNavigationViewController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController,
                                     animationControllerFor operation: UINavigationController.Operation,
                                     from fromVC: UIViewController,
                                     to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        defer { autoresettingNextTransitionStyle = .systemDefault }
        switch autoresettingNextTransitionStyle {
        case .modalLike: return ModalLikeTransition()
        case .systemDefault: return nil
        }
    }
}

fileprivate final class ModalLikeTransition: NSObject, UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval { 0.3 }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to)
        else { return }
        let containerView = transitionContext.containerView

        let finalFrame = transitionContext.finalFrame(for: toViewController)
        toViewController.view.frame.origin.y = fromViewController.view.frame.maxY
        containerView.insertSubview(toViewController.view, aboveSubview: fromViewController.view)

        UIView.animate(withDuration: transitionDuration(using: transitionContext)) {
            toViewController.view.frame = finalFrame
        } completion: {
            toViewController.navigationController?.setNavigationBarHidden(false, animated: false)
            transitionContext.completeTransition($0)
        }
    }
}
