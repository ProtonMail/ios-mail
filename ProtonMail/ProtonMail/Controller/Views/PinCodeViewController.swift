//
//  PinCodeViewController.swift
//  Proton Mail - Created on 4/6/16.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCore_UIFoundations
import UIKit

protocol PinCodeViewControllerDelegate: AnyObject {
    func cancel(completion: @escaping () -> Void)
    func next()
}

final class PinCodeViewController: UIViewController, AccessibleView {
    let viewModel: PinCodeViewModel
    weak var delegate: PinCodeViewControllerDelegate?

    private lazy var pinCodeView: PinCodeView = .init()
    private let contentView = UIView()
    private let unlockManager: UnlockManager

    init(unlockManager: UnlockManager,
         viewModel: PinCodeViewModel,
         delegate: PinCodeViewControllerDelegate?) {
        self.unlockManager = unlockManager
        self.viewModel = viewModel
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = self.contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        view.backgroundColor = ColorProvider.BackgroundNorm

        self.setUpView(true)
        self.setupPinCodeView()
        self.subscribeToWillEnterForegroundMessage()

        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.pinCodeView.resetPin()
        }
        generateAccessibilityIdentifiers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.view.layoutIfNeeded()

        if self.viewModel.checkTouchID() {
            if userCachedStatus.isTouchIDEnabled {
                self.decideOnBioAuthentication()
            }
        }

        if self.viewModel.getPinFailedRemainingCount() < 4 {
            self.pinCodeView.showAttemptError(self.viewModel.getPinFailedError(), low: true)
        }
    }

    private func setupPinCodeView() {
        self.pinCodeView.delegate = self
        self.contentView.addSubview(self.pinCodeView)
        [
            self.pinCodeView.topAnchor.constraint(equalTo: self.contentView.safeAreaLayoutGuide.topAnchor),
            self.pinCodeView.trailingAnchor.constraint(equalTo: self.contentView.safeAreaLayoutGuide.trailingAnchor),
            self.pinCodeView.leadingAnchor.constraint(equalTo: self.contentView.safeAreaLayoutGuide.leadingAnchor),
            self.pinCodeView.bottomAnchor.constraint(equalTo: self.contentView.safeAreaLayoutGuide.bottomAnchor),
        ].activate()

    }

    func setUpView(_ reset: Bool) {
        self.pinCodeView.updateViewText(cancelText: self.viewModel.cancel(),
                                        resetPin: reset)
        self.pinCodeView.updateBackButton(self.viewModel.backButtonIcon())
    }
}

extension PinCodeViewController: BioAuthenticating {
    func authenticateUser() {
        unlockManager.biometricAuthentication(afterBioAuthPassed: {
            self.viewModel.done { shouldPop in
                self.delegate?.next()
                if shouldPop {
                    _ = self.navigationController?.popViewController(animated: true)
                }
            }
        })
    }
}

extension PinCodeViewController: PinCodeViewDelegate {
    func cancel() {
        guard self.viewModel.needsLogoutConfirmation() else {
            self.proceedCancel()
            return
        }

        let alert = UIAlertController(title: nil, message: LocalString._signout_secondary_account_from_manager_account, preferredStyle: .alert)
        alert.addAction(.init(title: LocalString._sign_out, style: .destructive, handler: self.proceedCancel))
        alert.addAction(.init(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    private func proceedCancel(_ sender: Any? = nil) {
        guard let _delegate = self.delegate else {
            // Pin code settings
            self.navigationController?.popViewController(animated: true)
            return
        }
        // unlock when app launch
        _ = _delegate.cancel {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }

    func next(_ code: String) {
        if code.isEmpty {
            let alert = LocalString._pin_code_cant_be_empty.alertController()
            alert.addOKAction()
            self.present(alert, animated: true, completion: nil)
        } else {
            let step: PinCodeStep = self.viewModel.setCode(code)
            if step != .done {
                self.setUpView(true)
            } else {
                self.viewModel.isPinMatched { matched in
                    if matched {
                        self.pinCodeView.hideAttemptError(true)
                        self.viewModel.done { shouldPop in
                            self.delegate?.next()
                            if shouldPop {
                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                    } else {
                        let count = self.viewModel.getPinFailedRemainingCount()
                        if count == 11 { // when setup
                            self.pinCodeView.resetPin()
                            self.pinCodeView.showAttemptError(self.viewModel.getPinFailedError(), low: false)
                        } else if count < 10 {
                            if count <= 0 {
                                self.proceedCancel()
                            } else {
                                self.pinCodeView.resetPin()
                                self.pinCodeView.showAttemptError(self.viewModel.getPinFailedError(), low: count < 4)
                            }
                        }
                        self.pinCodeView.showError()
                    }
                }
            }
        }
    }
}
