//
//  LockCoordinator.swift
//  ProtonMail
//
//  Created by Krzysztof Siejkowski on 23/04/2021.
//  Copyright © 2021 ProtonMail. All rights reserved.
//

import Foundation
import PromiseKit

final class LockCoordinator: DefaultCoordinator {

    enum FlowResult {
        case signIn
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
        switch unlockManager.getUnlockFlow() {
        case .requirePin:
            goToPin()
        case .requireTouchID:
            goToTouchId()
        case .restore:
            finishLockFlow(.signIn)
        }
    }

    func stop() {
        delegate?.willStop(in: self)
        startedOrSheduledForAStart = false
        delegate?.didStop(in: self)
    }

    private func goToPin() {
        if actualViewController.presentedViewController is PinCodeViewController { return }
        let pinVC = UIStoryboard.Storyboard.signIn.storyboard.make(PinCodeViewController.self)
        pinVC.viewModel = UnlockPinCodeModelImpl()
        pinVC.delegate = self
        pinVC.modalPresentationStyle = .fullScreen
        actualViewController.present(pinVC, animated: true, completion: nil)
    }

    private func goToTouchId() {
        if actualViewController.presentedViewController is BioCodeViewController { return }
        let bioCodeVC = UIStoryboard.Storyboard.signIn.storyboard.make(BioCodeViewController.self)
        bioCodeVC.delegate = self
        bioCodeVC.modalPresentationStyle = .fullScreen
        actualViewController.present(bioCodeVC, animated: true, completion: nil)
    }
}

// copied from old implementation of SignInViewController to keep the pin logic untact
extension LockCoordinator: PinCodeViewControllerDelegate {

    func Next() {
        unlockManager.unlockIfRememberedCredentials(requestMailboxPassword: { [weak self] in
            self?.finishLockFlow(.mailboxPassword)
        }, unlockFailed: { [weak self] in
            self?.finishLockFlow(.signIn)
        }, unlocked: { [weak self] in
            self?.finishLockFlow(.mailbox)
        })
    }

    func Cancel() -> Promise<Void> {
        return Promise { [weak self] seal in
            UserTempCachedStatus.backup()
            _ = self?.usersManager.clean().done { [weak self] in
                seal.fulfill_()
                self?.finishLockFlow(.signIn)
            }
        }
    }
}
