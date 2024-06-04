//
//  User.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 24.07.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import ProtonCoreQuarkCommands

extension User {

    init(id: Int, name: String, password: String = "", email: String = "") {
        self.init(name: name, password: password)
        self.mailboxPassword = ""
        self.totpSecurityKey = ""
        self.displayName = name
        self.id = id
        self.email = email
    }

    init(from quarkResponse: MailWebFixtureQuarkResponse) {
        self.init(name: quarkResponse.name, password: quarkResponse.password)
        self.email = quarkResponse.email
        self.displayName = self.name
        self.mailboxPassword = ""
        self.totpSecurityKey = ""
        self.id = Int(quarkResponse.decryptedUserId)
        self.recoveryEmail = quarkResponse.recovery
    }

    init(from quarkResponse: QuarkUser) {
        self.init(name: quarkResponse.name, password: quarkResponse.password)
        self.displayName = self.name
        self.mailboxPassword = ""
        self.totpSecurityKey = ""
        self.id = quarkResponse.id.raw
    }

    func getTwoFaCode() -> String {
        return Otp().generate(self.totpSecurityKey)
    }

    var dynamicDomainEmail: String {
        return "\(name)@\(dynamicDomain)"
    }
}
