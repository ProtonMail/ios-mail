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

import Combine
import ProtonCoreDataModel
import ProtonCoreFeatures
import ProtonInboxRSVP

extension AnswerInvitationUseCase {
    struct UserPreContactsProvider: UserPreContactsProviding {
        private let fetchAndVerifyContacts: FetchAndVerifyContactsUseCase
        // remove this dependency if/when `sign` property is added to ProtonCoreDataModel.User
        private let user: UserManager

        init(fetchAndVerifyContacts: FetchAndVerifyContactsUseCase, user: UserManager) {
            self.fetchAndVerifyContacts = fetchAndVerifyContacts
            self.user = user
        }

        func preContacts(for user: User, recipients: [String]) -> AnyPublisher<[ProtonCoreFeatures.PreContact], Error> {
            assert(user.ID == self.user.userInfo.userId)

            let params = FetchAndVerifyContacts.Parameters(emailAddresses: recipients)

            return Future { completion in
                self.fetchAndVerifyContacts.execute(params: params) { result in
                    let mappedResult = result.map { mailPreContacts in
                        mailPreContacts.map { mailPreContact in
                            let mimeEnabledPGPSchemes: [PGPScheme] = [.pgpMIME, .cleartextMIME]

                            let isSigned: Bool
                            switch mailPreContact.sign {
                            case .doNotSign:
                                isSigned = false
                            case .sign:
                                isSigned = true
                            case .signingFlagNotFound:
                                isSigned = self.user.userInfo.sign == 1
                            }

                            return ProtonCoreFeatures.PreContact(
                                email: mailPreContact.email,
                                pubKey: mailPreContact.pgpKeys.first,
                                pubKeys: mailPreContact.pgpKeys,
                                isSigned: isSigned,
                                isEncrypted: mailPreContact.encrypt,
                                hasMime: mimeEnabledPGPSchemes.contains { "\($0.rawValue)" == mailPreContact.scheme },
                                isPlainText: mailPreContact.mimeType?.lowercased()
                                ==
                                Message.MimeType.textPlain.rawValue
                            )
                        }
                    }

                    completion(mappedResult)
                }
            }
            .eraseToAnyPublisher()
        }
    }
}
