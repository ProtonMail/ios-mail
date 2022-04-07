//
//  MenuViewController.swift
//  ProtonCore-HumanVerification - Created on 2/1/16.
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
import ProtonCore_UIFoundations
import ProtonCore_Foundations
import ProtonCore_Networking

protocol MenuViewControllerDelegate: AnyObject {
    func didSelectVerifyMethod(method: VerifyMethod)
    func didShowMenuHelpViewController()
    func didDismissMenuViewController()
}

public class MenuViewController: UIViewController, AccessibleView {

    // MARK: - Outlets

    @IBOutlet weak var helpBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var segmentControl: PMSegmentedControl!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var closeBarButtonItem: UIBarButtonItem!

    // MARK: - Properties

    weak var delegate: MenuViewControllerDelegate?
    var viewModel: MenuViewModel!
    var viewTitle: String?
    var capchaViewController: RecaptchaViewController?
    var emailViewController: EmailVerifyViewController?
    var smsViewController: PhoneVerifyViewController?
    
    override public var preferredStatusBarStyle: UIStatusBarStyle { darkModeAwarePreferredStatusBarStyle() }

    // MARK: View controller life cycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        generateAccessibilityIdentifiers()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    func resetUI() {
        configureUI()
    }

    // MARK: - Actions

    @IBAction func helpAction(_ sender: Any) {
        delegate?.didShowMenuHelpViewController()
    }

    @IBAction func closeAction(_ sender: Any) {
        delegate?.didDismissMenuViewController()
    }

    // MARK: - Private Interface

    private func configureUI() {
        closeBarButtonItem.image = IconProvider.crossSmall
        closeBarButtonItem.tintColor = ColorProvider.IconNorm
        closeBarButtonItem.accessibilityLabel = "closeButton"
        view.backgroundColor = ColorProvider.BackgroundNorm
        self.title = viewTitle ?? CoreString._hv_title
        updateTitleAttributes()
        helpBarButtonItem.title = CoreString._hv_help_button
        helpBarButtonItem.tintColor = ColorProvider.BrandNorm
        segmentControl.removeAllSegments()
        viewModel.verifySegments.forEach {
            segmentControl.insertSegment(withTitle: $0.title, at: $0.index, animated: true)
        }
        segmentControl.addTarget(self, action: #selector(selectionDidChange(_:)), for: .valueChanged)

        capchaViewController = nil
        emailViewController = nil
        smsViewController = nil

        // Select First Segment
        segmentControl.selectedSegmentIndex = 0
        navigationController?.hideBackground()
        updateView()
    }

    @objc private func selectionDidChange(_ sender: UISegmentedControl) {
        updateView()
    }

    private var lastViewController: UIViewController?

    private func updateView() {
        // no verify methods in view model
        guard viewModel.verifyMethods.count > 0 else { return }
        let index = segmentControl.selectedSegmentIndex
        let item = viewModel.verifyMethods[index]
        if shouldRefreshVerifyMethod(method: item) {
            delegate?.didSelectVerifyMethod(method: item)
        }
        if let viewController = lastViewController {
            self.remove(asChildViewController: viewController)
            viewController.dismiss(animated: false)
            lastViewController = nil
        }
        var customViewController: UIViewController?
        switch item.predefinedMethod {
        case .captcha:
            customViewController = capchaViewController
        case .email:
            customViewController = emailViewController
        case .sms:
            customViewController = smsViewController
        default:
            break
        }
        guard let childViewController = customViewController else { return }
        self.add(asChildViewController: childViewController)
        if let viewController = children.last {
            lastViewController = viewController
        }
    }

    private func shouldRefreshVerifyMethod(method: VerifyMethod) -> Bool {
        if method.predefinedMethod == .captcha || (method.predefinedMethod == .email && emailViewController == nil) || (method.predefinedMethod == .sms && smsViewController == nil) {
            // reload only captha when user switches segmentControl
            return true
        }
        return false
    }

    private func remove(asChildViewController viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }

    private func add(asChildViewController viewController: UIViewController) {
        addChild(viewController)
        self.containerView .addSubview(viewController.view)
        viewController.view.frame = self.containerView.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.didMove(toParent: self)
    }
}
