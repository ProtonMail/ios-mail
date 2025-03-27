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

import UIKit
import SwiftUI
import ProtonCoreLoginUI

final class SettingsViewsFactory {
    typealias Dependencies = AnyObject
    & SettingsDeviceViewModel.Dependencies
    & SettingsSwipeActionSelectViewModelImpl.Dependencies
    & HasUserCachedStatus

    private unowned let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func makeDeviceView(coordinator: SettingsDeviceCoordinator) -> SettingsDeviceViewController {
        let viewModel = SettingsDeviceViewModel(dependencies: dependencies)
        return SettingsDeviceViewController(viewModel: viewModel, coordinator: coordinator)
    }

    func makeContactCombineView() -> SwitchToggleViewController {
        let viewModel = ContactCombineViewModel(userDefaults: dependencies.userDefaults)
        return SwitchToggleViewController(viewModel: viewModel)
    }

    func makeNetworkSettingView() -> SwitchToggleViewController {
        let viewModel = NetworkSettingViewModel(
            userDefaults: dependencies.userDefaults,
            dohSetting: BackendConfiguration.shared.doh
        )
        return SwitchToggleViewController(viewModel: viewModel)
    }

    func makeGesturesView(coordinator: SettingsGesturesCoordinator) -> SettingsGesturesViewController {
        let viewModel = SettingsGestureViewModelImpl(
            cache: dependencies.userCachedStatus,
            swipeActionInfo: dependencies.user.userInfo
        )
        return SettingsGesturesViewController(viewModel: viewModel, coordinator: coordinator)
    }

    func makeSwipeActionSelectView(selectedAction: SwipeActionItems) -> SettingsSwipeActionSelectController {
        let viewModel = SettingsSwipeActionSelectViewModelImpl(
            dependencies: dependencies,
            selectedAction: selectedAction
        )
        return SettingsSwipeActionSelectController(viewModel: viewModel)
    }

    func makeDarkModeSettingView() -> SettingsSingleCheckMarkViewController {
        let viewModel = DarkModeSettingViewModel(userDefaults: dependencies.userDefaults)
        return SettingsSingleCheckMarkViewController(viewModel: viewModel)
    }

    func makeApplicationLogsView() -> ApplicationLogsViewController {
        let viewModel = ApplicationLogsViewModel()
        return ApplicationLogsViewController(viewModel: viewModel)
    }

    func makeMessageSwipeNavigationView() -> SwitchToggleViewController {
        let viewModel = MessageSwipeNavigationViewModel(userDefaults: dependencies.userDefaults)
        return SwitchToggleViewController(viewModel: viewModel)
    }

    @MainActor
    func makeScanQRCodeInstructionsView() -> ShowingNavigationBarUIHostingController {
        let passphrase = dependencies.user.mailboxPassword.value
        return ShowingNavigationBarUIHostingController(
            rootView: AnyView(ScanQRCodeInstructionsView(
                viewModel: .init(dependencies: .init(passphrase: passphrase))))
        )
    }
}

class ShowingNavigationBarUIHostingController: UIHostingController<AnyView> {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false
    }
}
