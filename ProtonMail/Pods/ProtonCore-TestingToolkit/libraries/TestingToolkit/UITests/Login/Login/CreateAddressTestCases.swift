//
//  CreateAddressTestCases.swift
//  ProtonCore-TestingToolkit - Created on 28.11.2022.
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

import pmtest
import ProtonCore_QuarkCommands
import ProtonCore_Doh

public class CreateAddressTestCases {

    private let quarkCommands: QuarkCommands
    private let loginRobot = LoginRobot()
    private var random: Email!
      
    public init(doh: DoHInterface) {
        self.quarkCommands = QuarkCommands(doh: doh)
        self.random = generateEmail()
    }

    public func testShowCreateAddressSuccessfulCreation<T: CoreElements>(robot _: T.Type) -> T {
        quarkCommands.createUser(externalEmail: random.email, password: random.password)
        
        loginRobot
            .fillUsername(username: random.email)
            .fillpassword(password: random.password)
            .signIn(robot: CreateAddressRobot.self)
            .verify.createAddress(email: random.email)
            .tapContinueButton()
        return T()
    }
    
    public func testShowCreateAddressNewNameSuccessfulCreation<T: CoreElements>(robot _: T.Type) -> T {
        quarkCommands.createUser(externalEmail: random.email, password: random.password)
        let newEmail = generateName()
        
        loginRobot
            .fillUsername(username: random.email)
            .fillpassword(password: random.password)
            .signIn(robot: CreateAddressRobot.self)
            .verify.createAddress(email: random.email)
            .fillUsername(username: newEmail)
            .tapContinueButton()
        return T()
    }
    
    public func testShowCreateAddressCancelButton() {
        quarkCommands.createUser(externalEmail: random.email, password: random.password)
        
        loginRobot
            .fillUsername(username: random.email)
            .fillpassword(password: random.password)
            .signIn(robot: CreateAddressRobot.self)
            .verify.createAddress(email: random.email)
            .tapCancelButton()
            .verify.loginScreenIsShown()
    }
    
    public func testShowCreateAddressBackButton() {
        quarkCommands.createUser(externalEmail: random.email, password: random.password)
        
        loginRobot
            .fillUsername(username: random.email)
            .fillpassword(password: random.password)
            .signIn(robot: CreateAddressRobot.self)
            .verify.createAddress(email: random.email)
            .tapBackButton()
            .verify.loginScreenIsShown()
    }
    
    public func testShowCreateAddressInvalidCharacter() {
        quarkCommands.createUser(externalEmail: random.email, password: random.password)
        
        loginRobot
            .fillUsername(username: random.email)
            .fillpassword(password: random.password)
            .signIn(robot: CreateAddressRobot.self)
            .verify.createAddress(email: random.email)
            .fillUsername(username: "@@@")
            .tapContinueButton()
            .verify.invalidCharactersBanner()
    }
    
    struct Email {
        let email: String
        let password: String
    }
    
    private func generateEmail() -> Email {
        let randomEmail = "\(StringUtils.randomAlphanumericString(length: 8))\(StringUtils.randomAlphanumericString(length: 8))@proton.uitests"
        let randomPassword = StringUtils.randomAlphanumericString(length: 8)
        return Email(email: randomEmail, password: randomPassword)
    }
    
    private func generateName() -> String {
        return "\(StringUtils.randomAlphanumericString(length: 8))\(StringUtils.randomAlphanumericString(length: 8))"
    }
}
 
