//
//  ExternalLinks.swift
//  PMLogin - Created on 15.12.2020.
//
//  Copyright (c) 2019 Proton Technologies AG
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

import Foundation

final class ExternalLinks {
    let passwordReset = URL(string: "https://mail.protonmail.com/help/reset-login-password")!
    let accountSetup = URL(string: "https://account.protonmail.com/")!
    let termsAndConditions = URL(string: "https://protonmail.com/terms-and-conditions")!
    let humanVerificationHelp = URL(string: "https://protonmail.com/support/knowledge-base/human-verification/")!
    let support = URL(string: "https://protonmail.com/support-form")!
    let commonLoginProblems = URL(string: "https://protonmail.com/support/knowledge-base/common-login-problems")!
    let forgottenUsername = URL(string: "https://protonmail.com/username")!
}
