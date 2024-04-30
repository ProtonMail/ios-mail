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
import ProtonCoreDataModel
import ProtonCoreServices

public struct AutoAddedEventKeyPacketUploader {

    private let eventKeyPacketUpdater: EventKeyPacketUpdating
    private let calendarKeyStorage: CalendarKeyStorage

    public init(
        eventKeyPacketUpdater: EventKeyPacketUpdating,
        calendarKeyStorage: CalendarKeyStorage
    ) {
        self.eventKeyPacketUpdater = eventKeyPacketUpdater
        self.calendarKeyStorage = calendarKeyStorage
    }

    public func uploadReEncryptedKeyPacket(
        addressKeyPacket: String,
        for event: IdentifiableEvent,
        decryptionPackage: AddressKeyPackage
    ) -> AnyPublisher<Void, Error> {
        guard let activePrimaryCalendarKey = activePrimaryCalendarKey(for: event) else {
            return Fail(error: AnswerInvitationUseCaseError.missingActivePrimaryCalendarKey).eraseToAnyPublisher()
        }

        guard let reEncryptedSessionKeyWithCalendarKey = try? AddressKeyPacketReEncryptor.reEncryptedKeyPacket(
            addressKeyPacket: addressKeyPacket,
            withCalendarKey: activePrimaryCalendarKey,
            decryptionPackage: decryptionPackage
        ) else {
            return Fail(error: AnswerInvitationUseCaseError.reEncryptionFailed).eraseToAnyPublisher()
        }

        return eventKeyPacketUpdater.updateSharedKeyPacket(
            with: reEncryptedSessionKeyWithCalendarKey,
            calendarID: event.calendarID,
            eventID: event.id
        )
    }

    private func activePrimaryCalendarKey(for event: IdentifiableEvent) -> CalendarKey? {
        calendarKeyStorage.activeKeys(calendarID: event.calendarID)?.activePrimaryKey
    }

}
