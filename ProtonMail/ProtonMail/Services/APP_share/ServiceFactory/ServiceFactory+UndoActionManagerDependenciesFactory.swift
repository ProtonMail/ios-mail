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
import ProtonCore_Services
import UIKit

protocol UndoActionManagerDependenciesFactory {
    func makeDependencies(apiService: APIService) -> UndoActionManager.Dependencies
    func makeComposer(user: UserManager, message: Message) -> UINavigationController
}

extension ServiceFactory {
    private struct UndoActionManagerFactory: UndoActionManagerDependenciesFactory {
        private let factory: ServiceFactory

        init(factory: ServiceFactory) {
            self.factory = factory
        }

        func makeDependencies(apiService: APIService) -> UndoActionManager.Dependencies {
            .init(
                contextProvider: factory.get(),
                apiService: apiService
            )
        }

        func makeComposer(user: UserManager, message: Message) -> UINavigationController {
            ComposerViewFactory.makeComposer(
                msg: message,
                action: .openDraft,
                user: user,
                contextProvider: factory.get(),
                isEditingScheduleMsg: false,
                userIntroductionProgressProvider: userCachedStatus,
                internetStatusProvider: factory.get(),
                coreKeyMaker: factory.get()
            )
        }
    }

    func makeUndoActionManagerDependenciesFactory() -> UndoActionManagerDependenciesFactory {
        UndoActionManagerFactory(factory: self)
    }
}
