//
//  SingleMessageViewController.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import PMUIFoundations
import UIKit

class SingleMessageViewController: UIViewController, UIScrollViewDelegate {

    private(set) lazy var customView = SingleMessageView()
    private lazy var navigationTitleLabel = SingleMessageNavigationHeaderView()

    private let viewModel: SingleMessageViewModel
    private lazy var starBarButton = UIBarButtonItem(
        image: nil,
        style: .plain,
        target: self,
        action: #selector(starButtonTapped)
    )

    let messageBodyViewController: NewMessageBodyViewController
    let nonExapndedHeaderViewController: NonExpandedHeaderViewController

    init(viewModel: SingleMessageViewModel) {
        self.viewModel = viewModel
        self.messageBodyViewController = NewMessageBodyViewController(viewModel: viewModel.messageBodyViewModel)
        self.nonExapndedHeaderViewController = NonExpandedHeaderViewController(
            viewModel: viewModel.nonExapndedHeaderViewModel
        )
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.viewDidLoad()
        viewModel.refreshView = { [weak self] in
            self?.reloadMessageRelatedData()
        }
        setUpSelf()
        embedChildren()
    }

    private func embedChildren() {
        embed(messageBodyViewController, inside: customView.messageBodyContainer)
        embed(nonExapndedHeaderViewController, inside: customView.messageHeaderContainer)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.markReadIfNeeded()
        viewModel.userActivity.becomeCurrent()
    }

    private func reloadMessageRelatedData() {
        starButtonSetUp(starred: viewModel.message.starred)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        viewModel.userActivity.invalidate()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.reloadAfterRotation()
        }
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let shouldShowSeparator = scrollView.contentOffset.y >= customView.smallTitleHeaderSeparatorView.frame.maxY
        let shouldShowTitleInNavigationBar = scrollView.contentOffset.y >= customView.titleLabel.frame.maxY

        customView.navigationSeparator.isHidden = !shouldShowSeparator
        shouldShowTitleInNavigationBar ? showTitleView() : hideTitleView()
    }

    // MARK: - Private

    private func setUpSelf() {
        customView.titleLabel.attributedText = viewModel.messageTitle
        navigationTitleLabel.label.attributedText = viewModel.message.title.apply(style: .DefaultSmallStrong)
        navigationTitleLabel.label.lineBreakMode = .byTruncatingTail

        customView.navigationSeparator.isHidden = true
        customView.scrollView.delegate = self
        navigationTitleLabel.label.alpha = 0

        navigationItem.rightBarButtonItem = starBarButton
        navigationItem.titleView = navigationTitleLabel
        starButtonSetUp(starred: viewModel.message.starred)
    }

    private func starButtonSetUp(starred: Bool) {
        starBarButton.image = starred ?
            Asset.messageDeatilsStarActive.image : Asset.messageDetailsStarInactive.image
        starBarButton.tintColor = starred ? UIColorManager.NotificationWarning : UIColorManager.IconWeak
    }

    @objc
    private func starButtonTapped() {
        viewModel.starTapped()
    }

    private func reloadAfterRotation() {
        scrollViewDidScroll(customView.scrollView)
    }

    private func showTitleView() {
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.navigationTitleLabel.label.alpha = 1
        }
    }

    private func hideTitleView() {
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.navigationTitleLabel.label.alpha = 0
        }
    }

    required init?(coder: NSCoder) {
        nil
    }

}

extension SingleMessageViewController: Deeplinkable {

    var deeplinkNode: DeepLink.Node {
        return DeepLink.Node(
            name: String(describing: SingleMessageViewController.self),
            value: viewModel.message.messageID
        )
    }

}
