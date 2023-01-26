//
//  AccountDeletionViewModel.swift
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

#if canImport(ProtonCore_Authentication)
import ProtonCore_Authentication
#else
import PMAuthentication
#endif
#if canImport(ProtonCore_Networking)
import ProtonCore_Networking
#else
import PMCommon
#endif
#if canImport(ProtonCore_Doh)
import ProtonCore_Doh
#endif
#if canImport(ProtonCore_Services)
import ProtonCore_Services
#endif
#if canImport(ProtonCore_CoreTranslation)
import ProtonCore_CoreTranslation
#else
import PMCoreTranslation
#endif
import ProtonCore_Utilities
import WebKit

public enum NotificationType: String, Codable {
    case error
    case warning
    case info
    case success
}

public enum AccountDeletionRetryCheckResult: Equatable {
    case dontRetry
    case retry
    case apiMightBeBlocked(message: String)
}

public protocol AccountDeletionViewModelInterface {
    
    var getURLRequest: URLRequest { get }
    
    func setup(webViewConfiguration: WKWebViewConfiguration)
    
    func shouldRetryFailedLoading(host: String, error: Error, shouldReloadWebView: @escaping (AccountDeletionRetryCheckResult) -> Void)
    
    func interpretMessage(_ message: WKScriptMessage,
                          loadedPresentation: @escaping () -> Void,
                          notificationPresentation: @escaping (NotificationType, String) -> Void,
                          successPresentation: @escaping () -> Void,
                          closeWebView: @escaping (@escaping () -> Void) -> Void)
    
    func deleteAccountWasClosed()
    
    func deleteAccountDidErrorOut(message: String)
    
    func deleteAccountFailedBecauseApiMightBeBlocked(message: String, originalError: Error)
}

final class AccountDeletionViewModel: AccountDeletionViewModelInterface {
    
    enum AccountDeletionMessageType: String, Codable {
        case loaded = "LOADED"
        case success = "SUCCESS"
        case error = "ERROR"
        case close = "CLOSE"
        case notification = "NOTIFICATION"
    }
    
    struct AccountDeletionMessagePayload: Codable {
        // error message payload
        let message: String?
        
        // notification message payload
        let type: NotificationType?
        let text: String?
    }
    
    struct AccountDeletionMessage: Codable {
        let type: AccountDeletionMessageType
        let payload: AccountDeletionMessagePayload?
    }
    
    var getURLRequest: URLRequest {
        let host = doh.getAccountHost()
        let url = URL(string: "\(host)/lite?action=delete-account&language=\(preferredLanguage)#selector=\(forkSelector)")!
        return URLRequest(url: url)
    }
    
    var jsonDecoder = JSONDecoder()
    
    private let forkSelector: String
    private let apiService: APIService
    private let doh: DoHInterface
    private let performBeforeClosingAccountDeletionScreen: (@escaping () -> Void) -> Void
    private let completion: (Result<AccountDeletionSuccess, AccountDeletionError>) -> Void
    private let preferredLanguage: String
    
    enum AccountDeletionState {
        case notDeletedYet
        case alreadyDeleted
        case finishedWithoutDeletion
    }
    
    private var state: AccountDeletionState = .notDeletedYet
    private let callCompletionBlockUsing: CompletionBlockExecutor
    
    init(forkSelector: String,
         apiService: APIService,
         doh: DoHInterface,
         preferredLanguage: String = NSLocale.autoupdatingCurrent.identifier,
         performBeforeClosingAccountDeletionScreen: @escaping (@escaping () -> Void) -> Void,
         callCompletionBlockUsing: CompletionBlockExecutor = .asyncMainExecutor,
         completion: @escaping (Result<AccountDeletionSuccess, AccountDeletionError>) -> Void) {
        self.forkSelector = forkSelector
        self.apiService = apiService
        self.doh = doh
        self.preferredLanguage = preferredLanguage
        self.performBeforeClosingAccountDeletionScreen = performBeforeClosingAccountDeletionScreen
        self.callCompletionBlockUsing = callCompletionBlockUsing
        self.completion = completion
    }
    
