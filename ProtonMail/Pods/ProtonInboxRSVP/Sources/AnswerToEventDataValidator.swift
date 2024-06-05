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

import ProtonCoreDataModel

public struct AnswerToEventDataValidator {

    public struct Data {
        public let calendarEvent: CalendarEvent
        public let addressKeyPackage: AddressKeyPackage

        public init(calendarEvent: CalendarEvent, addressKeyPackage: AddressKeyPackage) {
            self.calendarEvent = calendarEvent
            self.addressKeyPackage = addressKeyPackage
        }
    }

    private let userStorage: CurrentUserStorage
    private let eventStorage: EventStorage
    private let passphraseStorage: UserPassphraseStorage

    public init(
        userStorage: CurrentUserStorage,
        eventStorage: EventStorage,
        passphraseStorage: UserPassphraseStorage
    ) {
        self.userStorage = userStorage
        self.eventStorage = eventStorage
        self.passphraseStorage = passphraseStorage
    }

    public func validationResult(
        for event: IdentifiableEvent,
        addressKeys: [AddressKey_v2]
    ) -> Result<AnswerToEventDataValidator.Data, AnswerInvitationUseCaseError> {
        guard let calendarEvent = eventStorage.calendarEvent(for: event) else {
            return .failure(.missingEvent)
        }

        guard let user = userStorage.user else {
            return .failure(.missingUser)
        }

        guard let userPassphrase = passphraseStorage.userPassphrase else {
            return .failure(.missingUserPassphrase)
        }

        guard let addressKeyPackage = AddressKeyPackage(addressKeys, user, userPassphrase) else {
            return .failure(.missingPrimaryAddressKey)
        }

        return .success(.init(calendarEvent: calendarEvent, addressKeyPackage: addressKeyPackage))
    }

}

private extension AddressKeyPackage {

    init?(_ keys: [AddressKey_v2], _ user: User, _ userPassphrase: String) {
        self.init(keys: keys, passphraseInfo: .init(user: user, userPassphrase: userPassphrase))
    }

}
