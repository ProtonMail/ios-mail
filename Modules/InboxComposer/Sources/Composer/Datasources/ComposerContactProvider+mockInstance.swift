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

import Foundation
import SwiftUI

struct ComposerMockContactsDatasource: ComposerContactsDatasource {
    private var randomColor: Color {
        [.green, .blue, .purple, .orange, .red].randomElement()!
    }

    func allContacts() async -> [ComposerContact] {
        var contacts: [ComposerContact] = []

        for (index, _) in (1...120_000).enumerated() {
            let email = "\(Self.emailPrefix.randomElement()!)_\(index)\(Self.emailDomain.randomElement()!)"
            let name = Bool.random() ? "\(Self.names.randomElement()!)" : email
            let contactType = ComposerContactType.single(
                ComposerContactSingle(
                    initials: email.first!.description.uppercased(),
                    name: name,
                    email: email
                )
            )
            contacts.append(ComposerContact(type: contactType, avatarColor: randomColor))
        }
        let groups = [
            ComposerContactType.group(ComposerContactGroup(name: "Core Team", totalMembers: 4)),
            ComposerContactType.group(ComposerContactGroup(name: "The Gang", totalMembers: 6)),
            ComposerContactType.group(ComposerContactGroup(name: "Football on Thursdays", totalMembers: 15)),
            ComposerContactType.group(ComposerContactGroup(name: "Family", totalMembers: 8)),
            ComposerContactType.group(ComposerContactGroup(name: "Operations", totalMembers: 10))
        ]
        for group in groups {
            contacts.append(ComposerContact(type: group, avatarColor: randomColor))
        }

        contacts.sort {
            let first = $0.type.nameOrEmail
            let second = $1.type.nameOrEmail
            return first.localizedCompare(second) == .orderedAscending
        }
        return contacts
    }
}

private extension ComposerContactType {
    var nameOrEmail: String {
        switch self {
        case .single(let single):
            return single.name
        case .group(let group):
            return group.name
        }
    }
}

