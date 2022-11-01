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

import UIKit

enum LabelEditStackBuilder {
    static func make(
        editMode: LabelEditMode,
        type: PMLabelType,
        labels: [MenuLabel],
        dependencies: LabelEditViewModel.Dependencies,
        coordinatorDismissalObserver: CoordinatorDismissalObserver?
    ) -> UINavigationController {
        let navigationController = UINavigationController()

        let router = LabelEditRouter(
            navigationController: navigationController,
            coordinatorDismissalObserver: coordinatorDismissalObserver
        )
        let viewModel = LabelEditViewModel(
            router: router,
            editMode: editMode,
            type: type,
            labels: labels,
            dependencies: dependencies
        )
        let viewController = LabelEditViewController(viewModel: viewModel)
        if #available(iOS 13.0, *) {
            viewController.isModalInPresentation = true
        }

        navigationController.setViewControllers([viewController], animated: false)
        return navigationController
    }
}
