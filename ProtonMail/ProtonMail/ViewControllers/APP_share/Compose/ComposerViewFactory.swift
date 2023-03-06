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
        scheduleSendStatusProvider: ScheduleSendEnableStatusProvider,
        internetStatusProvider: InternetConnectionStatusProvider,
        navigationViewController: UINavigationController
    ) -> ComposeContainerViewController {
        let childViewModel = ComposeViewModel(
            subject: subject,
            body: body,
            files: files,
            action: .newDraftFromShare,
            msgService: user.messageService,
            user: user,
            coreDataContextProvider: contextProvider,
            internetStatusProvider: internetStatusProvider
        )
        let router = ComposerRouter()
        router.setupNavigation(navigationViewController)
        let viewModel = ComposeContainerViewModel(
            router: router,
            editorViewModel: childViewModel,
            userIntroductionProgressProvider: userIntroductionProgressProvider,
            scheduleSendStatusProvider: scheduleSendStatusProvider
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
        scheduleSendEnableStatusProvider: ScheduleSendEnableStatusProvider,
        internetStatusProvider: InternetConnectionStatusProvider,
        mailToUrl: URL? = nil,
        toContact: ContactPickerModelProtocol? = nil
    ) -> UINavigationController {
        let childViewModel = ComposeViewModel(
            msg: msg,
            action: action,
            msgService: user.messageService,
            user: user,
            coreDataContextProvider: contextProvider,
            internetStatusProvider: internetStatusProvider,
            isEditingScheduleMsg: isEditingScheduleMsg
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
            userIntroductionProgressProvider: userIntroductionProgressProvider,
            scheduleSendEnableStatusProvider: scheduleSendEnableStatusProvider
        )
    }

    static func makeComposer(
        childViewModel: ComposeViewModel,
        contextProvider: CoreDataContextProviderProtocol,
        userIntroductionProgressProvider: UserIntroductionProgressProvider,
        scheduleSendEnableStatusProvider: ScheduleSendEnableStatusProvider
    ) -> UINavigationController {
        let router = ComposerRouter()
        let viewModel = ComposeContainerViewModel(
            router: router,
            editorViewModel: childViewModel,
            userIntroductionProgressProvider: userIntroductionProgressProvider,
            scheduleSendStatusProvider: scheduleSendEnableStatusProvider
        )
        let controller = ComposeContainerViewController(
            viewModel: viewModel,
            contextProvider: contextProvider)
        let navigationVC = UINavigationController(rootViewController: controller)
        router.setupNavigation(navigationVC)
        return navigationVC
    }
}
