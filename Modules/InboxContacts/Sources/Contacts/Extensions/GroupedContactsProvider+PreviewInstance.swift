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

import proton_app_uniffi

extension GroupedContactsProvider {

    static func previewInstance() -> Self {
        .init(allContacts: { _ in .ok(stubbedContacts) })
    }

    private static var stubbedContacts: [GroupedContacts] {
        [
            .init(
                groupedBy: "#",
                items: [
                    .contact(
                        .init(
                            id: 1_000,
                            name: "0 VIP",
                            avatarInformation: .init(text: "0V", color: "#33FF57"),
                            emails: [
                                .init(id: 1_001, email: "vip@proton.me"),
                            ]
                        )
                    ),
                ]
            ),
            .init(
                groupedBy: "A",
                items: [
                    .contact(
                        .init(
                            id: 0,
                            name: "Alice Adams",
                            avatarInformation: .init(text: "AA", color: "#FF5733"),
                            emails: [
                                .init(id: 1, email: "alice.adams@proton.me"),
                                .init(id: 2, email: "alice.adams@gmail.com")
                            ]
                        )
                    ),
                    .group(
                        .init(
                            id: 3,
                            name: "Advisors Group: Comprehensive Wealth Management and Strategic Financial Solutions",
                            avatarColor: "#A1FF33",
                            contacts: [
                                .init(id: 4, email: "group.advisor@pm.me"),
                                .init(id: 5, email: "group.advisor@protonmail.com"),
                                .init(id: 6, email: "advisor.group@yahoo.com")
                            ]
                        )
                    ),
                    .contact(
                        .init(
                            id: 7,
                            name: "🙂 Andrew Allen",
                            avatarInformation: .init(text: "AA", color: "#33FF57"),
                            emails: [
                                .init(id: 8, email: "andrew.allen@protonmail.com"),
                                .init(id: 9, email: "andrew.allen@yahoo.com")
                            ]
                        )
                    ),
                    .contact(
                        .init(
                            id: 10,
                            name: "Amanda Archer",
                            avatarInformation: .init(text: "AA", color: "#3357FF"),
                            emails: [
                                .init(id: 11, email: "amanda.archer@gmail.com"),
                                .init(id: 12, email: "amanda.archer@pm.me")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "B",
                items: [
                    .contact(
                        .init(
                            id: 13,
                            name: "Bob Ainsworth",
                            avatarInformation: .init(text: "BA", color: "#FF33A1"),
                            emails: []
                        )
                    ),
                    .contact(
                        .init(
                            id: 16,
                            name: "Betty Brown",
                            avatarInformation: .init(text: "BB", color: "#FF5733"),
                            emails: [
                                .init(id: 17, email: "betty.brown.consulting.department.group@gmail.com"),
                                .init(id: 18, email: "betty.brown@protonmail.com")
                            ]
                        )
                    ),
                    .group(
                        .init(
                            id: 19,
                            name: "Business Group",
                            avatarColor: "#A1FF33",
                            contacts: [
                                .init(id: 20, email: "business.group@proton.me")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "C",
                items: [
                    .group(
                        .init(
                            id: 23,
                            name: "Consultants",
                            avatarColor: "#33FF57",
                            contacts: [
                                .init(id: 24, email: "consultant@proton.me"),
                                .init(id: 25, email: "consult.group@yahoo.com"),
                                .init(id: 26, email: "group.consultants@pm.me")
                            ]
                        )
                    ),
                    .group(
                        .init(
                            id: 27,
                            name: "Corporate Team",
                            avatarColor: "#3357FF",
                            contacts: [
                                .init(id: 28, email: "corp.team@gmail.com"),
                                .init(id: 29, email: "corp.team@protonmail.com"),
                                .init(id: 30, email: "corporate@proton.me")
                            ]
                        )
                    ),
                    .contact(
                        .init(
                            id: 31,
                            name: "Carl Cooper",
                            avatarInformation: .init(text: "CC", color: "#FF33A1"),
                            emails: [
                                .init(id: 32, email: "carl.cooper@yahoo.com"),
                                .init(id: 33, email: "carl.cooper@protonmail.com")
                            ]
                        )
                    ),
                    .contact(
                        .init(
                            id: 34,
                            name: "Cathy Carter",
                            avatarInformation: .init(text: "CC", color: "#FF5733"),
                            emails: [
                                .init(id: 35, email: "cathy.carter@pm.me"),
                                .init(id: 36, email: "cathy.carter@gmail.com")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "D",
                items: [
                    .contact(
                        .init(
                            id: 37,
                            name: "David Dawson",
                            avatarInformation: .init(text: "DD", color: "#A1FF33"),
                            emails: [
                                .init(id: 38, email: "david.dawson@protonmail.com"),
                                .init(id: 39, email: "david.dawson@yahoo.com")
                            ]
                        )
                    ),
                    .contact(
                        .init(
                            id: 40,
                            name: "Diana Davis",
                            avatarInformation: .init(text: "DD", color: "#33FF57"),
                            emails: [
                                .init(id: 41, email: "diana.davis@pm.me"),
                                .init(id: 42, email: "diana.davis@gmail.com")
                            ]
                        )
                    ),
                    .group(
                        .init(
                            id: 43,
                            name: "Development Team",
                            avatarColor: "#FF33A1",
                            contacts: [
                                .init(id: 44, email: "dev.team@proton.me"),
                                .init(id: 45, email: "development@protonmail.com"),
                                .init(id: 46, email: "dev.group@pm.me")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "E",
                items: [
                    .group(
                        .init(
                            id: 47,
                            name: "Engineering Team",
                            avatarColor: "#A1FF33",
                            contacts: [
                                .init(id: 48, email: "engineering@proton.me"),
                                .init(id: 49, email: "eng.team@protonmail.com"),
                                .init(id: 50, email: "team.engineering@yahoo.com")
                            ]
                        )
                    ),
                    .contact(
                        .init(
                            id: 51,
                            name: "Emily Edwards",
                            avatarInformation: .init(text: "EE", color: "#33FF57"),
                            emails: [
                                .init(id: 52, email: "emily.edwards@gmail.com"),
                                .init(id: 53, email: "emily.edwards@protonmail.com")
                            ]
                        )
                    ),
                    .contact(
                        .init(
                            id: 54,
                            name: "Ethan Evans",
                            avatarInformation: .init(text: "EE", color: "#3357FF"),
                            emails: [
                                .init(id: 55, email: "ethan.evans@pm.me"),
                                .init(id: 56, email: "ethan.evans@yahoo.com")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "F",
                items: [
                    .contact(
                        .init(
                            id: 57,
                            name: "Frank Foster",
                            avatarInformation: .init(text: "FF", color: "#FF5733"),
                            emails: [
                                .init(id: 58, email: "frank.foster@gmail.com"),
                                .init(id: 59, email: "frank.foster@pm.me")
                            ]
                        )
                    ),
                    .contact(
                        .init(
                            id: 60,
                            name: "Fiona Finch",
                            avatarInformation: .init(text: "FF", color: "#A1FF33"),
                            emails: [
                                .init(id: 61, email: "fiona.finch@yahoo.com"),
                                .init(id: 62, email: "fiona.finch@protonmail.com")
                            ]
                        )
                    ),
                    .group(
                        .init(
                            id: 63,
                            name: "Finance Group",
                            avatarColor: "#33FF57",
                            contacts: [
                                .init(id: 64, email: "finance.group@proton.me"),
                                .init(id: 65, email: "group.finance@pm.me"),
                                .init(id: 66, email: "finance@protonmail.com")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "G",
                items: [
                    .group(
                        .init(
                            id: 67,
                            name: "Global Partners",
                            avatarColor: "#3357FF",
                            contacts: [
                                .init(id: 68, email: "global.partners@pm.me"),
                                .init(id: 69, email: "global@protonmail.com"),
                                .init(id: 70, email: "partners.global@yahoo.com")
                            ]
                        )
                    ),
                    .contact(
                        .init(
                            id: 71,
                            name: "George Green",
                            avatarInformation: .init(text: "GG", color: "#FF33A1"),
                            emails: [
                                .init(id: 72, email: "george.green@proton.me"),
                                .init(id: 73, email: "george.green@gmail.com")
                            ]
                        )
                    ),
                    .contact(
                        .init(
                            id: 74,
                            name: "Grace Gray",
                            avatarInformation: .init(text: "GG", color: "#FF5733"),
                            emails: [
                                .init(id: 75, email: "grace.gray@yahoo.com"),
                                .init(id: 76, email: "grace.gray@pm.me")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "H",
                items: [
                    .contact(
                        .init(
                            id: 77,
                            name: "Harry Hunt",
                            avatarInformation: .init(text: "HH", color: "#A1FF33"),
                            emails: [
                                .init(id: 78, email: "harry.hunt@protonmail.com"),
                                .init(id: 79, email: "harry.hunt@gmail.com")
                            ]
                        )
                    ),
                    .group(
                        .init(
                            id: 80,
                            name: "Healthcare Team",
                            avatarColor: "#33FF57",
                            contacts: [
                                .init(id: 81, email: "health.team@proton.me"),
                                .init(id: 82, email: "team.healthcare@protonmail.com"),
                                .init(id: 83, email: "healthcare@pm.me")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "I",
                items: [
                    .group(
                        .init(
                            id: 84,
                            name: "IT Group",
                            avatarColor: "#3357FF",
                            contacts: [
                                .init(id: 85, email: "it.group@yahoo.com"),
                                .init(id: 86, email: "group.it@protonmail.com"),
                                .init(id: 87, email: "it.group@pm.me")
                            ]
                        )
                    ),
                    .contact(
                        .init(
                            id: 88,
                            name: "Ivy Irving",
                            avatarInformation: .init(text: "II", color: "#FF33A1"),
                            emails: [
                                .init(id: 89, email: "ivy.irving@gmail.com"),
                                .init(id: 90, email: "ivy.irving@pm.me")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "J",
                items: [
                    .contact(
                        .init(
                            id: 91,
                            name: "James Johnson",
                            avatarInformation: .init(text: "JJ", color: "#FF5733"),
                            emails: [
                                .init(id: 92, email: "james.johnson@yahoo.com"),
                                .init(id: 93, email: "james.johnson@protonmail.com")
                            ]
                        )
                    ),
                    .group(
                        .init(
                            id: 94,
                            name: "Journalists Team",
                            avatarColor: "#A1FF33",
                            contacts: [
                                .init(id: 95, email: "journalist.team@pm.me"),
                                .init(id: 96, email: "team.journalists@proton.me"),
                                .init(id: 97, email: "journalist@protonmail.com")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "K",
                items: [
                    .contact(
                        .init(
                            id: 98,
                            name: "Karen King",
                            avatarInformation: .init(text: "KK", color: "#33FF57"),
                            emails: [
                                .init(id: 99, email: "karen.king@proton.me"),
                                .init(id: 100, email: "karen.king@protonmail.com")
                            ]
                        )
                    ),
                    .contact(
                        .init(
                            id: 101,
                            name: "Kevin Kelly",
                            avatarInformation: .init(text: "KK", color: "#3357FF"),
                            emails: [
                                .init(id: 102, email: "kevin.kelly@gmail.com"),
                                .init(id: 103, email: "kevin.kelly@pm.me")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "L",
                items: [
                    .contact(
                        .init(
                            id: 104,
                            name: "Lisa Lewis",
                            avatarInformation: .init(text: "LL", color: "#FF33A1"),
                            emails: [
                                .init(id: 105, email: "lisa.lewis@protonmail.com"),
                                .init(id: 106, email: "lisa.lewis@yahoo.com")
                            ]
                        )
                    ),
                    .group(
                        .init(
                            id: 107,
                            name: "Legal Team",
                            avatarColor: "#A1FF33",
                            contacts: [
                                .init(id: 108, email: "legal.team@pm.me"),
                                .init(id: 109, email: "team.legal@proton.me"),
                                .init(id: 110, email: "legal@protonmail.com")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "M",
                items: [
                    .group(
                        .init(
                            id: 111,
                            name: "Marketing Team",
                            avatarColor: "#33FF57",
                            contacts: [
                                .init(id: 112, email: "marketing@pm.me"),
                                .init(id: 113, email: "team.marketing@protonmail.com"),
                                .init(id: 114, email: "marketing@proton.me")
                            ]
                        )
                    ),
                    .contact(
                        .init(
                            id: 115,
                            name: "Michael Moore",
                            avatarInformation: .init(text: "MM", color: "#3357FF"),
                            emails: [
                                .init(id: 116, email: "michael.moore@protonmail.com"),
                                .init(id: 117, email: "michael.moore@yahoo.com")
                            ]
                        )
                    ),
                    .contact(
                        .init(
                            id: 118,
                            name: "Megan Miller",
                            avatarInformation: .init(text: "MM", color: "#FF33A1"),
                            emails: [
                                .init(id: 119, email: "megan.miller@gmail.com"),
                                .init(id: 120, email: "megan.miller@proton.me")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "N",
                items: [
                    .contact(
                        .init(
                            id: 121,
                            name: "Nancy Newman",
                            avatarInformation: .init(text: "NN", color: "#33FF57"),
                            emails: [
                                .init(id: 122, email: "nancy.newman@protonmail.com"),
                                .init(id: 123, email: "nancy.newman@pm.me")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "O",
                items: [
                    .group(
                        .init(
                            id: 124,
                            name: "Operations Group",
                            avatarColor: "#3357FF",
                            contacts: [
                                .init(id: 125, email: "operations.group@proton.me"),
                                .init(id: 126, email: "group.ops@yahoo.com"),
                                .init(id: 127, email: "ops.group@pm.me")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "P",
                items: [
                    .contact(
                        .init(
                            id: 128,
                            name: "Paul Parker",
                            avatarInformation: .init(text: "PP", color: "#FF33A1"),
                            emails: [
                                .init(id: 129, email: "paul.parker@gmail.com"),
                                .init(id: 130, email: "paul.parker@protonmail.com")
                            ]
                        )
                    ),
                    .contact(
                        .init(
                            id: 131,
                            name: "Patricia Peterson",
                            avatarInformation: .init(text: "PP", color: "#FF5733"),
                            emails: [
                                .init(id: 132, email: "patricia.peterson@proton.me"),
                                .init(id: 133, email: "patricia.peterson@gmail.com")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "Q",
                items: [
                    .contact(
                        .init(
                            id: 134,
                            name: "Quincy Quinn",
                            avatarInformation: .init(text: "QQ", color: "#A1FF33"),
                            emails: [
                                .init(id: 135, email: "quincy.quinn@pm.me"),
                                .init(id: 136, email: "quincy.quinn@protonmail.com")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "R",
                items: [
                    .group(
                        .init(
                            id: 137,
                            name: "Research Group",
                            avatarColor: "#33A1FF",
                            contacts: [
                                .init(id: 138, email: "research.group@pm.me"),
                                .init(id: 139, email: "group.research@proton.me"),
                                .init(id: 140, email: "research@protonmail.com")
                            ]
                        )
                    ),
                    .contact(
                        .init(
                            id: 141,
                            name: "Rachel Reed",
                            avatarInformation: .init(text: "RR", color: "#33FF57"),
                            emails: [
                                .init(id: 142, email: "rachel.reed@gmail.com"),
                                .init(id: 143, email: "rachel.reed@protonmail.com")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "S",
                items: [
                    .contact(
                        .init(
                            id: 144,
                            name: "Sarah Scott",
                            avatarInformation: .init(text: "SS", color: "#3357FF"),
                            emails: [
                                .init(id: 145, email: "sarah.scott@yahoo.com"),
                                .init(id: 146, email: "sarah.scott@proton.me")
                            ]
                        )
                    ),
                    .contact(
                        .init(
                            id: 147,
                            name: "Sam Smith",
                            avatarInformation: .init(text: "SS", color: "#FF33A1"),
                            emails: [
                                .init(id: 148, email: "sam.smith@pm.me"),
                                .init(id: 149, email: "sam.smith@protonmail.com")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "T",
                items: [
                    .group(
                        .init(
                            id: 150,
                            name: "Tech Group",
                            avatarColor: "#A1FF33",
                            contacts: [
                                .init(id: 151, email: "tech.group@proton.me"),
                                .init(id: 152, email: "group.tech@pm.me"),
                                .init(id: 153, email: "tech@protonmail.com")
                            ]
                        )
                    ),
                    .contact(
                        .init(
                            id: 154,
                            name: "Tina Thompson",
                            avatarInformation: .init(text: "TT", color: "#FF5733"),
                            emails: [
                                .init(id: 155, email: "tina.thompson@yahoo.com"),
                                .init(id: 156, email: "tina.thompson@pm.me")
                            ]
                        )
                    ),
                    .contact(
                        .init(
                            id: 157,
                            name: "Tom Taylor",
                            avatarInformation: .init(text: "TT", color: "#33FF57"),
                            emails: [
                                .init(id: 158, email: "tom.taylor@gmail.com"),
                                .init(id: 159, email: "tom.taylor@protonmail.com")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "U",
                items: [
                    .contact(
                        .init(
                            id: 160,
                            name: "Ursula Underwood",
                            avatarInformation: .init(text: "UU", color: "#FF33A1"),
                            emails: [
                                .init(id: 161, email: "ursula.underwood@pm.me"),
                                .init(id: 162, email: "ursula.underwood@yahoo.com")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "V",
                items: [
                    .group(
                        .init(
                            id: 163,
                            name: "Visionaries Group",
                            avatarColor: "#A1FF33",
                            contacts: [
                                .init(id: 164, email: "visionaries@protonmail.com"),
                                .init(id: 165, email: "vision@proton.me"),
                                .init(id: 166, email: "group.visionaries@pm.me")
                            ]
                        )
                    ),
                    .contact(
                        .init(
                            id: 167,
                            name: "Victor Vega",
                            avatarInformation: .init(text: "VV", color: "#33FF57"),
                            emails: [
                                .init(id: 168, email: "victor.vega@protonmail.com"),
                                .init(id: 169, email: "victor.vega@proton.me")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "W",
                items: [
                    .contact(
                        .init(
                            id: 170,
                            name: "Walter White",
                            avatarInformation: .init(text: "WW", color: "#FF5733"),
                            emails: [
                                .init(id: 171, email: "walter.white@gmail.com"),
                                .init(id: 172, email: "walter.white@protonmail.com")
                            ]
                        )
                    ),
                    .group(
                        .init(
                            id: 173,
                            name: "Writers Team",
                            avatarColor: "#A1FF33",
                            contacts: [
                                .init(id: 174, email: "writers.team@pm.me"),
                                .init(id: 175, email: "team.writers@protonmail.com"),
                                .init(id: 176, email: "writers@proton.me")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "X",
                items: [
                    .contact(
                        .init(
                            id: 177,
                            name: "Xander Xavier",
                            avatarInformation: .init(text: "XX", color: "#33FF57"),
                            emails: []
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "Y",
                items: [
                    .contact(
                        .init(
                            id: 180,
                            name: "Yasmin Young",
                            avatarInformation: .init(text: "YY", color: "#FF5733"),
                            emails: [
                                .init(id: 181, email: "yasmin.young@proton.me"),
                                .init(id: 182, email: "yasmin.young@pm.me")
                            ]
                        )
                    )
                ]
            ),
            .init(
                groupedBy: "Z",
                items: [
                    .contact(
                        .init(
                            id: 183,
                            name: "Zoe Zimmerman",
                            avatarInformation: .init(text: "ZZ", color: "#A1FF33"),
                            emails: [
                                .init(id: 184, email: "zoe.zimmerman@gmail.com"),
                                .init(id: 185, email: "zoe.zimmerman@protonmail.com")
                            ]
                        )
                    ),
                    .group(
                        .init(
                            id: 186,
                            name: "Zebra Group",
                            avatarColor: "#3357FF",
                            contacts: [
                                .init(id: 187, email: "zebra.group@protonmail.com"),
                                .init(id: 188, email: "group.zebra@pm.me"),
                                .init(id: 189, email: "zebra@proton.me")
                            ]
                        )
                    )
                ]
            )
        ]
    }

}

extension ContactItem {

    init(id: UInt64, name: String, avatarInformation: AvatarInformation, emails: [ContactEmailItem]) {
        self.init(
            id: Id(value: id),
            name: name,
            avatarInformation: avatarInformation,
            emails: emails
        )
    }

}

extension ContactGroupItem {

    init(id: UInt64, name: String, avatarColor: String, contacts: [ContactEmailItem]) {
        self.init(
            id: Id(value: id),
            name: name,
            avatarColor: avatarColor,
            contacts: [
                .init(
                    id: id,
                    name: name,
                    avatarInformation: .init(text: "__NOT_USED__", color: avatarColor),
                    emails: contacts
                )
            ]
        )
    }

}

extension ContactEmailItem {

    init(id: UInt64, email: String) {
        self.init(id: Id(value: id), email: email, isProton: false, lastUsedTime: 0)
    }

}
