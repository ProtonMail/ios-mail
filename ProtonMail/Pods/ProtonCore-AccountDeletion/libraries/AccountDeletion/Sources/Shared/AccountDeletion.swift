//
//  AccountDeletion.swift
//  ProtonCore-AccountDeletion - Created on 10.12.21.
//
//  Copyright (c) 2022 Proton Technologies AG
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

import Foundation

#if canImport(ProtonCoreAuthentication)
import ProtonCoreAuthentication
#else
import PMAuthentication
#endif
#if canImport(ProtonCoreNetworking)
import ProtonCoreNetworking
#else
import PMCommon
#endif
#if canImport(ProtonCoreDoh)
import ProtonCoreDoh
#endif
#if canImport(ProtonCoreServices)
import ProtonCoreServices
#endif
import ProtonCoreUIFoundations

public typealias AccountDeletionSuccess = Void

#if canImport(ProtonCoreNetworking)
public typealias CannotDeleteYourselfReasonError = ResponseError
#else
public typealias CannotDeleteYourselfReasonError = Error
extension Error {
    var networkResponseMessageForTheUser: String {
        localizedDescription
    }
}
#endif

public enum AccountDeletionError: Error {
    case cannotDeleteYourself(becauseOf: CannotDeleteYourselfReasonError)
    case sessionForkingError(message: String)
    case closedByUser
    case deletionFailure(message: String)
    case apiMightBeBlocked(message: String, originalError: Error)
    
    public var userFacingMessageInAccountDeletion: String {
        switch self {
        case .cannotDeleteYourself(let error): return error.localizedDescription
        case .sessionForkingError(let message): return message
        case .closedByUser: return ""
        case .deletionFailure(let message): return message
        case .apiMightBeBlocked(let message, _): return message
        }
    }
}

public protocol AccountDeletion {
    associatedtype ViewController
    
    func initiateAccountDeletionProcess(
        over viewController: ViewController,
        inAppTheme: @escaping () -> InAppTheme,
        performAfterShowingAccountDeletionScreen: @escaping () -> Void,
        performBeforeClosingAccountDeletionScreen: @escaping (@escaping () -> Void) -> Void,
        completion: @escaping (Result<AccountDeletionSuccess, AccountDeletionError>) -> Void
    )
}

public extension AccountDeletion {
    func initiateAccountDeletionProcess(
        over viewController: ViewController,
        performAfterShowingAccountDeletionScreen: @escaping () -> Void,
        performBeforeClosingAccountDeletionScreen: @escaping (@escaping () -> Void) -> Void,
        completion: @escaping (Result<AccountDeletionSuccess, AccountDeletionError>) -> Void
    ) {
        initiateAccountDeletionProcess(over: viewController,
                                       inAppTheme: { .default },
                                       performAfterShowingAccountDeletionScreen: performAfterShowingAccountDeletionScreen,
                                       performBeforeClosingAccountDeletionScreen: performBeforeClosingAccountDeletionScreen,
                                       completion: completion)
    }
}

#if canImport(ProtonCoreServices)
public extension AccountDeletion {
    static var defaultButtonName: String {
        ADTranslation.delete_account_button.l10n
    }
    
    static var defaultExplanationMessage: String {
        ADTranslation.delete_account_message.l10n
    }
}
#endif

final class CanDeleteRequest: Request {
    let path: String = "/core/v4/users/delete"
    let method: HTTPMethod = .get
    let isAuth: Bool = true
}

final class CanDeleteResponse: Response {}

public final class AccountDeletionService {
    
    private let api: APIService
    private let doh: DoHInterface
    private let authenticator: Authenticator
    private let preferredLanguage: String

    #if canImport(ProtonCoreServices)
    public convenience init(api: APIService, preferredLanguage: String = NSLocale.autoupdatingCurrent.identifier) {
        self.init(api: api, doh: api.dohInterface, preferredLanguage: preferredLanguage)
    }
    #endif
    
