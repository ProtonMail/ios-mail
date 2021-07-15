//
//  SignInCoordinator.swift
//  ProtonMail - Created on 23/04/2021
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

import PromiseKit
import ProtonCore_DataModel
import ProtonCore_Login
import ProtonCore_Networking

final class SignInCoordinator: DefaultCoordinator {

    enum FlowResult {
        case succeeded
        case dismissed
        case alreadyLoggedIn
        case loggedInFreeAccountsLimitReached
        case userWantsToGoToTroubleshooting
        case errored(FlowError)
    }

    enum FlowError: LocalizedError {
        case fetchingSettingsFailed(Error)
        case finalizingSignInFailed(Error)
        case mailboxPasswordRetrievalRequired
        case unlockFailed

        var errorDescription: String? {
            switch self {
            case .fetchingSettingsFailed(let error), .finalizingSignInFailed(let error): return error.localizedDescription
            case .mailboxPasswordRetrievalRequired, .unlockFailed: return nil
            }
        }
        var failureReason: String? {
            switch self {
            case .fetchingSettingsFailed(let error), .finalizingSignInFailed(let error): return (error as NSError).localizedFailureReason
            case .mailboxPasswordRetrievalRequired, .unlockFailed: return nil
            }
        }
        var recoverySuggestion: String? {
            switch self {
            case .fetchingSettingsFailed(let error), .finalizingSignInFailed(let error): return (error as NSError).localizedRecoverySuggestion
            case .mailboxPasswordRetrievalRequired, .unlockFailed: return nil
            }
        }
        var helpAnchor: String? {
            switch self {
            case .fetchingSettingsFailed(let error), .finalizingSignInFailed(let error): return (error as NSError).helpAnchor
            case .mailboxPasswordRetrievalRequired, .unlockFailed: return nil
            }
        }
    }
    
    typealias VC = CoordinatorKeepingViewController<SignInCoordinator>

    weak var viewController: VC?

    var actualViewController: VC { viewController ?? makeViewController() }

    let startingPoint: WindowsCoordinator.Destination.SignInDestination

    var services: ServiceFactory { environment.services }
    weak var delegate: CoordinatorDelegate?
    private var isStarted = false

    private let environment: SignInCoordinatorEnvironment
    private let login: LoginInterface
    private let username: String?
    private let isFirstAccountFlow: Bool
    private let onFinish: (FlowResult) -> Void
    
    static func loginFlowForFirstAccount(startingPoint: WindowsCoordinator.Destination.SignInDestination,
                                         environment: SignInCoordinatorEnvironment,
                                         onFinish: @escaping (FlowResult) -> Void) -> SignInCoordinator {
        .init(username: nil, isFirstAccountFlow: true, startingPoint: startingPoint, environment: environment, onFinish: onFinish)
    }
    
    static func loginFlowForSecondAndAnotherAccount(username: String?,
                                                    environment: SignInCoordinatorEnvironment,
                                                    onFinish: @escaping (FlowResult) -> Void) -> SignInCoordinator {
        .init(username: username, isFirstAccountFlow: false, startingPoint: .form, environment: environment, onFinish: onFinish)
    }
    
    private init(username: String?,
                 isFirstAccountFlow: Bool,
                 startingPoint: WindowsCoordinator.Destination.SignInDestination,
                 environment: SignInCoordinatorEnvironment,
                 onFinish: @escaping (FlowResult) -> Void) {
        self.username = username
        self.isFirstAccountFlow = isFirstAccountFlow
        self.startingPoint = startingPoint
        self.environment = environment
        // TODO: what is the right setup here? also — should the name be taken from somewhere instead of hardcoded?
        login = environment.loginCreationClosure("Proton Mail",
                                                 .internal,
                                                 .internal,
                                                 [.notEmpty, .atLeastEightCharactersLong],
                                                 !isFirstAccountFlow)

        // explanation: boxing stopClosure to avoid referencing self before initialization is finished
        var stopClosure = { }
        self.onFinish = {
            stopClosure()
            onFinish($0)
        }
        stopClosure = { [weak self] in self?.stop() }
    }

