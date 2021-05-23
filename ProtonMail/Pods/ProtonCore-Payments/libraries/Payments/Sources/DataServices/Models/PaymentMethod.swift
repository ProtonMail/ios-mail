//
//  PaymentMethod.swift
//  PMPayments - Created on 31/08/2018.
//
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

// swiftlint:disable identifier_name

import Foundation

struct PaymentMethod: Codable {
    enum PaymentType: String, Codable {
        case other
        case apple
        case card

        init?(rawValue: String) {
            if rawValue == PaymentType.apple.rawValue {
                self = .apple
            } else if rawValue == PaymentType.card.rawValue {
                self = .card
            } else {
                self = .other
            }
        }
    }

    let iD: String
    let type: PaymentType
}
