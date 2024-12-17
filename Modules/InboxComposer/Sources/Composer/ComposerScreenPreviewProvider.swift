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

enum ComposerScreenPreviewProvider {

    static func makeRandom(suffix: String) -> RecipientUIModel {
        switch [RecipientType.single, .single, .single, .group].randomElement()! {
        case .single: return makeRandomSingleRecipient(suffix: suffix)
        case .group: return makeRandomGroup(suffix: suffix)
        }
    }

    static func makeRandomSingleRecipient(suffix: String) -> RecipientUIModel {
        let address = ["john.doe_\(suffix)@apple.com", "laura.stern_\(suffix)@gmail.com", "mike2318.smith12398\(suffix)@protonmail.com", "anna\(suffix)@pm.me", "Hillary Scott <hey_hs_\(suffix)@gmail.com>", "Brandon <brandon_234\(suffix)@proton.me>", "andy_\(suffix)@proton.ch"].randomElement()!

        return RecipientUIModel(
            composerRecipient: .single(
                .init(
                    displayName: "",
                    address: address,
                    validState: .valid
                )
            )
        )
    }

    static func makeRandomGroup(suffix: String) -> RecipientUIModel {
        return RecipientUIModel(
            composerRecipient: .group(
                .init(
                    displayName: ["Family_\(suffix)", "Gym_\(suffix) 🏋️‍♂️", "Football team with work colleagues \(suffix)", "🏖️ college trip \(suffix)"].randomElement()!,
                    recipients: [],
                    totalContactsInGroup: 0
                )
            )
        )
    }
}
