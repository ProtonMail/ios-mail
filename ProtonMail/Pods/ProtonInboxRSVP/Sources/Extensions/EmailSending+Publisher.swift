// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Technologies AG and Proton Calendar.
//
// Proton Calendar is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Calendar is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Calendar. If not, see https://www.gnu.org/licenses/.

import Combine
import ProtonCoreCrypto
import ProtonCoreDataModel
import ProtonCoreFeatures
import ProtonCoreNetworking

public extension EmailSending {

    func send(
        content: MessageContent,
        userKeys: [Key],
        addressKeys: [Key],
        senderName: String,
        senderEmail: String,
        password: Passphrase,
        contacts: [PreContact],
        auth: AuthCredential?
    ) -> AnyPublisher<Void, Error> {
        Deferred {
            Future { promise in
                send(
                    content: content,
                    userKeys: userKeys,
                    addressKeys: addressKeys,
                    senderName: senderName,
                    senderAddr: senderEmail,
                    password: password,
                    contacts: contacts,
                    auth: auth
                ) { _, _, error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }

}
