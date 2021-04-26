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
import SafariServices
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
    private(set) var bannerViewController: BannerViewController?
    private(set) var attachmentViewController: AttachmentViewController?

    init(viewModel: SingleMessageViewModel) {
        self.viewModel = viewModel
        self.nonExapndedHeaderViewController = NonExpandedHeaderViewController(
            viewModel: viewModel.nonExapndedHeaderViewModel
        )
        if viewModel.message.numAttachments != 0 {
            attachmentViewController = AttachmentViewController(viewModel: viewModel.attachmentViewModel)
        }
        super.init(nibName: nil, bundle: nil)
        self.messageBodyViewController =
            NewMessageBodyViewController(viewModel: viewModel.messageBodyViewModel,
                                         parentScrollView: self)
        self.messageBodyViewController.delegate = self

        self.attachmentViewController?.delegate = self
        if viewModel.message.expirationTime != nil {
            showBanner()
        }
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
        viewModel.updateErrorBanner = { [weak self] error in
            if let error = error {
                self?.showBanner()
                self?.bannerViewController?.showErrorBanner(error: error)
            } else {
                self?.bannerViewController?.hideBanner(type: .error)
            }
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
        emptyBackButtonTitleForNextView()
    }

    private func embedChildren() {
        precondition(messageBodyViewController != nil)
        embed(messageBodyViewController, inside: customView.messageBodyContainer)
        embed(nonExapndedHeaderViewController, inside: customView.messageHeaderContainer)
        if let attachmentVC = self.attachmentViewController {
            embed(attachmentVC, inside: customView.attachmentContainer)
        }
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

    private func showBanner() {
        guard self.bannerViewController == nil else { return }
        let controller = BannerViewController(viewModel: viewModel.bannerViewModel)
        controller.delegate = self
        embed(controller, inside: customView.bannerContainer)
        self.bannerViewController = controller
    }

    private func hideBanner() {
        guard let controler = self.bannerViewController else {
            return
        }
        unembed(controler)
        self.bannerViewController = nil
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
    func updateContentBanner(shouldShowRemoteContentBanner: Bool, shouldShowEmbeddedContentBanner: Bool) {
        let shouldShowRemoteContentBanner =
            shouldShowRemoteContentBanner && !viewModel.bannerViewModel.shouldAutoLoadRemoteContent
        let shouldShowEmbeddedImageBanner =
            shouldShowEmbeddedContentBanner && !viewModel.bannerViewModel.shouldAutoLoadEmbeddedImage

        showBanner()
        bannerViewController?.showContentBanner(remoteContent: shouldShowRemoteContentBanner,
                                                embeddedImage: shouldShowEmbeddedImageBanner)
    }

	func openMailUrl(_ mailUrl: URL) {
        // TODO: handle in coordinator

    }

    func openUrl(_ url: URL) {
        // TODO: Move to coordinator
        let browserSpecificUrl = viewModel.linkOpener.deeplink(to: url) ?? url
        switch viewModel.linkOpener {
        case .inAppSafari:
            let supports = ["https", "http"]
            let scheme = browserSpecificUrl.scheme ?? ""
            guard supports.contains(scheme) else {
                self.showUnsupportAlert(url: browserSpecificUrl)
                return
            }
            let safari = SFSafariViewController(url: browserSpecificUrl)
            self.present(safari, animated: true, completion: nil)
        case _ where UIApplication.shared.canOpenURL(browserSpecificUrl):
            UIApplication.shared.open(browserSpecificUrl, options: [:], completionHandler: nil)
        default:
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    func handleReload() {
        viewModel.downloadDetails()
    }

    private func showUnsupportAlert(url: URL) {
        let message = LocalString._unsupported_url
        let open = LocalString._general_open_button
        let alertController = UIAlertController(title: LocalString._general_alert_title,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: open,
                                                style: .default,
                                                handler: { _ in
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }))
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button,
                                                style: .cancel,
                                                handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}

extension SingleMessageViewController: AttachmentViewControllerDelegate {
    func openAttachmentList() {
        // TODO: Move to coordinator
        let viewModel = AttachmentListViewModel(attachments: self.viewModel.attachmentViewModel.attachments,
                                                user: self.viewModel.user)
        let viewController = AttachmentListViewController(viewModel: viewModel)
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}

extension SingleMessageViewController: BannerViewControllerDelegate {
    func hideBannerController() {
        hideBanner()
    }

    func loadEmbeddedImage() {
        viewModel.messageBodyViewModel.embeddedContentPolicy = .allowed
    }

    func handleMessageExpired() {
        self.navigationController?.popViewController(animated: true)
    }

    func loadRemoteContent() {
        viewModel.messageBodyViewModel.remoteContentPolicy = WebContents.RemoteContentPolicy.allowed.rawValue
    }
}