    func setup(webViewConfiguration: WKWebViewConfiguration) {
        let requestInterceptor = AlternativeRoutingRequestInterceptor(
            headersGetter: doh.getAccountHeaders,
            cookiesSynchronization: doh.synchronizeCookies(with:requestHeaders:),
            cookiesStorage: doh.currentlyUsedCookiesStorage
        ) { challenge, completionHandler in
            handleAuthenticationChallenge(
                didReceive: challenge,
                noTrustKit: PMAPIService.noTrustKit,
                trustKit: PMAPIService.trustKit,
                challengeCompletionHandler: completionHandler
            )
        }
        requestInterceptor.setup(webViewConfiguration: webViewConfiguration)
    }
    
    func interpretMessage(_ message: WKScriptMessage,
                          loadedPresentation: @escaping () -> Void,
                          notificationPresentation: @escaping(NotificationType, String) -> Void,
                          successPresentation: @escaping () -> Void,
                          closeWebView: @escaping (@escaping () -> Void) -> Void) {
        guard let string = message.body as? String,
              let data = string.utf8,
              let message = try? jsonDecoder.decode(AccountDeletionMessage.self, from: data)
        else { return }
        // we ignore further messages if we've already received the success message
        guard state == .notDeletedYet else { return }
        switch message.type {
        case .loaded:
            callCompletionBlockUsing.execute(completionBlock: loadedPresentation)
        case .notification:
            guard let notificationMessage = message.payload?.text else { return }
            let notificationType = message.payload?.type ?? .warning
            callCompletionBlockUsing.execute {
                notificationPresentation(notificationType, notificationMessage)
            }
        case .success:
            callCompletionBlockUsing.execute {
                successPresentation()
            }
            state = .alreadyDeleted
            let completion = completion
            let performBeforeClosingAccountDeletionScreen = performBeforeClosingAccountDeletionScreen
            callCompletionBlockUsing.execute(after: .seconds(3)) {
                performBeforeClosingAccountDeletionScreen {
                    closeWebView {
                        completion(.success(AccountDeletionSuccess()))
                    }
                }
            }
        case .error:
            state = .finishedWithoutDeletion
            let errorMessage = message.payload?.message ?? CoreString._ad_delete_network_error
            let completion = completion
            callCompletionBlockUsing.execute {
                closeWebView {
                    completion(.failure(.deletionFailure(message: errorMessage)))
                }
            }
        case .close:
            state = .finishedWithoutDeletion
            let completion = completion
            callCompletionBlockUsing.execute {
                closeWebView { }
                completion(.failure(.closedByUser))
            }
        }
    }
    
    func deleteAccountDidErrorOut(message: String) {
        let completion = completion
        callCompletionBlockUsing.execute {
            completion(.failure(.deletionFailure(message: message)))
        }
    }
    
    func deleteAccountFailedBecauseApiMightBeBlocked(message: String, originalError: Error) {
        let completion = completion
        callCompletionBlockUsing.execute {
            completion(.failure(.apiMightBeBlocked(message: message, originalError: originalError)))
        }
    }
    
    func deleteAccountWasClosed() {
        let completion = completion
        callCompletionBlockUsing.execute {
            completion(.failure(.closedByUser))
        }
    }
    
    func shouldRetryFailedLoading(host: String, error: Error, shouldReloadWebView: @escaping (AccountDeletionRetryCheckResult) -> Void) {
        doh.handleErrorResolvingProxyDomainIfNeeded(host: host, requestHeaders: doh.getAccountHeaders(), sessionId: apiService.sessionUID, error: error,
                                                    callCompletionBlockUsing: callCompletionBlockUsing) { [weak self] shouldRetry in
            guard shouldRetry == false else { shouldReloadWebView(.retry); return }
            guard self?.doh.errorIndicatesDoHSolvableProblem(error: error) == true else { shouldReloadWebView(.dontRetry); return }
            shouldReloadWebView(.apiMightBeBlocked(message: CoreString._net_api_might_be_blocked_message))
        }
    }
}
