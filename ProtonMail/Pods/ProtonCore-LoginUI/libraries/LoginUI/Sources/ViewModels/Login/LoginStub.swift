//
//  LoginStub.swift
//  ProtonCoreLoginUI - Created on 10/05/2024.
//
//  Copyright (c) 2024 Proton AG
//
//  This file is part of Proton AG and ProtonCore.
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

#if DEBUG

// MARK: Stub for SwiftUI Previews

import Foundation
import ProtonCoreLogin
import ProtonCoreNetworking
import ProtonCoreAuthentication
import ProtonCoreDataModel
import ProtonCoreServices
import ProtonCoreAPIClient

struct LoginStub: Login {
    func processResponseToken(idpEmail: String, responseToken: ProtonCoreNetworking.SSOResponseToken, completion: @escaping (Result<ProtonCoreLogin.LoginStatus, ProtonCoreLogin.LoginError>) -> Void) {

    }

    func getSSORequest(challenge ssoChallengeResponse: ProtonCoreAuthentication.SSOChallengeResponse) async -> (request: URLRequest?, error: String?) {
        (nil, nil)
    }

    func isProtonPage(url: URL?) -> Bool {
        false
    }

    var currentlyChosenSignUpDomain: String = ""

    var allSignUpDomains: [String] = []

    func updateAllAvailableDomains(type: ProtonCoreLogin.AvailableDomainsType, result: @escaping ([String]?) -> Void) {

    }

    func login(username: String, password: String, intent: Intent?, challenge: [String: Any]?, completion: @escaping (Result<LoginStatus, LoginError>) -> Void) {

    }

    func provide2FACode(_ code: String, completion: @escaping (Result<ProtonCoreLogin.LoginStatus, ProtonCoreLogin.LoginError>) -> Void) {

    }

    func provideFido2Signature(_ signature: ProtonCoreAuthentication.Fido2Signature, completion: @escaping (Result<ProtonCoreLogin.LoginStatus, ProtonCoreLogin.LoginError>) -> Void) {

    }

    func finishLoginFlow(mailboxPassword: String, passwordMode: ProtonCoreAPIClient.PasswordMode, completion: @escaping (Result<ProtonCoreLogin.LoginStatus, ProtonCoreLogin.LoginError>) -> Void) {

    }

    func logout(credential: ProtonCoreNetworking.AuthCredential?, completion: @escaping (Result<Void, Error>) -> Void) {

    }

    func checkAvailabilityForUsernameAccount(username: String, completion: @escaping (Result<(), ProtonCoreLogin.AvailabilityError>) -> Void) {

    }

    func checkAvailabilityForInternalAccount(username: String, completion: @escaping (Result<(), ProtonCoreLogin.AvailabilityError>) -> Void) {

    }

    func checkAvailabilityForExternalAccount(email: String, completion: @escaping (Result<(), ProtonCoreLogin.AvailabilityError>) -> Void) {

    }

    func setUsername(username: String, completion: @escaping (Result<(), ProtonCoreLogin.SetUsernameError>) -> Void) {

    }

    func createAccountKeysIfNeeded(user: ProtonCoreDataModel.User, addresses: [ProtonCoreDataModel.Address]?, mailboxPassword: String?, completion: @escaping (Result<ProtonCoreDataModel.User, ProtonCoreLogin.LoginError>) -> Void) {

    }

    func createAddress(completion: @escaping (Result<ProtonCoreDataModel.Address, ProtonCoreLogin.CreateAddressError>) -> Void) {

    }

    func createAddressKeys(user: ProtonCoreDataModel.User, address: ProtonCoreDataModel.Address, mailboxPassword: String, completion: @escaping (Result<ProtonCoreDataModel.Key, ProtonCoreLogin.CreateAddressKeysError>) -> Void) {

    }

    func refreshCredentials(completion: @escaping (Result<ProtonCoreNetworking.Credential, ProtonCoreLogin.LoginError>) -> Void) {

    }

    func refreshUserInfo(completion: @escaping (Result<ProtonCoreDataModel.User, ProtonCoreLogin.LoginError>) -> Void) {

    }

    func availableUsernameForExternalAccountEmail(email: String, completion: @escaping (String?) -> Void) {

    }

    var minimumAccountType: ProtonCoreLogin.AccountType = .external

    func updateAccountType(accountType: ProtonCoreLogin.AccountType) {

    }

    var startGeneratingAddress: (() -> Void)?

    var startGeneratingKeys: (() -> Void)?

}

#endif
