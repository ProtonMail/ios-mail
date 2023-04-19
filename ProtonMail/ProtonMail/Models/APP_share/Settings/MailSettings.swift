// Copyright (c) 2023 Proton Technologies AG
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

struct MailSettings: Parsable, Equatable {
    let nextMessageOnMove: Bool
    let hideSenderImages: Bool

    enum CodingKeys: String, CodingKey {
        case nextMessageOnMove = "NextMessageOnMove"
        case hideSenderImages = "HideSenderImages"
    }

    init(
        nextMessageOnMove: Bool = DefaultValue.nextMessageOnMove,
        hideSenderImages: Bool = DefaultValue.hideSenderImages
    ) {
        self.nextMessageOnMove = nextMessageOnMove
        self.hideSenderImages = hideSenderImages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nextMessageOnMove = container
            .decodeIfPresentBoolOrIntToBool(forKey: .nextMessageOnMove, defaultValue: DefaultValue.nextMessageOnMove)
        hideSenderImages = container.decodeIfPresentBoolOrIntToBool(
            forKey: .hideSenderImages,
            defaultValue: DefaultValue.hideSenderImages
        )
    }

    struct DefaultValue {
        static let nextMessageOnMove = false
        static let hideSenderImages = false
    }
}

// sourcery: mock
protocol MailSettingsHandler: AnyObject {
    var mailSettings: MailSettings { get set }
}

extension UserManager: MailSettingsHandler {}
