//
//  SigupMock.swift
//  ProtonCore-Login-Tests - Created on 09.04.21.
//
//  Copyright (c) 2019 Proton Technologies AG
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

// swiftlint:disable function_parameter_count

import Foundation

import ProtonCore_Login

public class SigupMock: Signup {
    
    public init() {}
    
    public var requestValidationTokenResult: (Result<Void, SignupError>) = .success(())
    public var checkValidationTokenResult: (Result<Void, SignupError>) = .success(())
    public var createNewUserResult: (Result<Void, SignupError>) = .success(())
    public var createNewExternalUserResult: (Result<Void, SignupError>) = .success(())
    
    public func requestValidationToken(email: String, completion: @escaping (Result<Void, SignupError>) -> Void) {
        completion(requestValidationTokenResult)
    }
    
    public func checkValidationToken(email: String, token: String, completion: @escaping (Result<Void, SignupError>) -> Void) {
        completion(checkValidationTokenResult)
    }
    
    public func createNewUser(userName: String, password: String, email: String?, phoneNumber: String?, completion: @escaping (Result<(), SignupError>) -> Void) {
        completion(createNewUserResult)
    }
    
    public func createNewExternalUser(email: String, password: String, verifyToken: String, completion: @escaping (Result<(), SignupError>) -> Void) {
        completion(createNewExternalUserResult)
    }
    
    public func createNewUser(userName: String, password: String, deviceToken: String, email: String?, phoneNumber: String?, completion: @escaping (Result<(), SignupError>) -> Void) {
        completion(createNewUserResult)
    }
    
    public func createNewExternalUser(email: String, password: String, deviceToken: String, verifyToken: String, completion: @escaping (Result<(), SignupError>) -> Void) {
        completion(createNewExternalUserResult)
    }
    
}