private extension ComposerMockContactsDatasource {
    static let names = [
        "Aaron", "Aaron Anderson Baker", "Aaron B.", "Aaron Davis", "Aaron Dr.",
        "Aaron Garcia", "Aaron Garcia Young", "Aaron Johnson Evans", "Aaron Martinez",
        "Aaron Martinez Evans", "Aaron Rodriguez", "Aaron Rodriguez Allen", "Aaron Taylor",
        "Abel", "Abel Rodriguez", "Abigail", "Abigail Anderson",
        "Abigail Clark", "Abigail Clark Baker", "Abigail Davis", "Abigail Davis Green",
        "Abigail Garcia", "Abigail Garcia Green", "Abigail Garcia Rivera", "Abigail Harris Evans",
        "Abigail Johnson", "Abigail Johnson Green", "Abigail Martinez", "Ana Rodriguez",
        "Anna Taylor Collins", "Anne Taylor Green", "Alex", "Alexander", "Alexander Anderson",
        "Alexander Anderson Collins", "Alexander Clark", "Alexander Davis", "Alexander Garcia",
        "Alexander Harris", "Alexander Harris Rivera", "Alexander Martinez Allen", "Alexander Rodriguez",
        "Alexander Rodriguez Collins", "Alexander Rodriguez Rivera", "Alexander Taylor Baker", "Amelia",
        "Amelia Brown Allen", "Amelia Brown Lee", "Amelia Clark", "Amelia Davis", "Amelia Davis Evans",
        "Amelia Garcia Allen", "Amelia Harris", "Amelia Hernandez Evans", "Amelia Johnson", "Amelia Taylor",
        "Amelia Taylor Young", "Ben", "Benjamin", "Benjamin Anderson Allen", "Benjamin Brown",
        "Benjamin Clark", "Benjamin Clark Walker", "Benjamin Davis", "Benjamin Costa", "Benjamin Garcia Rivera",
        "Benjamin Garcia Young", "Benjamin Harris Lee", "Benjamin Johnson", "Benjamin Johnson Evans",
        "Benjamin Rodriguez", "Benjamin Rodriguez Young", "Benjamin Taylor", "Benjamin Taylor Walker",
        "Caroline", "Caroline Anderson Collins", "Caroline Anderson Evans", "Caroline Brown",
        "Caroline Brown Evans", "Caroline Clark", "Caroline Garcia", "Caroline Harris", "Caroline Johnson",
        "Caroline Martinez", "Caroline Martinez Walker", "Caroline Rodriguez Collins", "Caroline Rodriguez Rivera",
        "Caroline Taylor", "Charlie", "Charlotte", "Charlotte Anderson", "Charlotte Anderson Evans",
        "Charlotte Brown Collins", "Charlotte Clark", "Charlotte Clark Allen", "Charlotte Clark Green",
        "Charlotte Clark Rivera", "Charlotte Davis", "Charlotte Davis Lee", "Charlotte Davis Parker",
        "Charlotte Harris", "Charlotte Harris Evans", "Charlotte Johnson", "Charlotte Rodriguez", "Daniel",
        "Daniel Brown", "Daniel Brown Rivera", "Daniel Clark Allen", "Daniel Davis Green", "Daniel Garcia Collins",
        "Daniel Garcia Rivera", "Daniel Harris Young", "Daniel Johnson Baker", "Daniel Martinez Baker",
        "Daniel Martinez Green", "Daniel Martinez Lee", "Daniel Rodriguez", "Daniel Rodriguez Allen",
        "Daniel Taylor Young", "Danny", "Elijah", "Elijah Brown", "Elijah Brown Green", "Elijah Clark",
        "Elijah Garcia Green", "Elijah Harris", "Elijah Harris Allen", "Elijah Harris Collins", "Elijah Harris Walker",
        "Elijah Johnson Baker", "Elijah Martinez", "Elijah Rodriguez Green", "Elijah Taylor Collins", "Ellie", "Emma",
        "Emma Anderson", "Emma Anderson Evans", "Emma Anderson Young", "Emma Brown", "Emma Davis Allen",
        "Emma Davis Evans", "Emma Davis Rivera", "Emma Garcia", "Emma Garcia Rivera", "Emma Garcia Walker",
        "Emma Harris Collins", "Emma Harris Green", "Emma Harris Young", "Emma Johnson Walker", "Emma Martinez",
        "Emma Martinez Baker", "Emma Martinez Collins", "Emma Martinez Lee", "Emma Rodriguez Allen",
        "Emma Taylor Walker", "Evelyn", "Evelyn Brown", "Evelyn Clark Green", "Evelyn Davis", "Evelyn Garcia",
        "Evelyn Harris", "Evelyn Johnson", "Evelyn Johnson Baker", "Evelyn Johnson Collins", "Evelyn Johnson Green",
        "Evelyn Martinez Evans", "Evelyn Martinez Young", "Evelyn Rodriguez Baker", "Henry", "Henry Brown",
        "Henry Clark Lee", "Henry Davis", "Henry Garcia", "Henry Garcia Collins", "Henry Harris Allen",
        "Henry Johnson", "Henry Martinez Allen", "Henry Martinez Rivera", "Henry Rodriguez Collins", "Henry Taylor",
        "Henry Taylor Allen", "Henry Taylor Evans", "Henry Taylor Young", "I. Abrahams", "Isabella Anderson",
        "Isabella Brown", "Isabella Davis", "Isabella Davis Lee", "Isabella Garcia", "Isabella Harris Collins",
        "Isabella Johnson Collins", "Isabella Martinez", "Isabella Martinez Evans", "Isabella Martinez Green",
        "Isabella Martinez Rivera", "Isabella Martinez Walker", "Isabella Rodriguez", "Isabella Taylor", "James",
        "James Davis", "James Davis Parker", "James Garcia", "James Garcia Rivera", "James Johnson Collins",
        "James Martinez", "James Martinez Lee", "James Rodriguez Green", "James Taylor", "Liz", "Lucas",
        "Lucas Anderson", "Lucas Anderson Walker", "Lucas Brown", "Lucas Brown Baker", "Lucas Clark", "Lucas Clark Evans",
        "Lucas Davis Allen", "Lucas Garcia", "Lucas Harris", "Lucas Johnson", "Lucas Martinez", "Lucas Rodriguez Collins",
        "Lucas Taylor", "Maddie", "Mia", "Mia Anderson Young", "Mia Brown", "Mia Brown Evans", "Mia Clark Allen",
        "Mia Davis", "Mia Davis Green", "Mia Garcia", "Mia Harris", "Mia Johnson", "Mia Johnson Allen", "Mia Taylor",
        "Mia Taylor Baker", "Nate", "Olivia", "Olivia Brown", "Olivia Brown Green", "Olivia Garcia", "Olivia Garcia Rivera",
        "Olivia Harris Collins", "Olivia Harris Young", "Olivia Johnson Rivera", "Olivia Martinez", "Olivia Martinez Green",
        "Olivia Taylor", "Sam", "Sophia", "Sophia Anderson", "Sophia Anderson Baker", "Sophia Anderson Evans",
        "Sophia Anderson Young", "Sophia Brown", "Sophia Brown Baker", "Sophia Brown Evans", "Sophia Clark", "Sophia Davis",
        "Sophia Davis Lee", "Sophia Garcia", "Sophia Johnson Collins", "Sophia Martinez", "Sophia Martinez Allen",
        "Sophia Martinez Parker", "Sophia Rodriguez Collins", "Sophia Taylor", "Toby", "William", "William Anderson Evans",
        "William Anderson Parker", "William Brown", "William Brown Collins", "William Brown Evans", "William Clark",
        "William Davis Parker", "William Garcia Allen", "William Garcia Collins", "William Garcia Green",
        "William Harris Young", "William Johnson", "William Johnson Rivera", "William Johnson Young", "William Martinez",
        "William Rodriguez", "William Rodriguez Green", "William Taylor", "William Taylor Evans", "Zoe", "Zoe Brown",
        "Zoe Brown Collins", "Zoe Brown Rivera", "Zoe Davis", "Zoe Davis Evans", "Zoe Harris Parker", "Zoe Harris Rivera",
        "Zoe Johnson Green", "Zoe Martinez", "Zoe Taylor"
    ]

