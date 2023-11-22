//
//  SharePinUnlockViewController.swift
//  Share - Created on 7/26/17.
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

import ProtonCoreUIFoundations
import UIKit

protocol SharePinUnlockViewControllerDelegate: AnyObject {
    func onUnlockChallengeSuccess()
    func cancel()
}

class SharePinUnlockViewController: UIViewController {
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

            self.isModalInPresentation = true
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
            let step: PinCodeStep = viewModel.setCode(code)
            if step != .done {
                setUpView(true)
            } else {
                verifyPinCode()
            }
        }
    }

    private func verifyPinCode() {
        Task {
            let isVerified = await viewModel.verifyPinCode()
            updateView(verificationResult: isVerified)
        }
    }

    @MainActor
    private func updateView(verificationResult isPinCodeVerified: Bool) {
        if isPinCodeVerified {
            pinCodeView.hideAttemptError(true)
            viewModel.done { [unowned self] _ in
                self.dismiss(animated: true, completion: {
                    self.delegate?.onUnlockChallengeSuccess()
                })
            }
        } else {
            let count = viewModel.getPinFailedRemainingCount()
            if count == 11 { // when setup
                pinCodeView.resetPin()
                pinCodeView.showAttemptError(self.viewModel.getPinFailedError(), low: false)
            } else if count < 10 {
                if count <= 0 {
                    cancel()
                } else {
                    pinCodeView.resetPin()
                    pinCodeView.showAttemptError(self.viewModel.getPinFailedError(), low: count < 4)
                }
            }
            pinCodeView.showError()
        }
    }
}
