//
//  LabelManagerCoordinator.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCore_DataModel
import UIKit

protocol LabelManagerRouterProtocol {

    func navigateToLabelEdit(
        editMode: LabelEditMode,
        labels: [MenuLabel],
        type: PMLabelType,
        userInfo: UserInfo,
        labelService: LabelsDataService
    )
}

final class LabelManagerRouter: LabelManagerRouterProtocol {
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    // TODO: Use business model object instead of MenuLabel
    func navigateToLabelEdit(
        editMode: LabelEditMode,
        labels: [MenuLabel],
        type: PMLabelType,
        userInfo: UserInfo,
        labelService: LabelsDataService
    ) {
        let dependencies = LabelEditViewModel.Dependencies(userInfo: userInfo, labelService: labelService)
        let labelEditNavigationController = LabelEditStackBuilder.make(
            editMode: editMode,
            type: type,
            labels: labels,
            dependencies: dependencies,
            coordinatorDismissalObserver: nil
        )

        navigationController.present(labelEditNavigationController, animated: true)
    }
}
