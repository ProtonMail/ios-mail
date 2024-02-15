//
//  LockCoordinator.swift
//  Proton Mail
//
//  Created by Krzysztof Siejkowski on 23/04/2021.
//  Copyright © 2021 Proton Mail. All rights reserved.
//

import LifetimeTracker
import PromiseKit
import ProtonMailAnalytics

final class LockCoordinator: LifetimeTrackable {
    enum FlowResult {
        case signIn
        case mailboxPassword
        case mailbox
        case signOut
    }

    typealias Dependencies = UnlockPinCodeModelImpl.Dependencies 
    & HasUsersManager
    & HasUnlockManager
    & HasUnlockService

    typealias VC = CoordinatorKeepingViewController<LockCoordinator>

    class var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }

    var startedOrScheduledForAStart: Bool = false

    private weak var viewController: VC?

    var actualViewController: VC { viewController ?? makeViewController() }

    private let finishLockFlow: (FlowResult) -> Void

    private let dependencies: Dependencies

    init(dependencies: Dependencies, finishLockFlow: @escaping (FlowResult) -> Void) {
        self.dependencies = dependencies
        // explanation: boxing stopClosure to avoid referencing self before initialization is finished
        var stopClosure = { }
        self.finishLockFlow = { result in
            stopClosure()
            finishLockFlow(result)
        }
        stopClosure = { [weak self] in self?.stop() }
        trackLifetime()
    }

    private func makeViewController() -> VC {
        let vc = VC(coordinator: self, backgroundColor: .white)
        vc.view = UINib(nibName: "LaunchScreen", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView
        vc.restorationIdentifier = "Lock"
        viewController = vc
        return vc
    }

    func start() {
        startedOrScheduledForAStart = true
        self.actualViewController.presentedViewController?.dismiss(animated: true)
        let unlockFlow = dependencies.unlockManager.getUnlockFlow()
        switch unlockFlow {
        case .requirePin:
            goToPin()
        case .requireTouchID:
            goToTouchId()
        case .restore:
            finishLockFlow(.signIn)
        }
    }

    private func stop() {
        startedOrScheduledForAStart = false
    }

    private func goToPin() {
        if actualViewController.presentedViewController is PinCodeViewController { return }
        let pinVC = PinCodeViewController(unlockManager: dependencies.unlockManager,
                                          viewModel: UnlockPinCodeModelImpl(dependencies: dependencies),
                                          delegate: self)
        pinVC.modalPresentationStyle = .fullScreen
        actualViewController.present(pinVC, animated: true, completion: nil)
    }

    private func goToTouchId() {
        if (actualViewController.presentedViewController as? UINavigationController)?.viewControllers.first is BioCodeViewController { return }
        let bioCodeVC = BioCodeViewController(unlockManager: dependencies.unlockManager, delegate: self)
        let navigationVC = UINavigationController(rootViewController: bioCodeVC)
        navigationVC.modalPresentationStyle = .fullScreen
        actualViewController.present(navigationVC, animated: true, completion: nil)
    }
}

// copied from old implementation of SignInViewController to keep the pin logic untact
extension LockCoordinator: PinCodeViewControllerDelegate {

    func onUnlockChallengeSuccess() {
        Task {
            let appAccess = await dependencies.unlockService.start()
            guard appAccess == .accessGranted else {
                await finishUnlockFlowAppAccessDenied()
                return
            }
            await finishUnlockFlowSuccess()
        }
    }

    @MainActor
    private func finishUnlockFlowSuccess() {
        finishLockFlow(.mailbox)
        actualViewController.presentedViewController?.dismiss(animated: true)
    }

    @MainActor
    private func finishUnlockFlowAppAccessDenied() {
        finishLockFlow(.signIn)
    }

    func cancel(completion: @escaping () -> Void) {
        /*
         If the user logs out from the unlock screen before unlocking the app, Core Data will not be set up when `clean()` is called, and the app will crash.

         Therefore we need to set up Core Data now.

         Note: calling `setupCoreData` before the main key is available might break the migration process, but it doesn't matter in this particular case, because we're going to clean the DB anyway.
         */
        do {
            try dependencies.unlockManager.delegate?.setupCoreData()
        } catch {
            fatalError("\(error)")
        }

        _ = dependencies.usersManager.clean().done { [weak self] in
            completion()
            self?.finishLockFlow(.signOut)
        }
    }
}
