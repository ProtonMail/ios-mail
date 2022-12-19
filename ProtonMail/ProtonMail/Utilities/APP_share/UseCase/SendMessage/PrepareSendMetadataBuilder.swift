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
import ProtonCore_Services

enum PrepareSendMetadataBuilder {

    static func make(
        userData: UserDataSource,
        apiService: APIService,
        cacheService: CacheServiceProtocol,
        contactProvider: ContactProviderProtocol
    ) -> PrepareSendMetadata {
        // ResolveSendPreferencesUseCase
        let fetchContactsDependencies: FetchAndVerifyContacts.Dependencies = .init(
            apiService: apiService,
            cacheService: cacheService,
            contactProvider: contactProvider
        )
        let fetchPublicKeyDependencies: FetchEmailAddressesPublicKey.Dependencies = .init(apiService: apiService)
        let sendPreferencesDependencies: ResolveSendPreferences.Dependencies = .init(
            fetchVerifiedContacts: FetchAndVerifyContacts(
                currentUser: userData.userID,
                currentUserKeys: userData.userPrivateKeys,
                dependencies: fetchContactsDependencies
            ),
            fetchAddressesPublicKeys: FetchEmailAddressesPublicKey(dependencies: fetchPublicKeyDependencies)
        )
        let resolveSendPreferences = ResolveSendPreferences(dependencies: sendPreferencesDependencies)

        // FetchAttachmentUseCase
        let fetchAttachmentDependencies: FetchAttachment.Dependencies = .init(apiService: apiService)

        // PrepareSendMetadataUseCase
        let sendMetadatDependencies: PrepareSendMetadata.Dependencies = .init(
            userDataSource: userData,
            resolveSendPreferences: resolveSendPreferences,
            fetchAttachment: FetchAttachment(dependencies: fetchAttachmentDependencies)
        )
        return PrepareSendMetadata(dependencies: sendMetadatDependencies)
    }
}