    private func makeViewController() -> VC {
        let vc = VC(coordinator: self, backgroundColor: isFirstAccountFlow ? .white : .clear)
        if isFirstAccountFlow {
            vc.view = UINib(nibName: "LaunchScreen", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView
        }
        vc.restorationIdentifier = "SignIn-\(startingPoint.rawValue.capitalized)"
        viewController = vc
        return vc
    }

    func start() {
        guard isStarted == false else { return }
        isStarted = true
        switch startingPoint {
        case .form:
            login.presentLoginFlow(over: actualViewController, username: username) { [weak self] in
                self?.processLoginResult($0)
            }
        case .mailboxPassword:
            login.presentMailboxPasswordFlow(over: actualViewController) { [weak self] in
                self?.processMailboxPasswordInCleartext($0)
            }
        }
    }

    private func processMailboxPasswordInCleartext(_ password: String) {
        if environment.currentAuth() == nil {
            environment.tryRestoringPersistedUser()
        }
        guard let auth = environment.currentAuth() else {
            onFinish(.errored(.unlockFailed))
            return
        }
        let encryptedPassword = environment.mailboxPassword(password, auth)
        if encryptedPassword != password {
            auth.udpate(password: encryptedPassword)
        }
        unlockMainKey(failOnMailboxPassword: true)
    }

    func stop() {
        guard isStarted == true else { return }
        delegate?.willStop(in: self)
        isStarted = false
        delegate?.didStop(in: self)
    }

    private func processLoginResult(_ result: LoginResult) {
        switch result {
        case .dismissed:
            onFinish(.dismissed)

        case .loggedIn(let loginData):
            environment.finalizeSignIn(loginData: loginData) { [weak self] error in
                self?.handleRequestError(error, wrapIn: FlowError.finalizingSignInFailed)
            } reachLimit: {
                [weak self] in self?.processReachLimitError()
            } existError: {
                [weak self] in self?.processExistError()
            } tryUnlock: {
                [weak self] in self?.unlockMainKey(failOnMailboxPassword: false)
            }
        }
    }

    private func processReachLimitError() {
        let alertController = UIAlertController(title: LocalString._free_account_limit_reached_title,
                                                message: LocalString._free_account_limit_reached,
                                                preferredStyle: .alert)
        showAlertAndFinish(controller: alertController, result: .loggedInFreeAccountsLimitReached)
    }

    private func processExistError() {
        let alertController = LocalString._duplicate_logged_in.alertController()
        showAlertAndFinish(controller: alertController, result: .alreadyLoggedIn)
    }

    private func unlockMainKey(failOnMailboxPassword: Bool) {
        environment.unlockIfRememberedCredentials(
            forUser: username,
            requestMailboxPassword: { [weak self] in
                assertionFailure("should never happen: the password should be provided by login module")
                let error: FlowError
                if failOnMailboxPassword {
                    error = .unlockFailed
                } else {
                    error = .mailboxPasswordRetrievalRequired
                }
                self?.handleRequestError(error, wrapIn: { _ in error })
            },
            unlockFailed: { [weak self] in
                let error = FlowError.unlockFailed
                self?.handleRequestError(error, wrapIn: { _ in error })
            },
            unlocked: { [weak self] in
                self?.onFinish(.succeeded)
            }
        )
    }
    
    // copied from old implementation of SignInViewController to keep the error presentation untact
    private func handleRequestError(_ error: Error, wrapIn flowError: (Error) -> FlowError) {
        let nsError = error as NSError
        let code = nsError.code
        if !self.checkDoh(nsError, wrapIn: flowError) && !code.forceUpgrade {
            let alertController = nsError.alertController()
            showAlertAndFinish(controller: alertController, result: .errored(flowError(error)))
        }
        PMLog.D("error: \(error)")
    }

    private func showAlertAndFinish(controller alertController: UIAlertController, result: FlowResult) {
        guard environment.shouldShowAlertOnError else { onFinish(result); return }

        alertController.addOKAction { [weak self] _ in
            self?.onFinish(result)
        }
        DispatchQueue.main.async {
            self.viewController?.present(alertController, animated: true, completion: nil)
        }
    }

    private func checkDoh(_ error: NSError, wrapIn flowError: (Error) -> FlowError) -> Bool {
        let code = error.code

        guard environment.doh.codeCheck(code: code) else { return false }

        let result: FlowResult = .errored(flowError(error as Error))
        guard environment.shouldShowAlertOnError else { onFinish(result); return true }
        
        //TODO:: don't use FailureReason in the future. also need clean up
        let message = error.localizedFailureReason ?? error.localizedDescription
        let alertController = UIAlertController(title: LocalString._protonmail, message: message, preferredStyle: .alert)
        alertController.addAction(
            UIAlertAction(title: "Troubleshoot", style: .default) { [weak self] action in
                self?.onFinish(.userWantsToGoToTroubleshooting)
            }
        )
        alertController.addAction(
            UIAlertAction(title: LocalString._general_cancel_button, style: .cancel) { [weak self] action in
                self?.onFinish(result)
            }
        )
        DispatchQueue.main.async {
            UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
        }
        
        return true
    }
}
