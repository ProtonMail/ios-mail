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

import ProtonCoreFeatures
import ProtonInboxRSVP

extension AnswerInvitationUseCase {
    typealias Dependencies = HasAPIService
    & HasEmailAddressStorage
    & HasFetchAndVerifyContactsUseCase
    & HasUserManager
    & RecipientProvider.Dependencies

    init(dependencies: Dependencies, answeringContext: AnsweringContext) {
        let calendarAPIService = CalendarAPIService(apiService: dependencies.apiService)

        self.init(
            emailSender: MailFeature(apiService: dependencies.apiService),
            localization: L10nProvider(),
            dateFormatterProvider: DateFormatterProvider(),
            currentDateProvider: CurrentDateProvider(),
            attendeeStorage: InMemoryAttendeeStorage(attendeeTransformers: answeringContext.attendeeTransformers),
            calendarKeyStorage: InMemoryCalendarKeyStorage(keyTransformers: answeringContext.keyTransformers),
            emailAddressStorage: dependencies.emailAddressStorage,
            eventStorage: InMemorySingleEventEventStorage(
                iCalEvent: answeringContext.iCalEvent,
                eventType: answeringContext.eventType
            ),
            passphraseStorage: UserManagerBasedUserPassphraseStorage(user: dependencies.user),
            userStorage: UserBasedCurrentUserStorage(user: dependencies.user),
            eventKeyPacketUpdater: calendarAPIService,
            eventParticipationStatusUpdater: calendarAPIService,
            eventPersonalPartUpdater: calendarAPIService,
            userPreContactsProvider: UserPreContactsProvider(
                fetchAndVerifyContacts: dependencies.fetchAndVerifyContacts,
                user: dependencies.user
            ),
            vTimeZonesInfoProvider: calendarAPIService,
            recipientProvider: RecipientProvider(dependencies: dependencies)
        )
    }
}
