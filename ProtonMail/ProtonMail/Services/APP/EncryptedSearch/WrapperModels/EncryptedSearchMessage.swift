// Copyright (c) 2022 Proton Technologies AG
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
import GoLibs

class EncryptedSearchMessage: EncryptedsearchMessage {
    let messageID: String?
    let labelIDs: String?

    init?(
        _ idValue: String?,
        timeValue: Int,
        orderValue: Int,
        labelIDsValue: String?,
        encryptedValue: EncryptedSearchEncryptedMessageContent?,
        decryptedValue: EncryptedSearchDecryptedMessageContent?
    ) {
        self.messageID = idValue
        self.labelIDs = labelIDsValue
        super.init(idValue,
                   timeValue: Int64(timeValue),
                   orderValue: Int64(orderValue),
                   labelidsValue: labelIDsValue,
                   encryptedValue: encryptedValue,
                   decryptedValue: decryptedValue)
    }
}
