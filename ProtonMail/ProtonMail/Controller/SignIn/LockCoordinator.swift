//
//  LockCoordinator.swift
//  ProtonMail
//
//  Created by Krzysztof Siejkowski on 23/04/2021.
//  Copyright © 2021 ProtonMail. All rights reserved.
//

import UIKit
import PromiseKit

final class LockCoordinator: DefaultCoordinator {

    enum FlowResult {
        case signIn(reason: String)
        case mailboxPassword
        case mailbox
    }

    typealias VC = CoordinatorKeepingViewController<LockCoordinator>

    let services: ServiceFactory
    let unlockManager: UnlockManager
    let usersManager: UsersManager
    var startedOrSheduledForAStart: Bool = false

    weak var viewController: VC?

    var actualViewController: VC { viewController ?? makeViewController() }

    let finishLockFlow: (FlowResult) -> Void

    init(services: ServiceFactory, finishLockFlow: @escaping (FlowResult) -> Void) {
        self.services = services
        self.unlockManager = services.get(by: UnlockManager.self)
        self.usersManager = services.get(by: UsersManager.self)

        // explanation: boxing stopClosure to avoid referencing self before initialization is finished
        var stopClosure = { }
        self.finishLockFlow = { result in
            stopClosure()
            finishLockFlow(result)
        }
        stopClosure = { [weak self] in self?.stop() }
    }

    private func makeViewController() -> VC {
        let vc = VC(coordinator: self, backgroundColor: .white)
        vc.view = UINib(nibName: "LaunchScreen", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView
        vc.restorationIdentifier = "Lock"
        viewController = vc
        return vc
    }

    func start() {
        startedOrSheduledForAStart = true
        let unlockFlow = unlockManager.getUnlockFlow()
        switch unlockFlow {
        case .requirePin:
            goToPin()
        case .requireTouchID:
            goToTouchId()
        case .restore:
            finishLockFlow(.signIn(reason: "unlockFlow: \(unlockFlow)"))
        }
    }

    func stop() {
        delegate?.willStop(in: self)
        startedOrSheduledForAStart = false
        delegate?.didStop(in: self)
    }

    private func goToPin() {
        if actualViewController.presentedViewController is PinCodeViewController { return }
        let pinVC = PinCodeViewController(unlockManager: UnlockManager.shared,
                                          viewModel: UnlockPinCodeModelImpl(),
                                          delegate: self)
        pinVC.modalPresentationStyle = .fullScreen
        actualViewController.present(pinVC, animated: true, completion: nil)
    }

    private func goToTouchId() {
        if (actualViewController.presentedViewController as? UINavigationController)?.viewControllers.first is BioCodeViewController { return }
        let bioCodeVC = BioCodeViewController(unlockManager: UnlockManager.shared,
                                              delegate: self)
        let navigationVC = UINavigationController(rootViewController: bioCodeVC)
        navigationVC.modalPresentationStyle = .fullScreen
        actualViewController.present(navigationVC, animated: true, completion: nil)
    }
}

// copied from old implementation of SignInViewController to keep the pin logic untact
extension LockCoordinator: PinCodeViewControllerDelegate {

    func next() {
        unlockManager.unlockIfRememberedCredentials(requestMailboxPassword: { [weak self] in
            self?.finishLockFlow(.mailboxPassword)
        }, unlockFailed: { [weak self] in
            self?.finishLockFlow(.signIn(reason: "unlock failed"))
        }, unlocked: { [weak self] in
            self?.finishLockFlow(.mailbox)
        })
    }

    func cancel(completion: @escaping () -> Void) {
        UserTempCachedStatus.backup()
        _ = self.usersManager.clean().done { [weak self] in
            completion()
            self?.finishLockFlow(.signIn(reason: "PinCodeViewControllerDelegate.cancel"))
        }
    }
}
