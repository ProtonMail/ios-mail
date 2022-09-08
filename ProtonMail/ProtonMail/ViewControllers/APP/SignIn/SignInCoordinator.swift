//
//  SignInCoordinator.swift
//  Proton Mail - Created on 23/04/2021
//
//  Copyright (c) 2021 Proton AG
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

import PromiseKit
import ProtonCore_DataModel
import ProtonCore_Login
import ProtonCore_LoginUI
import ProtonCore_Networking
import class ProtonCore_Services.APIErrorCode

// swiftlint:disable type_body_length
final class SignInCoordinator {
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
            case .fetchingSettingsFailed(let error), .finalizingSignInFailed(let error):
                return error.localizedDescription
            case .mailboxPasswordRetrievalRequired, .unlockFailed:
                return nil
            }
        }

        var failureReason: String? {
            switch self {
            case .fetchingSettingsFailed(let error), .finalizingSignInFailed(let error):
                return (error as NSError).localizedFailureReason
            case .mailboxPasswordRetrievalRequired, .unlockFailed:
                return nil
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .fetchingSettingsFailed(let error), .finalizingSignInFailed(let error):
                return (error as NSError).localizedRecoverySuggestion
            case .mailboxPasswordRetrievalRequired, .unlockFailed:
                return nil
            }
        }

        var helpAnchor: String? {
            switch self {
            case .fetchingSettingsFailed(let error), .finalizingSignInFailed(let error):
                return (error as NSError).helpAnchor
            case .mailboxPasswordRetrievalRequired, .unlockFailed:
                return nil
            }
        }
    }

    typealias VC = CoordinatorKeepingViewController<SignInCoordinator>

    weak var viewController: VC?

    var actualViewController: VC { viewController ?? makeViewController() }

    let startingPoint: WindowsCoordinator.Destination.SignInDestination

    weak var delegate: SignInCoordinatorDelegate?

    private var isStarted = false

    private let environment: SignInCoordinatorEnvironment
    private var login: LoginAndSignupInterface?
    private let username: String?
    private let isFirstAccountFlow: Bool
    private let onFinish: (FlowResult) -> Void
    private var loginData: LoginData?

    static func loginFlowForFirstAccount(startingPoint: WindowsCoordinator.Destination.SignInDestination,
                                         environment: SignInCoordinatorEnvironment,
                                         onFinish: @escaping (FlowResult) -> Void) -> SignInCoordinator {
        .init(username: nil,
              isFirstAccountFlow: true,
              startingPoint: startingPoint,
              environment: environment,
              onFinish: onFinish)
    }

    static func loginFlowForSecondAndAnotherAccount(username: String?,
                                                    environment: SignInCoordinatorEnvironment,
                                                    onFinish: @escaping (FlowResult) -> Void) -> SignInCoordinator {
        .init(username: username,
              isFirstAccountFlow: false,
              startingPoint: .form,
              environment: environment,
              onFinish: onFinish)
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

        // explanation: boxing stopClosure to avoid referencing self before initialization is finished
        var stopClosure = {}
        self.onFinish = {
            stopClosure()
            onFinish($0)
        }
        stopClosure = { [weak self] in self?.stop() }
        self.initLogin()
    }

    private func initLogin() {
        login = environment.loginCreationClosure(LocalString._protonmail,
                                                 .internal,
                                                 .internal,
                                                 [.notEmpty, .atLeastEightCharactersLong],
                                                 !isFirstAccountFlow)
    }

    private func makeViewController() -> VC {
        let view = VC(coordinator: self, backgroundColor: isFirstAccountFlow ? .white : .clear)
        if isFirstAccountFlow {
            view.view = UINib(nibName: "LaunchScreen", bundle: nil)
                .instantiate(withOwner: nil, options: nil).first as? UIView
        }
        view.restorationIdentifier = "SignIn-\(startingPoint.rawValue.capitalized)"
        viewController = view
        return view
    }

    func start() {
        guard isStarted == false else { return }
        isStarted = true
        if login == nil {
            initLogin()
        }

        switch startingPoint {
        case .form:
            let customization = LoginCustomizationOptions(username: username)
            login?.presentLoginFlow(over: actualViewController,
                                    customization: customization,
                                    updateBlock: { [weak self] in
                                        self?.processLoginAndSignupResult($0)
                                    })
        case .mailboxPassword:
            self.login?.presentMailboxPasswordFlow(over: actualViewController) { [weak self] in
                self?.processMailboxPasswordInCleartext($0)
                self?.login = nil
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
        self.login = nil
        isStarted = false
        delegate?.didStop()
    }

    private func processLoginAndSignupResult(_ result: LoginAndSignupResult) {
        switch result {
        case .dismissed:
            onFinish(.dismissed)
        case .loginStateChanged(let loginState):
            processLoginState(loginState)
        case .signupStateChanged(let signupState):
            processSignupState(signupState)
        }
    }

    private func processLoginState(_ loginState: LoginState) {
        switch loginState {
        case .dataIsAvailable(let loginData):
            self.loginData = loginData
            self.saveLoginData(loginData: loginData)
        case .loginFinished:
            if let loginData = loginData {
                finalizeLoginSignInProcess(loginData)
            }
            login = nil
        }
    }

    private func processSignupState(_ signupState: SignupState) {
        switch signupState {
        case .dataIsAvailable(let loginData):
            self.loginData = loginData
            self.saveLoginData(loginData: loginData)
        case .signupFinished:
            if let loginData = loginData {
                finalizeLoginSignInProcess(loginData)
            }
            login = nil
        }
    }

    private func saveLoginData(loginData: LoginData) {
        let savingResult = environment.saveLoginData(loginData)
        switch savingResult {
        case .success:
            break
        case .freeAccountsLimitReached:
            self.loginData = nil
            processReachLimitError()
        case .errorOccurred:
            self.loginData = nil
            self.processExistError()
        }
    }

    private func finalizeLoginSignInProcess(_ loginData: LoginData) {
        environment.finalizeSignIn(loginData: loginData,
                                   onError: { [weak self] error in
                                       self?.handleRequestError(error, wrapIn: FlowError.finalizingSignInFailed)
                                   },
                                   reachLimit: { [weak self] in
                                       self?.processReachLimitError()
                                   },
                                   existError: { [weak self] in
                                       self?.processExistError()
                                   },
                                   showSkeleton: { [weak self] in
                                       self?.showSkeletonTemplate()
                                   },
                                   tryUnlock: { [weak self] in
                                       self?.unlockMainKey(failOnMailboxPassword: false)
                                   })
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

    private func showSkeletonTemplate() {
        let link = DeepLink(.skeletonTemplate, sender: String(describing: SignInCoordinator.self))
        NotificationCenter.default.post(name: .switchView, object: link)
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
        let isForceUpdate = nsError.code == APIErrorCode.badAppVersion
        if !self.checkDoh(nsError, wrapIn: flowError), !isForceUpdate {
            let alertController = nsError.alertController()
            showAlertAndFinish(controller: alertController, result: .errored(flowError(error)))
        }
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
        guard environment.doh
            .errorIndicatesDoHSolvableProblem(error: error) else { return false }

        let result: FlowResult = .errored(flowError(error as Error))
        guard environment.shouldShowAlertOnError else { onFinish(result); return true }

        // TODO: don't use FailureReason in the future. also need clean up
        let message = error.localizedFailureReason ?? error.localizedDescription
        let alertController = UIAlertController(title: LocalString._protonmail,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(
            UIAlertAction(title: "Troubleshoot", style: .default) { [weak self] _ in
                self?.onFinish(.userWantsToGoToTroubleshooting)
            }
        )
        alertController.addAction(
            UIAlertAction(title: LocalString._general_cancel_button, style: .cancel) { [weak self] _ in
                self?.onFinish(result)
            }
        )
        DispatchQueue.main.async {
            UIApplication.shared.keyWindow?.rootViewController?
                .present(alertController, animated: true, completion: nil)
        }

        return true
    }
}

protocol SignInCoordinatorDelegate: AnyObject {
    func didStop()
}
