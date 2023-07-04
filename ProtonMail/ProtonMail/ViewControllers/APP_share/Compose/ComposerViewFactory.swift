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

import UIKit

struct ComposerViewFactory {
    // swiftlint:disable function_parameter_count
    static func makeComposer(
        subject: String,
        body: String,
        files: [FileData],
        user: UserManager,
        contextProvider: CoreDataContextProviderProtocol,
        userIntroductionProgressProvider: UserIntroductionProgressProvider,
        internetStatusProvider: InternetConnectionStatusProvider,
        coreKeyMaker: KeyMakerProtocol,
        darkModeCache: DarkModeCacheProtocol,
        mobileSignatureCache: MobileSignatureCacheProtocol,
        attachmentMetadataStrippingCache: AttachmentMetadataStrippingProtocol,
        navigationViewController: UINavigationController
    ) -> ComposeContainerViewController {
        let childViewModel = ComposeViewModel(
            subject: subject,
            body: body,
            files: files,
            action: .newDraftFromShare,
            msgService: user.messageService,
            user: user,
            dependencies: .init(
                coreDataContextProvider: contextProvider,
                coreKeyMaker: coreKeyMaker,
                fetchAndVerifyContacts: FetchAndVerifyContacts(user: user),
                internetStatusProvider: internetStatusProvider,
                fetchAttachment: FetchAttachment(dependencies: .init(apiService: user.apiService)),
                contactProvider: user.contactService,
                helperDependencies: .init(
                    messageDataService: user.messageService,
                    cacheService: user.cacheService,
                    contextProvider: contextProvider,
                    copyMessage: CopyMessage(
                        dependencies: .init(
                            contextProvider: contextProvider,
                            messageDecrypter: user.messageService.messageDecrypter
                        ),
                        userDataSource: user
                    )
                ), fetchMobileSignatureUseCase: FetchMobileSignature(
                    dependencies: .init(
                        coreKeyMaker: coreKeyMaker,
                        cache: mobileSignatureCache
                    )
                ),
                darkModeCache: darkModeCache,
                attachmentMetadataStrippingCache: attachmentMetadataStrippingCache
            )
        )
        let router = ComposerRouter()
        router.setupNavigation(navigationViewController)
        let viewModel = ComposeContainerViewModel(
            router: router,
            editorViewModel: childViewModel,
            userIntroductionProgressProvider: userIntroductionProgressProvider,
            contextProvider: contextProvider
        )
        let controller = ComposeContainerViewController(
            viewModel: viewModel,
            contextProvider: contextProvider
        )
        return controller
    }

    // swiftlint:disable function_parameter_count
    static func makeComposer(
        msg: Message?,
        action: ComposeMessageAction,
        user: UserManager,
        contextProvider: CoreDataContextProviderProtocol,
        isEditingScheduleMsg: Bool,
        userIntroductionProgressProvider: UserIntroductionProgressProvider,
        internetStatusProvider: InternetConnectionStatusProviderProtocol,
        coreKeyMaker: KeyMakerProtocol,
        darkModeCache: DarkModeCacheProtocol,
        mobileSignatureCache: MobileSignatureCacheProtocol,
        attachmentMetadataStrippingCache: AttachmentMetadataStrippingProtocol,
        mailToUrl: URL? = nil,
        toContact: ContactPickerModelProtocol? = nil,
        originalScheduledTime: Date? = nil
    ) -> UINavigationController {
        let childViewModel = ComposeViewModel(
            msg: msg,
            action: action,
            msgService: user.messageService,
            user: user,
            isEditingScheduleMsg: isEditingScheduleMsg,
            originalScheduledTime: originalScheduledTime,
            dependencies: .init(
                coreDataContextProvider: contextProvider,
                coreKeyMaker: coreKeyMaker,
                fetchAndVerifyContacts: FetchAndVerifyContacts(user: user),
                internetStatusProvider: internetStatusProvider,
                fetchAttachment: FetchAttachment(dependencies: .init(apiService: user.apiService)),
                contactProvider: user.contactService,
                helperDependencies: .init(
                    messageDataService: user.messageService,
                    cacheService: user.cacheService,
                    contextProvider: contextProvider,
                    copyMessage: CopyMessage(
                        dependencies: .init(
                            contextProvider: contextProvider,
                            messageDecrypter: user.messageService.messageDecrypter
                        ),
                        userDataSource: user
                    )
                ), fetchMobileSignatureUseCase: FetchMobileSignature(
                    dependencies: .init(
                        coreKeyMaker: coreKeyMaker,
                        cache: mobileSignatureCache
                    )
                ),
                darkModeCache: darkModeCache,
                attachmentMetadataStrippingCache: attachmentMetadataStrippingCache
            )
        )
        if let url = mailToUrl {
            childViewModel.parse(mailToURL: url)
        }
        if let toContact = toContact {
            childViewModel.addToContacts(toContact)
        }
        return Self.makeComposer(
            childViewModel: childViewModel,
            contextProvider: contextProvider,
            userIntroductionProgressProvider: userIntroductionProgressProvider
        )
    }

    static func makeComposer(
        childViewModel: ComposeViewModel,
        contextProvider: CoreDataContextProviderProtocol,
        userIntroductionProgressProvider: UserIntroductionProgressProvider
    ) -> UINavigationController {
        let router = ComposerRouter()
        let viewModel = ComposeContainerViewModel(
            router: router,
            editorViewModel: childViewModel,
            userIntroductionProgressProvider: userIntroductionProgressProvider,
            contextProvider: contextProvider
        )
        let controller = ComposeContainerViewController(
            viewModel: viewModel,
            contextProvider: contextProvider)
        let navigationVC = UINavigationController(rootViewController: controller)
        router.setupNavigation(navigationVC)
        return navigationVC
    }
}
