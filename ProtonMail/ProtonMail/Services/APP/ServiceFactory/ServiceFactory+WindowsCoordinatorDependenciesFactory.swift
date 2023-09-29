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
import ProtonCore_Keymaker

protocol WindowsCoordinatorDependenciesFactory {
    func makeWindowsCoordinatorDependencies() -> WindowsCoordinator.Dependencies
    func makeMenuCoordinator(sideMenu: PMSideMenuController) -> MenuCoordinator
    func makeLockCoordinator(finishLockFlow: @escaping (LockCoordinator.FlowResult) -> Void) -> LockCoordinator
}

extension ServiceFactory {
    private struct WindowsCoordinatorFactory: WindowsCoordinatorDependenciesFactory {
        private let factory: ServiceFactory

        init(factory: ServiceFactory) {
            self.factory = factory
        }

        func makeWindowsCoordinatorDependencies() -> WindowsCoordinator.Dependencies {
            .init(
                usersManager: factory.get(),
                pushService: factory.get(),
                queueManager: factory.get(),
                unlockManager: factory.get(),
                darkModeCache: factory.userCachedStatus,
                lockCache: factory.get(by: KeyMakerProtocol.self),
                notificationCenter: factory.get(),
                coreKeyMaker: factory.get()
            )
        }

        func makeMenuCoordinator(sideMenu: PMSideMenuController) -> MenuCoordinator {
            let menuWidth = MenuViewController.calcProperMenuWidth()
            let coordinator = MenuCoordinator(
                services: factory,
                pushService: factory.get(),
                coreDataService: factory.get(),
                lastUpdatedStore: factory.get(),
                usersManager: factory.get(),
                queueManager: factory.get(),
                // TODO: pass the dependencies properly through the entire chain
                // swiftlint:disable:next force_cast
                dependencies: (UIApplication.shared.delegate as! AppDelegate).dependencies,
                sideMenu: sideMenu,
                menuWidth: menuWidth
            )
            return coordinator
        }

        func makeLockCoordinator(finishLockFlow: @escaping (LockCoordinator.FlowResult) -> Void) -> LockCoordinator {
            .init(
                dependencies: .init(
                    unlockManager: factory.get(),
                    usersManager: factory.get(),
                    pinFailedCountCache: factory.userCachedStatus
                ),
                finishLockFlow: finishLockFlow
            )
        }
    }

    func makeWindowsCoordinatorDependenciesFactory() -> WindowsCoordinatorDependenciesFactory {
        WindowsCoordinatorFactory(factory: self)
    }
}
