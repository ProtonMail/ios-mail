//
//  Created on 30/4/24.
//
//  Copyright (c) 2024 Proton AG
//
//  ProtonVPN is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonVPN is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonVPN.  If not, see <https://www.gnu.org/licenses/>.

#if os(iOS)

import Foundation
import AuthenticationServices
import ProtonCoreAuthentication
import ProtonCoreLog
import ProtonCoreLogin
import ProtonCoreUIFoundations

@available(iOS 15.0, macOS 12.0, *)
extension Fido2View {

    public class ViewModel: NSObject, ObservableObject {

        var state: Fido2ViewModelState = .initial
        @Published var isLoading = false
        @Published var bannerState: BannerState = .none
        weak var delegate: TwoFactorViewControllerDelegate?

#if DEBUG
        static var initial: ViewModel = .init()
#endif

        override private init() { }

        public init(login: Login, challenge: Data, relyingPartyIdentifier: String, allowedCredentialIds: [Data]) {
            self.state = .configured(login: login,
                                     challenge: challenge,
                                     relyingPartyIdentifier: relyingPartyIdentifier,
                                     allowedCredentials: allowedCredentialIds.map {
                ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor(credentialID: $0,
                                                                        transports: ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor.Transport.allSupported)
                                     }
            )
        }

        func startSignature() {
            guard case let .configured(_, challenge, relyingPartyIdentifier, allowedCredentials) = state else { return }

            let provider = ASAuthorizationSecurityKeyPublicKeyCredentialProvider(relyingPartyIdentifier: relyingPartyIdentifier)
            let request = provider.createCredentialAssertionRequest(challenge: challenge)
            request.allowedCredentials = allowedCredentials
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        func provideFido2Signature(_ signature: Fido2Signature) {
            guard case let .configured(login, _, _, _) = state else { return }

            isLoading = true
            login.provideFido2Signature(signature) { @MainActor [weak self] result in
                switch result {
                case let .success(status):
                    switch status {
                    case let .finished(data):
                        self?.delegate?.twoFactorViewControllerDidFinish(data: data) { [weak self] in
                            self?.isLoading = false
                        }
                    case let .chooseInternalUsernameAndCreateInternalAddress(data):
                        login.availableUsernameForExternalAccountEmail(email: data.email) { [weak self] username in
                            self?.delegate?.createAddressNeeded(data: data, defaultUsername: username)
                            self?.isLoading = false
                        }
                    case .askTOTP, .askAny2FA, .askFIDO2:
                        PMLog.error("Asking for 2FA validation after successful 2FA validation is an invalid state", sendToExternal: true)
                        self?.isLoading = false
                        self?.bannerState = .error(content: .init(message: LUITranslation.twofa_invalid_state_banner.l10n))
                    case .askSecondPassword:
                        self?.delegate?.mailboxPasswordNeeded()
                        self?.isLoading = false
                    case .ssoChallenge:
                        PMLog.error("Receiving SSO challenge after successful 2FA code is an invalid state", sendToExternal: true)
                        self?.isLoading = false
                        self?.bannerState = .error(content: .init(message: LUITranslation.twofa_invalid_state_banner.l10n))
                    }
                case .failure(let error):
                    self?.bannerState = .error(content: .init(message: error.userFacingMessageInLogin))
                    self?.isLoading = false
                }
            }
        }
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension Fido2View.ViewModel: ASAuthorizationControllerDelegate {

    @MainActor
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let credentialAssertion as ASAuthorizationSecurityKeyPublicKeyCredentialAssertion:
            let signature = Fido2Signature(credentialAssertion: credentialAssertion)
            provideFido2Signature(signature)
        default:
            PMLog.error("Received unknown authorization type: \(authorization.credential)", sendToExternal: true)
            bannerState = .error(content: .init(message: LUITranslation.twofa_unexpected_authorization_type.l10n))
        }
    }

    @MainActor
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        PMLog.error("Secure Key authorization failed with error: \(error.localizedDescription)", sendToExternal: true)
        guard let authorizationError = error as? ASAuthorizationError,
              authorizationError.code != .canceled else {
            // do nothing, it's user caused
            return
        }
        bannerState = .error(content: .init(message: error.localizedDescription))
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension Fido2View.ViewModel: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension Fido2Signature {
    init(credentialAssertion: ASAuthorizationSecurityKeyPublicKeyCredentialAssertion) {
        self = .init(signature: credentialAssertion.signature,
                     credentialID: credentialAssertion.credentialID,
                     authenticatorData: credentialAssertion.rawAuthenticatorData,
                     clientData: credentialAssertion.rawClientDataJSON)
    }
}

@available(iOS 15.0, macOS 12.0, *)
enum Fido2ViewModelState {
    case initial
    case configured(login: Login, challenge: Data, relyingPartyIdentifier: String, allowedCredentials: [ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor])
}

#endif
