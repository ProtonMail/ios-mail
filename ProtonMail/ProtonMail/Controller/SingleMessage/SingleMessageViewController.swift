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
    private var contentOffsetToPerserve: CGPoint = .zero

    private let viewModel: SingleMessageViewModel
    private lazy var starBarButton = UIBarButtonItem(
        image: nil,
        style: .plain,
        target: self,
        action: #selector(starButtonTapped)
    )

    private(set) var messageBodyViewController: NewMessageBodyViewController!
    let nonExapndedHeaderViewController: NonExpandedHeaderViewController
    let bannerViewController: BannerViewController

    init(viewModel: SingleMessageViewModel) {
        self.viewModel = viewModel
        self.nonExapndedHeaderViewController = NonExpandedHeaderViewController(
            viewModel: viewModel.nonExapndedHeaderViewModel
        )
        self.bannerViewController = BannerViewController(viewModel: viewModel.bannerViewModel)

        super.init(nibName: nil, bundle: nil)
        self.messageBodyViewController =
            NewMessageBodyViewController(viewModel: viewModel.messageBodyViewModel,
                                         parentScrollView: self)
        self.messageBodyViewController.delegate = self

        self.bannerViewController.delegate = self
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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

        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(restoreOffset),
                                                   name: UIWindowScene.willEnterForegroundNotification,
                                                   object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(saveOffset),
                                                   name: UIWindowScene.didEnterBackgroundNotification,
                                                   object: nil)
        } else {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(restoreOffset),
                                                   name: UIApplication.willEnterForegroundNotification,
                                                   object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(saveOffset),
                                                   name: UIApplication.didEnterBackgroundNotification,
                                                   object: nil)
        }

        setUpSelf()
        embedChildren()
    }

    private func embedChildren() {
        precondition(messageBodyViewController != nil)
        embed(messageBodyViewController, inside: customView.messageBodyContainer)
        embed(nonExapndedHeaderViewController, inside: customView.messageHeaderContainer)
        embed(bannerViewController, inside: customView.bannerContainer)
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

extension SingleMessageViewController: ScrollableContainer {
    var scroller: UIScrollView {
        return self.customView.scrollView
    }

    func propogate(scrolling delta: CGPoint, boundsTouchedHandler: () -> Void) {
        let scrollView = customView.scrollView
        UIView.animate(withDuration: 0.001) { // hackish way to show scrolling indicators on tableView
            scrollView.flashScrollIndicators()
        }
        let maxOffset = scrollView.contentSize.height - scrollView.frame.size.height
        guard maxOffset > 0 else { return }

        let yOffset = scrollView.contentOffset.y + delta.y

        if yOffset < 0 { // not too high
            scrollView.setContentOffset(.zero, animated: false)
            boundsTouchedHandler()
        } else if yOffset > maxOffset { // not too low
            scrollView.setContentOffset(.init(x: 0, y: maxOffset), animated: false)
            boundsTouchedHandler()
        } else {
            scrollView.contentOffset = .init(x: 0, y: yOffset)
        }
    }

    @objc
    func saveOffset() {
        self.contentOffsetToPerserve = scroller.contentOffset
    }

    @objc
    func restoreOffset() {
        scroller.setContentOffset(self.contentOffsetToPerserve, animated: false)
    }
}

extension SingleMessageViewController: NewMessageBodyViewControllerDelegate {
    func updateRemoteContentBanner(shouldShow: Bool) {
        if shouldShow && !viewModel.bannerViewModel.shouldAutoLoadRemoteContent {
            bannerViewController.showRemoteContentBanner()
        }
    }

    func openUrl(_ url: URL) {
        // TODO: handle open web url/ mailto url here
    }

    func handleReload() {
        viewModel.downloadDetails()
    }
}

extension SingleMessageViewController: BannerViewControllerDelegate {
    func loadRemoteContent() {
        viewModel.messageBodyViewModel.remoteContentPolicy = WebContents.RemoteContentPolicy.allowed.rawValue
    }
}
