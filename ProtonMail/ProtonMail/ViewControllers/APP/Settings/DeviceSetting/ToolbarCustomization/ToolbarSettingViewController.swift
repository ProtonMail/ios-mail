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

import LifetimeTracker
import ProtonCore_UIFoundations
import UIKit

final class ToolbarSettingViewController: UIViewController, LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }

    let customView = ToolbarSettingView()
    let viewModel: ToolbarSettingViewModel
    private(set) var currentViewController: ToolbarCustomizeViewController<MessageViewActionSheetAction>?

    init(viewModel: ToolbarSettingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        title = LocalString._toolbar_customize_general_title
        trackLifetime()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBarItems()
        setupSegmentControl()
        customView.segmentControl.selectedSegmentIndex = 0
        showMessageToolbarView()
    }

    private func setupSegmentControl() {
        customView.segmentControl.addTarget(self, action: #selector(segmentValueChanged), for: .valueChanged)
    }

    private func setupNavigationBarItems() {
        let done = UIBarButtonItem(title: LocalString._general_done_button,
                                   style: .plain,
                                   target: self,
                                   action: #selector(doneButtonIsTapped))
        done.tintColor = ColorProvider.BrandNorm
        navigationItem.rightBarButtonItem = done
    }

    private func showMessageToolbarView() {
        currentViewController?.removeFromParent()
        let viewController = ToolbarCustomizeViewController(
            viewModel: viewModel.currentViewModeToolbarCustomizeViewModel,
            shouldHideInfoView: true
        )
        addToContainerView(of: viewController.view)
        addChild(viewController)
        currentViewController = viewController
        updateInfoText()
    }

    private func showInboxToolbarView() {
        currentViewController?.removeFromParent()
        let viewController = ToolbarCustomizeViewController(
            viewModel: viewModel.listViewToolbarCustomizeViewModel,
            shouldHideInfoView: true
        )
        addToContainerView(of: viewController.view)
        addChild(viewController)
        currentViewController = viewController
        updateInfoText()
    }

    private func addToContainerView(of view: UIView) {
        customView.containerView.subviews.forEach { $0.removeFromSuperview() }
        customView.containerView.addSubview(view)
        view.fillSuperview()
    }

    private func updateInfoText() {
        let segment = customView.segmentControl.selectedSegmentIndex
        let title = viewModel.infoViewTitle(segment: segment)
        let label = customView.infoBubbleView.subviews
            .compactMap({ $0 as? UILabel }).first
        var attribute = FontManager.CaptionWeak
        attribute[.font] = UIFont.adjustedFont(forTextStyle: .footnote)
        label?.attributedText = title.apply(style: attribute)
    }

    // MARK: - Actions

    @objc
    private func doneButtonIsTapped() {
        showProgressHud()
        viewModel.save { [weak self] in
            self?.navigationController?.popViewController(animated: true)
            self?.hideProgressHud()
        }
    }

    @objc
    private func segmentValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            showMessageToolbarView()
        case 1:
            showInboxToolbarView()
        default:
            assertionFailure("Should not have more than two options")
        }
    }
}
