// Copyright (c) 2022 Proton AG
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
import ProtonCore_DataModel
import ProtonCore_Services

/// Given a list of email addresses returns a PreContact object, for each address that exist in contacts
/// and has custom send preferences (e.g. a different public key, a specific PGP scheme,
/// sign messages, ...
///
/// - If the Contact information contains sending preferences and the contact is not stored in the local cache,
/// the use case fecthes the information and updates the cache before returning data.
/// - If a fetching contact request fails, the error is ignored and that Contact won't be returned.
/// - Contacts that fail verification of their digital signature are ignored and not returned.
protocol FetchAndVerifyContactsUseCase: UseCase {
    func execute(emailAddresses: [String], callback: ([PreContact]) -> Void)
}

final class FetchAndVerifyContacts: FetchAndVerifyContactsUseCase {
    private let params: Parameters
    private let dependencies: Dependencies

    init(params: Parameters, dependencies: Dependencies) {
        self.params = params
        self.dependencies = dependencies
    }

    func execute(emailAddresses: [String], callback: ([PreContact]) -> Void) {
        assert(!Thread.isMainThread, "Use case has blocking operations, make sure to run it on a background thread")
        let emails = dependencies.contactProvider.getEmailsByAddress(emailAddresses, for: params.currentUser)
        let emailsMissingSendingPreferences = emails.filter { !$0.isContactDownloaded && $0.hasSendingPreferences }
        fetchContactDetailsAndUpdateCache(for: emailsMissingSendingPreferences) { [weak self] _ in
            let preContacts = self?.verifiedContacts(for: emails) ?? []
            callback(preContacts)
        }
    }
}

extension FetchAndVerifyContacts {

    private func verifiedContacts(for emails: [EmailEntity]) -> [PreContact] {
        let cardParser = CardDataParser(userKeys: params.currentUserKeys)
        let contactEntities = dependencies.contactProvider.getContactsByIds(emails.map(\.contactID.rawValue))
        var results = [PreContact]()
        emails.forEach { emailEntity in
            var preContact: PreContact?
            let contactEntity = contactEntities.first(where: {
                $0.emailRelations.contains(where: { $0.email == emailEntity.email })
            })
            if let contactEntity = contactEntity {
                preContact = cardParser.verifyAndParseContact(with: emailEntity.email, from: contactEntity.cardDatas)
                if let preContact = preContact {
                    results.append(preContact)
                }
            }
        }
        return results
    }

    /// For all given emails it makes a request to fetch the contact details. If the request is successful it updates
    /// the local storage. Returns an array of ContactEntities corresponding to the array of EmailEntities passed.
    private func fetchContactDetailsAndUpdateCache(for emails: [EmailEntity], callback: ([ContactEntity]) -> Void) {
        let serialQueue = DispatchQueue(label: "com.protonmail.FetchAndVerifyContacts")
        let uniqueContactIds = Array(Set(emails.map(\.contactID.rawValue)))
        let group = DispatchGroup()
        var contactEntities = [ContactEntity]()

        guard !emails.isEmpty else {
            callback([])
            return
        }

        uniqueContactIds.forEach { [weak self] contactId in
            guard let self = self else { return }
            group.enter()
            self.fetchAndUpdate(contactId: contactId) { result in
                serialQueue.sync {
                    switch result {
                    case .success(let contactEntity):
                        contactEntities.append(contactEntity)
                    case .failure:
                        break
                    }
                }
                group.leave()
            }
        }
        group.wait()

        callback(contactEntities)
    }

    /// Makes a request to fetch the contact details. If the request is successful it updates the local cache
    private func fetchAndUpdate(contactId: String, callback: @escaping (Result<ContactEntity, NSError>) -> Void) {
        let request = ContactDetailRequest(cid: contactId)
        dependencies
            .apiService
            .exec(route: request, responseObject: ContactDetailResponse()) { [weak self] _, response in
                guard let self = self else { return }
                switch self.mapResponseToResult(response) {
                case .success(let contactDictionary):
                    self.updateContact(response: contactDictionary) { result in
                        switch result {
                        case .success(let contactEntity):
                            callback(.success(contactEntity))
                        case .failure(let error):
                            callback(.failure(error))
                        }
                    }
                case .failure(let error):
                    callback(.failure(error))
                }
            }
    }

    private func mapResponseToResult(_ response: ContactDetailResponse) -> Result<[String: Any], NSError> {
        if let error = response.error {
            return .failure(error.toNSError)
        } else if let contactDict = response.contact {
            return .success(contactDict)
        } else {
            return .failure(NSError.unableToParseResponse(response))
        }
    }

    private func updateContact(response: [String: Any], callback: @escaping (Result<ContactEntity, NSError>) -> Void) {
        dependencies.cacheService.updateContactDetail(serverResponse: response) { contact, error in
            if let contact = contact {
                let contactEntity = ContactEntity(contact: contact)
                callback(.success(contactEntity))
            } else if let error = error {
                callback(.failure(error))
            } else {
                fatalError("updateContactDetail result inconsistent state")
            }
        }
    }
}

extension FetchAndVerifyContacts {

    struct Parameters {
        let currentUser: UserID
        let currentUserKeys: [Key]
    }

    struct Dependencies {
        let apiService: APIService
        let cacheService: CacheServiceProtocol
        let contactProvider: ContactProviderProtocol

        init(apiService: APIService, cacheService: CacheServiceProtocol, contactProvider: ContactProviderProtocol) {
            self.apiService = apiService
            self.cacheService = cacheService
            self.contactProvider = contactProvider
        }
    }
}
