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
import Testing

struct ContactFormatterTests {
    @Test(
        "formats address correctly",
        arguments:
            zip(
                [
                    ContactDetailAddress(
                        street: "Bahnhofstrasse 1",
                        city: "Zürich",
                        region: nil,
                        postalCode: "8001",
                        country: nil,
                        addrType: [.home, .work]
                    ),
                    ContactDetailAddress(
                        street: "Rue du Rhône 8",
                        city: "Genève",
                        region: nil,
                        postalCode: "1204",
                        country: nil,
                        addrType: [.string("holiday")]
                    ),
                    ContactDetailAddress(
                        street: nil,
                        city: "Lugano",
                        region: nil,
                        postalCode: "6900",
                        country: nil,
                        addrType: []
                    ),
                    ContactDetailAddress(
                        street: "Musterstrasse 5",
                        city: nil,
                        region: nil,
                        postalCode: nil,
                        country: nil,
                        addrType: [.work]
                    ),
                    ContactDetailAddress(
                        street: nil,
                        city: "Lugano",
                        region: "Ticino",
                        postalCode: "6250",
                        country: "Switzerland",
                        addrType: []
                    ),
                ],
                [
                    ContactDetailsItem(label: "Home", value: "Bahnhofstrasse 1\nZürich 8001", isInteractive: false),
                    ContactDetailsItem(label: "Holiday", value: "Rue du Rhône 8\nGenève 1204", isInteractive: false),
                    ContactDetailsItem(label: "Address", value: "Lugano 6900", isInteractive: false),
                    ContactDetailsItem(label: "Work", value: "Musterstrasse 5", isInteractive: false),
                    ContactDetailsItem(label: "Address", value: "Lugano Ticino 6250\nSwitzerland", isInteractive: false),
                ]
            )
    )
    func testAddressFormatter(input: ContactDetailAddress, ouput: ContactDetailsItem) {
        #expect(ContactFormatter.Address.formatted(from: input) == ouput)
    }

    @Test(
        "formats gender correctly",
        arguments:
            zip(
                [
                    GenderKind.male,
                    GenderKind.female,
                    GenderKind.other,
                    GenderKind.notApplicable,
                    GenderKind.unknown,
                    GenderKind.none,
                    GenderKind.string("prefer not to say"),
                    GenderKind.string("non-binary"),
                ],
                [
                    ContactDetailsItem(label: "Gender", value: "Male", isInteractive: false),
                    ContactDetailsItem(label: "Gender", value: "Female", isInteractive: false),
                    ContactDetailsItem(label: "Gender", value: "Other", isInteractive: false),
                    ContactDetailsItem(label: "Gender", value: "Not applicable", isInteractive: false),
                    ContactDetailsItem(label: "Gender", value: "Unknown", isInteractive: false),
                    ContactDetailsItem(label: "Gender", value: "None", isInteractive: false),
                    ContactDetailsItem(label: "Gender", value: "Prefer not to say", isInteractive: false),
                    ContactDetailsItem(label: "Gender", value: "Non-binary", isInteractive: false),
                ]
            )
    )
    func testGenderFormatter(input: GenderKind, output: ContactDetailsItem) {
        #expect(ContactFormatter.Gender.formatted(from: input) == output)
    }

    @Test(
        "formats contact date",
        arguments:
            zip(
                [
                    (ContactDate.string("Feb 25, 2015"), "Birthday"),
                    (ContactDate.date(.init(year: 2011, month: 9, day: 22)), "Anniversary"),
                    (ContactDate.date(.init(year: 2020, month: 12, day: .none)), "Anniversary"),
                    (ContactDate.date(.init(year: 2004, month: .none, day: .none)), "Birthday"),
                    (ContactDate.date(.init(year: .none, month: .none, day: .none)), "Missing date"),
                ],
                [
                    ContactDetailsItem(label: "Birthday", value: "Feb 25, 2015", isInteractive: false),
                    ContactDetailsItem(label: "Anniversary", value: "9/22/11", isInteractive: false),
                    ContactDetailsItem(label: "Anniversary", value: "12/1/20", isInteractive: false),
                    ContactDetailsItem(label: "Birthday", value: "1/1/04", isInteractive: false),
                    ContactDetailsItem(label: "Missing date", value: "1/1/01", isInteractive: false),
                ]
            )
    )
    func testDateFormatter(input: (date: ContactDate, label: String), output: ContactDetailsItem) {
        #expect(ContactFormatter.Date.formatted(from: input.date, with: input.label) == output)
    }

    @Test(
        "formats telephone correctly",
        arguments:
            zip(
                [
                    ContactDetailsTelephones(number: "044 123 45 67", telTypes: [.home]),
                    ContactDetailsTelephones(number: "079 456 78 90", telTypes: [.cell, .voice]),
                    ContactDetailsTelephones(number: "031 987 65 43", telTypes: []),
                    ContactDetailsTelephones(number: "0800 111 222", telTypes: [.string("Toll-Free")]),
                    ContactDetailsTelephones(number: "076 333 44 55", telTypes: [.text]),
                    ContactDetailsTelephones(number: "032 123 45 67", telTypes: [.fax]),
                    ContactDetailsTelephones(number: "041 555 66 77", telTypes: [.video]),
                    ContactDetailsTelephones(number: "043 666 77 88", telTypes: [.pager]),
                    ContactDetailsTelephones(number: "044 777 88 99", telTypes: [.textPhone]),
                ],
                [
                    ContactDetailsItem(label: "Home", value: "044 123 45 67", isInteractive: true),
                    ContactDetailsItem(label: "Cell", value: "079 456 78 90", isInteractive: true),
                    ContactDetailsItem(label: "Phone", value: "031 987 65 43", isInteractive: true),
                    ContactDetailsItem(label: "Toll-Free", value: "0800 111 222", isInteractive: true),
                    ContactDetailsItem(label: "Text", value: "076 333 44 55", isInteractive: true),
                    ContactDetailsItem(label: "Fax", value: "032 123 45 67", isInteractive: true),
                    ContactDetailsItem(label: "Video", value: "041 555 66 77", isInteractive: true),
                    ContactDetailsItem(label: "Pager", value: "043 666 77 88", isInteractive: true),
                    ContactDetailsItem(label: "Text phone", value: "044 777 88 99", isInteractive: true),
                ]
            )
    )
    func testTelephoneFormatter(input: ContactDetailsTelephones, output: ContactDetailsItem) {
        #expect(ContactFormatter.Telephone.formatted(from: input) == output)
    }

    @Test(
        "formats URL correctly",
        arguments:
            zip(
                [
                    VCardUrl(url: "https://swissbank.ch", urlType: [.work]),
                    VCardUrl(url: "https://voice.example", urlType: [.voice]),
                    VCardUrl(url: "https://personal.blog", urlType: [.home]),
                    VCardUrl(url: "https://example.org", urlType: []),
                    VCardUrl(url: "https://custom.link", urlType: [.string("GitHub")]),
                ],
                [
                    ContactDetailsItem(label: "Work", value: "https://swissbank.ch", isInteractive: true),
                    ContactDetailsItem(label: "Voice", value: "https://voice.example", isInteractive: true),
                    ContactDetailsItem(label: "Home", value: "https://personal.blog", isInteractive: true),
                    ContactDetailsItem(label: "URL", value: "https://example.org", isInteractive: true),
                    ContactDetailsItem(label: "GitHub", value: "https://custom.link", isInteractive: true),
                ]
            )
    )
    func testURLFormatter(input: VCardUrl, output: ContactDetailsItem) {
        #expect(ContactFormatter.URL.formatted(from: input) == output)
    }
}
