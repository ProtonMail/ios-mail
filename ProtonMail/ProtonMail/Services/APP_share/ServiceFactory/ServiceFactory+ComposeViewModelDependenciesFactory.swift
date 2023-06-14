// Copyright (c) 2023 Proton Technologies AG
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

protocol ComposeViewModelDependenciesFactory {
    func makeViewModelDependencies(user: UserManager) -> ComposeViewModel.Dependencies
}

extension ServiceFactory {
    private struct ComposeViewModelFactory: ComposeViewModelDependenciesFactory {
        private let factory: ServiceFactory

        init(factory: ServiceFactory) {
            self.factory = factory
        }

        func makeViewModelDependencies(user: UserManager) -> ComposeViewModel.Dependencies {
            .init(
                coreDataContextProvider: factory.get(),
                coreKeyMaker: factory.get(),
                fetchAndVerifyContacts: FetchAndVerifyContacts(
                    user: user
                ),
                internetStatusProvider: factory.get(),
                fetchAttachment: FetchAttachment(dependencies: .init(apiService: user.apiService)),
                contactProvider: user.contactService,
                helperDependencies: .init(
                    messageDataService: user.messageService,
                    cacheService: user.cacheService,
                    contextProvider: factory.get(),
                    copyMessage: CopyMessage(
                        dependencies: .init(
                            contextProvider: factory.get(),
                            messageDecrypter: user.messageService.messageDecrypter
                        ),
                        userDataSource: user
                    )
                ),
                fetchMobileSignatureUseCase: FetchMobileSignature(
                    dependencies: .init(
                        coreKeyMaker: factory.get(),
                        cache: factory.userCachedStatus
                    )
                ), darkModeCache: factory.userCachedStatus
            )
        }
    }

    func makeComposeViewModelDependenciesFactory() -> ComposeViewModelDependenciesFactory {
        ComposeViewModelFactory(factory: self)
    }
}
