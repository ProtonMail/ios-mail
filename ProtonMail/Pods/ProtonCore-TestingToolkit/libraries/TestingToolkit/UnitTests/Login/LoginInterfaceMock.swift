//
//  LoginInterfaceMock.swift
//  ProtonCore-TestingToolkit - Created on 03.06.2021.
//
//  Copyright (c) 2021 Proton Technologies AG
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

import UIKit
import ProtonCore_Login

public class LoginInterfaceMock: LoginAndSignupInterface {

    public init() {}

    @FuncStub(LoginInterfaceMock.presentLoginFlow) public var presentLoginFlowStub
    public func presentLoginFlow(over viewController: UIViewController,
                                 username: String?,
                                 performBeforeFlowCompletion: WorkBeforeFlowCompletion?,
                                 completion: @escaping (LoginResult) -> Void) {
        presentLoginFlowStub(viewController, username, performBeforeFlowCompletion, completion)
    }

    @FuncStub(LoginInterfaceMock.presentSignupFlow) public var presentSignupFlowStub
    public func presentSignupFlow(over viewController: UIViewController,
                                  performBeforeFlowCompletion: WorkBeforeFlowCompletion?,
                                  completion: @escaping (LoginResult) -> Void) {
        presentSignupFlowStub(viewController, performBeforeFlowCompletion, completion)
    }

    @FuncStub(LoginInterfaceMock.presentMailboxPasswordFlow) public var presentMailboxPasswordFlowStub
    public func presentMailboxPasswordFlow(over viewController: UIViewController, completion: @escaping (String) -> Void) {
        presentMailboxPasswordFlowStub(viewController, completion)
    }

    @FuncStub(LoginInterfaceMock.presentFlowFromWelcomeScreen) public var presentFlowFromWelcomeScreenStub
    public func presentFlowFromWelcomeScreen(over viewController: UIViewController,
                                             welcomeScreen: WelcomeScreenVariant,
                                             username: String?,
                                             performBeforeFlowCompletion: WorkBeforeFlowCompletion?,
                                             completion: @escaping (LoginResult) -> Void) {
        presentFlowFromWelcomeScreenStub(viewController, welcomeScreen, username, performBeforeFlowCompletion, completion)
    }

    @FuncStub(LoginInterfaceMock.welcomeScreenForPresentingFlow, initialReturn: .crash) public var welcomeScreenForPresentingFlowStub
    public func welcomeScreenForPresentingFlow(variant welcomeScreen: WelcomeScreenVariant,
                                               username: String?,
                                               performBeforeFlowCompletion: WorkBeforeFlowCompletion?,
                                               completion: @escaping (LoginResult) -> Void) -> UIViewController {
        welcomeScreenForPresentingFlowStub(welcomeScreen, username, performBeforeFlowCompletion, completion)
    }
}
