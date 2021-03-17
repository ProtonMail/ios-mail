//
//  TokenStorage.swift
//  PMPayments - Created on 01/02/2021.
//
//
//  Copyright (c) 2021 Proton Technologies AG
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

class TokenStorage: PaymentTokenStorage {
    let tokenStorage: PaymentTokenStorage?

    init(tokenStorage: PaymentTokenStorage?) {
        self.tokenStorage = tokenStorage ?? LocalTokenStorage()
    }

    func add(_ token: PaymentToken) {
        tokenStorage?.add(token)
    }

    func get() -> PaymentToken? {
        return tokenStorage?.get()
    }

    func clear() {
        tokenStorage?.clear()
    }
}

class LocalTokenStorage: PaymentTokenStorage {
    var token: PaymentToken?

    func add(_ token: PaymentToken) {
        self.token = token
    }

    func get() -> PaymentToken? {
        return token
    }

    func clear() {
        self.token = nil
    }
}
