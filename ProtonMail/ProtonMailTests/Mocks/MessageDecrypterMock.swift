// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import CoreData
import Foundation
@testable import ProtonMail

final class MessageDecrypterMock: MessageDecrypterProtocol {
    func decrypt(message: Message) throws -> String {
        return "Test body"
    }
    
    func copy(message: Message, copyAttachments: Bool, context: NSManagedObjectContext) -> Message {
        return message
    }

    func verify(message: MessageEntity, verifier: [Data]) -> SignatureVerificationResult {
        return .ok
    }
    
    func decrypt(message: MessageEntity) throws -> (String?, [MimeAttachment]?) {
        return (nil, nil)
    }
}
