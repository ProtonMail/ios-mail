// Copyright (c) 2025 Proton Technologies AG
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
import InboxCoreUI
import InboxSnapshotTesting
import proton_app_uniffi
import SwiftUI
import Testing

@MainActor
final class ContactDetailsScreenSnapshotTests {
    @Test
    func testContactDetailsScreenVariant1() {
        let items: [ContactField] = [
            .emails([
                .init(emailType: [.work], email: "ben.ale@protonmail.com"),
                .init(emailType: [.home], email: "alexander@proton.me"),
            ]),
            .addresses([
                .init(
                    street: "Lettensteg 10",
                    city: "Zürich",
                    region: .none,
                    postalCode: "8037",
                    country: .none,
                    addrType: []
                ),
                .init(
                    street: "Uetlibergstrasse 872",
                    city: "Zürich",
                    region: .none,
                    postalCode: "8025",
                    country: .none,
                    addrType: []
                ),
            ]),
            .birthday(.string("Jan 23, 2004")),
            .notes([
                "Met Caleb while studying abroad. Amazing memories and a strong friendship."
            ]),
        ]

        assertSnapshotsOnIPhoneX(of: makeSUT(items: items))
    }

    @Test
    func testContactDetailsScreenVariant2() {
        let items: [ContactField] = [
            .emails([
                .init(emailType: [.work], email: "ben.ale@protonmail.com")
            ]),
            .telephones([
                .init(number: "+41771234567", telTypes: [.home])
            ]),
            .anniversary(.string("Feb 28, 2019")),
            .gender(.male),
            .languages(["english", "german"]),
        ]

        assertSnapshotsOnIPhoneX(of: makeSUT(items: items))
    }

    @Test
    func testContactDetailsScreenVariant3() {
        let items: [ContactField] = [
            .emails([
                .init(emailType: [.work], email: "ben.ale@protonmail.com")
            ]),
            .languages(["english", "german"]),
            .timeZones(["Europe/Zürich"]),
            .titles(["Phd"]),
            .roles(["Professor"]),
        ]

        assertSnapshotsOnIPhoneX(of: makeSUT(items: items))
    }

    @Test
    func testContactDetailsScreenVariant4() {
        let items: [ContactField] = [
            .emails([
                .init(emailType: [.work], email: "ben.ale@protonmail.com")
            ]),
            .languages(["french"]),
            .organizations(["CERN", "NASA"]),
            .members(["N/A"]),
            .urls([.init(url: .http("https://www.nasa.gov"), urlType: [.work])]),
        ]

        assertSnapshotsOnIPhoneX(of: makeSUT(items: items))
    }

    private func makeSUT(items: [ContactField]) -> some View {
        let contact: ContactItem = .benjaminAlexander
        let sut = ContactDetailsScreen(
            contact: contact,
            provider: .previewInstance(),
            draftPresenter: ContactsDraftPresenterDummy(),
            state: .init(contact: contact, details: .testData(contact: contact, fields: items))
        )

        return sut.environmentObject(ToastStateStore(initialState: .initial))
    }
}
