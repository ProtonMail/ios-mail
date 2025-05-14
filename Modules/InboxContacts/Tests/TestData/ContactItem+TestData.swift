// Copyright (c) 2024 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

@testable import InboxContacts
import proton_app_uniffi

extension ContactItem {

    static func testData(id: UInt64) -> Self {
        .init(
            id: id,
            name: "__NOT_USED__",
            avatarInformation: .init(text: "AA", color: "#FF5733"),
            emails: []
        )
    }

    static var vip: Self {
        .init(
            id: 1_000,
            name: "0 VIP",
            avatarInformation: .init(text: "0V", color: "#33FF57"),
            emails: [
                .init(id: 1_001, email: "vip@proton.me"),
            ]
        )
    }

    static var aliceAdams: Self {
        .init(
            id: 0,
            name: "Alice Adams",
            avatarInformation: .init(text: "AA", color: "#FF5733"),
            emails: [
                .init(id: 1, email: "alice.adams@proton.me"),
                .init(id: 2, email: "alice.adams@gmail.com")
            ]
        )
    }

    static var andrewAllen: Self {
        .init(
            id: 7,
            name: "🙂 Andrew Allen",
            avatarInformation: .init(text: "AA", color: "#33FF57"),
            emails: [
                .init(id: 8, email: "andrew.allen@protonmail.com"),
                .init(id: 9, email: "andrew.allen@yahoo.com")
            ]
        )
    }

    static var amandaArcher: Self {
        .init(
            id: 10,
            name: "Amanda Archer",
            avatarInformation: .init(text: "AA", color: "#3357FF"),
            emails: [
                .init(id: 11, email: "amanda.archer@gmail.com"),
                .init(id: 12, email: "amanda.archer@pm.me")
            ]
        )
    }

    static var alexAbrams: Self {
        .init(
            id: 13,
            name: "Alex Abrams",
            avatarInformation: .init(text: "AA", color: "#FF5733"),
            emails: [
                .init(id: 13, email: "alex.abrams@gmail.com"),
                .init(id: 14, email: "alex.andrews@pm.me")
            ]
        )
    }

    static var bobAinsworth: Self {
        .init(
            id: 1,
            name: "Bob Ainsworth",
            avatarInformation: .init(text: "BA", color: "#FF33A1"),
            emails: []
        )
    }

    static var elenaErickson: Self {
        .init(
            id: 11,
            name: "🌟 Elena Erickson",
            avatarInformation: .init(text: "EE", color: "#33A1FF"),
            emails: [
                .init(id: 21, email: "elena.erickson@example.com"),
                .init(id: 22, email: "elena.e@yahoo.com")
            ]
        )
    }

    static var evanAndrage: Self {
        .init(
            id: 12,
            name: "😊 Evan Andrage",
            avatarInformation: .init(text: "EA", color: "#FF5733"),
            emails: [
                .init(id: 11, email: "evan.andrage@outlook.com"),
                .init(id: 12, email: "e.andrage@gmail.com")
            ]
        )
    }

}
