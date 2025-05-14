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

final class ComposerViewFactory {
    typealias Dependencies = AnyObject
    & ComposeContainerViewModel.Dependencies
    & ComposeContainerViewController.Dependencies
    & HasUserManager
    & HasInternetConnectionStatusProviderProtocol
    & HasKeychain
    & HasKeyMakerProtocol
    & HasUserCachedStatus
    & HasFetchAttachmentUseCase
    & HasUserDefaults

    private unowned let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func makeComposer(
        subject: String,
        body: String,
        files: [FileData],
        navigationViewController: UINavigationController
    ) -> ComposeContainerViewController {
        let childViewModel = ComposeViewModel(
            subject: subject,
            body: body,
            files: files,
            action: .newDraftFromShare,
            dependencies: composeViewModelDependencies
        )

        let router = ComposerRouter()
        let controller = makeContainerViewController(childViewModel: childViewModel, router: router)
        router.setupNavigation(navigationViewController)
        return controller
    }

    func makeComposer(
        msg: MessageEntity?,
        action: ComposeMessageAction,
        remoteContentPolicy: WebContents.RemoteContentPolicy? = nil,
        embeddedContentPolicy: WebContents.EmbeddedContentPolicy? = nil,
        isEditingScheduleMsg: Bool = false,
        mailToUrl: URL? = nil,
        toContact: ContactPickerModelProtocol? = nil,
        originalScheduledTime: Date? = nil,
        composerDelegate: ComposeContainerViewControllerDelegate? = nil
    ) -> UINavigationController {
        let list: [ComposeMessageAction] = [.reply, .replyAll, .replyAll]
        if list.contains(action),
           remoteContentPolicy == nil,
           embeddedContentPolicy == nil {
            PMAssertionFailure("For these type should provide policy")
        }
        let userInfo = dependencies.user.userInfo
        let defaultRemotePolicy: WebContents.RemoteContentPolicy
        defaultRemotePolicy = userInfo.hideRemoteImages == 1 ? .disallowed : .allowedWithoutProxy
        let defaultEmbeddedPolicy: WebContents.EmbeddedContentPolicy
        defaultEmbeddedPolicy = userInfo.hideEmbeddedImages == 1 ? .disallowed : .allowed
        let childViewModel = ComposeViewModel(
            isEditingScheduleMsg: isEditingScheduleMsg,
            originalScheduledTime: originalScheduledTime,
            remoteContentPolicy: remoteContentPolicy ?? defaultRemotePolicy,
            embeddedContentPolicy: embeddedContentPolicy ?? defaultEmbeddedPolicy,
            dependencies: composeViewModelDependencies
        )

        do {
            try childViewModel.initialize(message: msg, action: action)
        } catch {
            PMAssertionFailure(error)
        }

        if let url = mailToUrl {
            childViewModel.parse(mailToURL: url)
        }

        if let toContact = toContact {
            childViewModel.addToContacts(toContact)
        }

        let router = ComposerRouter()
        let controller = makeContainerViewController(childViewModel: childViewModel, router: router)
        controller.delegate = composerDelegate
        let navigationVC = UINavigationController(rootViewController: controller)
        router.setupNavigation(navigationVC)
        navigationVC.modalPresentationStyle = .pageSheet
        return navigationVC
    }

    private func makeContainerViewController(
        childViewModel: ComposeViewModel,
        router: ComposerRouter
    ) -> ComposeContainerViewController {
        let viewModel = ComposeContainerViewModel(
            router: router,
            dependencies: dependencies,
            editorViewModel: childViewModel
        )

        return ComposeContainerViewController(viewModel: viewModel, dependencies: dependencies)
    }

    var composeViewModelDependencies: ComposeViewModel.Dependencies {
        return .init(
            user: dependencies.user,
            coreDataContextProvider: dependencies.contextProvider,
            fetchAndVerifyContacts: FetchAndVerifyContacts(
                user: dependencies.user
            ),
            internetStatusProvider: dependencies.internetConnectionStatusProvider,
            keychain: dependencies.keychain,
            fetchAttachment: dependencies.fetchAttachment,
            contactProvider: dependencies.user.contactService,
            helperDependencies: .init(
                messageDataService: dependencies.user.messageService,
                cacheService: dependencies.user.cacheService,
                contextProvider: dependencies.contextProvider,
                copyMessage: CopyMessage(
                    dependencies: .init(
                        contextProvider: dependencies.contextProvider,
                        messageDecrypter: dependencies.user.messageService.messageDecrypter
                    ),
                    userDataSource: dependencies.user
                )
            ),
            fetchMobileSignatureUseCase: FetchMobileSignature(
                dependencies: .init(
                    coreKeyMaker: dependencies.keyMaker,
                    cache: dependencies.userCachedStatus,
                    keychain: dependencies.keychain
                )
            ),
            userDefaults: dependencies.userDefaults,
            notificationCenter: NotificationCenter.default
        )
    }
}
