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
import ProtonCoreServices

enum PrepareSendMetadataBuilder {
    typealias Dependencies = HasFetchAndVerifyContactsUseCase
    & HasFetchAttachmentUseCase
    & HasFetchEmailAddressesPublicKey

    static func make(userData: UserDataSource, dependencies: Dependencies) -> PrepareSendMetadata {
        let sendPreferencesDependencies: ResolveSendPreferences.Dependencies = .init(
            fetchVerifiedContacts: dependencies.fetchAndVerifyContacts,
            fetchAddressesPublicKeys: dependencies.fetchEmailAddressesPublicKey
        )
        let resolveSendPreferences = ResolveSendPreferences(dependencies: sendPreferencesDependencies)

        // PrepareSendMetadataUseCase
        let sendMetadatDependencies: PrepareSendMetadata.Dependencies = .init(
            userDataSource: userData,
            resolveSendPreferences: resolveSendPreferences,
            fetchAttachment: dependencies.fetchAttachment
        )
        return PrepareSendMetadata(dependencies: sendMetadatDependencies)
    }
}