    static let emailPrefix = [
        "aaron.brown", "aaron.clark", "aaron.harris", "aaron.hernandez",
         "aaron.miller", "abel.rodriguez", "abigail.allen", "abigail.hall",
         "abigail.martin", "abigail.martinez", "abigail.miller", "abigail.taylor",
         "abigail.young", "alexander.clark", "alexander.davis", "alexander.garcia",
         "alexander.hall", "alexander.martin", "amelia.davis", "amelia.gonzalez",
         "amelia.hall", "amelia.hernandez", "amelia.lopez", "amelia.martin",
         "amelia.rodriguez", "amelia.taylor", "amelia.wilson", "benjamin.clark",
         "benjamin.garcia", "benjamin.hernandez", "benjamin.martin", "caroline.clark",
         "caroline.hall", "caroline.rodriguez", "caroline.smith", "caroline.taylor",
         "charlotte.davis", "charlotte.garcia", "charlotte.gonzalez", "charlotte.harris",
         "charlotte.hernandez", "charlotte.rodriguez", "daniel.clark", "daniel.hall",
         "daniel.johnson", "daniel.martin", "daniel.martinez", "elijah.anderson",
         "elijah.miller", "elijah.smith", "emma.hall", "emma.johnson",
         "emma.rodriguez", "emma.young", "eve.anderson", "evelyn.gonzalez",
         "evelyn.hall", "evelyn.hernandez", "evely.martin", "henry.allen",
         "henry.clark", "henry.davis", "henry.hall", "henry.johnson",
         "henry.rodriguez", "isabella.garcia", "isabella.harris", "isabella.lopez",
         "isabella.wilson", "isabella.young", "james.allen", "james.brown",
         "james.gonzalez", "james.martin", "james.miller", "lucas.allen",
         "lucas.anderson", "lucas.brown", "lucas.hall", "lucas.harris",
         "lucas.martin", "lucas.martinez", "lucas.smith", "mia.davis",
         "mia.garcia", "mia.gonzalez", "olivia.anderson", "olivia.clark",
         "olivia.lopez", "olivia.wilson", "sophia.allen", "sophia.clark",
         "sophia.hall", "sophia.johnson", "sophia.smith", "sophia.wilson",
         "sophia.young", "william.clark", "william.davis", "william.martinez"
    ]

    static let emailDomain = [
        "@gmail.com", "@proton.me", "@yahoo.jp", "@outlook.com", "@hotmail.com", "@proton.me", "@icloud.com", "@zoho.com"
    ]
}
