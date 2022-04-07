//
//  SharePinUnlockViewController.swift
//  Share - Created on 7/26/17.
//
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

import ProtonCore_UIFoundations
import UIKit

protocol SharePinUnlockViewControllerDelegate: AnyObject {
    func cancel()
    func next()
}

class SharePinUnlockViewController: UIViewController, CoordinatedNew {
    typealias coordinatorType = SharePinUnlockCoordinator

    @IBOutlet weak var pinCodeViewContainer: UIView!
    private weak var coordinator: SharePinUnlockCoordinator?
    var viewModel: PinCodeViewModel!
    weak var delegate: SharePinUnlockViewControllerDelegate?
    lazy var pinCodeView = PinCodeView(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.layoutIfNeeded()
        setupPinCodeView()
        self.view.backgroundColor = ColorProvider.BackgroundNorm
        self.setUpView(true)

        if #available(iOSApplicationExtension 13.0, *) {
            self.isModalInPresentation = true
        }
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
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    func set(coordinator: SharePinUnlockCoordinator) {
        self.coordinator = coordinator
    }

    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }

    private func setUpView(_ reset: Bool) {
        self.pinCodeView.updateViewText(cancelText: self.viewModel.cancel(), resetPin: reset)
    }

    private func setupPinCodeView() {
        pinCodeViewContainer.addSubview(pinCodeView)
        [
            pinCodeView.topAnchor.constraint(equalTo: self.pinCodeViewContainer.safeAreaLayoutGuide.topAnchor),
            pinCodeView.trailingAnchor.constraint(equalTo: self.pinCodeViewContainer.safeAreaLayoutGuide.trailingAnchor),
            pinCodeView.leadingAnchor.constraint(equalTo: self.pinCodeViewContainer.safeAreaLayoutGuide.leadingAnchor),
            pinCodeView.bottomAnchor.constraint(equalTo: self.pinCodeViewContainer.safeAreaLayoutGuide.bottomAnchor),
        ].activate()
        pinCodeView.delegate = self
    }
}

extension SharePinUnlockViewController: PinCodeViewDelegate {
    func cancel() {
        // TODO: use the coordinator delegated
        self.dismiss(animated: true) {
            self.delegate?.cancel()
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
                        self.viewModel.done { _ in
                            self.dismiss(animated: true, completion: {
                                self.delegate?.next()
                            })
                        }
                    } else {
                        let count = self.viewModel.getPinFailedRemainingCount()
                        if count == 11 { // when setup
                            self.pinCodeView.resetPin()
                            self.pinCodeView.showAttemptError(self.viewModel.getPinFailedError(), low: false)
                        } else if count < 10 {
                            if count <= 0 {
                                self.cancel()
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