    @available(*, deprecated, message: "this will be removed. use initializer with doh: DoHInterface type")
    init(api: APIService, doh: DoHInterface & ServerConfig, preferredLanguage: String = NSLocale.autoupdatingCurrent.identifier) {
        self.api = api
        self.doh = doh
        self.preferredLanguage = preferredLanguage
        self.authenticator = Authenticator(api: api)
    }
    
    init(api: APIService, doh: DoHInterface, preferredLanguage: String = NSLocale.autoupdatingCurrent.identifier) {
        self.api = api
        self.doh = doh
        self.preferredLanguage = preferredLanguage
        self.authenticator = Authenticator(api: api)
    }

    func initiateAccountDeletionProcess(
        presenter viewController: AccountDeletionViewControllerPresenter,
        inAppTheme: @escaping () -> InAppTheme = { .default },
        performAfterShowingAccountDeletionScreen: @escaping () -> Void = { },
        performBeforeClosingAccountDeletionScreen: @escaping (@escaping () -> Void) -> Void = { $0() },
        completion: @escaping (Result<AccountDeletionSuccess, AccountDeletionError>) -> Void
    ) {
        api.perform(request: CanDeleteRequest(), response: CanDeleteResponse()) { [self] (_, response: CanDeleteResponse) in
            if let error = response.error {
                if error.isApiIsBlockedError {
                    completion(.failure(.apiMightBeBlocked(message: error.localizedDescription, originalError: error.underlyingError ?? error as NSError)))
                } else {
                    completion(.failure(.cannotDeleteYourself(becauseOf: error)))
                }
            } else {
                self.forkSession(viewController: viewController,
                                 inAppTheme: inAppTheme,
                                 performAfterShowingAccountDeletionScreen: performAfterShowingAccountDeletionScreen,
                                 performBeforeClosingAccountDeletionScreen: performBeforeClosingAccountDeletionScreen,
                                 completion: completion)
            }
        }
    }
    
    private func forkSession(viewController: AccountDeletionViewControllerPresenter,
                             inAppTheme: @escaping () -> InAppTheme,
                             performAfterShowingAccountDeletionScreen: @escaping () -> Void,
                             performBeforeClosingAccountDeletionScreen: @escaping (@escaping () -> Void) -> Void,
                             completion: @escaping (Result<AccountDeletionSuccess, AccountDeletionError>) -> Void) {
        authenticator.forkSession { [self] result in
            switch result {
            case let .failure(.apiMightBeBlocked(message, originalError)):
                completion(.failure(.apiMightBeBlocked(message: message, originalError: originalError)))
            case .failure(let authError):
                completion(.failure(.sessionForkingError(message: authError.userFacingMessageInNetworking)))
            case .success(let response):
                handleSuccessfullyForkedSession(
                    selector: response.selector,
                    over: viewController,
                    inAppTheme: inAppTheme,
                    performAfterShowingAccountDeletionScreen: performAfterShowingAccountDeletionScreen,
                    performBeforeClosingAccountDeletionScreen: performBeforeClosingAccountDeletionScreen,
                    completion: completion
                )
            }
        }
    }
    
    // swiftlint:disable:next function_parameter_count
    private func handleSuccessfullyForkedSession(
        selector: String,
        over: AccountDeletionViewControllerPresenter,
        inAppTheme: @escaping () -> InAppTheme,
        performAfterShowingAccountDeletionScreen: @escaping () -> Void,
        performBeforeClosingAccountDeletionScreen: @escaping (@escaping () -> Void) -> Void,
        completion: @escaping (Result<AccountDeletionSuccess, AccountDeletionError>) -> Void
    ) {
        let viewModel = AccountDeletionViewModel(forkSelector: selector,
                                                 apiService: api,
                                                 doh: doh,
                                                 preferredLanguage: preferredLanguage,
                                                 performBeforeClosingAccountDeletionScreen: performBeforeClosingAccountDeletionScreen,
                                                 completion: completion)
        let viewController = AccountDeletionWebView(viewModel: viewModel)
        viewController.stronglyKeptDelegate = self
        present(vc: viewController, over: over, inAppTheme: inAppTheme, completion: performAfterShowingAccountDeletionScreen)
    }
}
