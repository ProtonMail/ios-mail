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

import SafariServices
import ProtonCore_UIFoundations
import UIKit

class SingleMessageViewController: UIViewController, UIScrollViewDelegate, ComposeSaveHintProtocol {

    let viewModel: SingleMessageViewModel

    private lazy var navigationTitleLabel = SingleMessageNavigationHeaderView()
    private var contentOffsetToPerserve: CGPoint = .zero

    private let coordinator: SingleMessageCoordinator
    private lazy var starBarButton = UIBarButtonItem(
        image: nil,
        style: .plain,
        target: self,
        action: #selector(starButtonTapped)
    )

    private var isExpandingHeader = false

    private(set) lazy var customView = SingleMessageView()

    private(set) var messageBodyViewController: NewMessageBodyViewController!
    private(set) var bannerViewController: BannerViewController?
    private(set) var attachmentViewController: AttachmentViewController?

    private lazy var actionSheetPresenter = MessageViewActionSheetPresenter()
    private var actionBar: PMActionBar?
    private lazy var moveToActionSheetPresenter = MoveToActionSheetPresenter()
    private lazy var labelAsActionSheetPresenter = LabelAsActionSheetPresenter()

    var headerViewController: UIViewController {
        didSet {
            changeHeader(oldController: oldValue, newController: headerViewController)
        }
    }

    init(coordinator: SingleMessageCoordinator, viewModel: SingleMessageViewModel) {
        self.coordinator = coordinator
        self.viewModel = viewModel

        if viewModel.message.numAttachments != 0 {
            attachmentViewController = AttachmentViewController(viewModel: viewModel.attachmentViewModel)
        }

        self.headerViewController = {
            if let nonExpandedHeaderViewModel = viewModel.nonExapndedHeaderViewModel {
                return NonExpandedHeaderViewController(viewModel: nonExpandedHeaderViewModel)
            }
            return UIViewController()
        }()
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

        addObservations()
        setUpSelf()
        embedChildren()
        emptyBackButtonTitleForNextView()
        setUpExpandAction()
        showActionBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.markReadIfNeeded()
        viewModel.userActivity.becomeCurrent()
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

    @objc
    private func expandButton() {
        guard isExpandingHeader == false else { return }
        viewModel.isExpanded.toggle()
    }

    private func addObservations() {
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

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(networkStatusUpdated(_:)),
                                               name: NSNotification.Name.reachabilityChanged,
                                               object: nil)
    }

    private func setUpExpandAction() {
        customView.messageHeaderContainer.expandArrowControl.addTarget(
            self,
            action: #selector(expandButton),
            for: .touchUpInside
        )
    }

    private func embedChildren() {
        precondition(messageBodyViewController != nil)
        embed(messageBodyViewController, inside: customView.messageBodyContainer)
        embed(headerViewController, inside: customView.messageHeaderContainer.contentContainer)

        viewModel.embedExpandedHeader = { [weak self] viewModel in
            let viewController = ExpandedHeaderViewController(viewModel: viewModel)
            viewController.contactTapped = {
                self?.presentActionSheet(context: $0)
            }
            self?.headerViewController = viewController
        }

        viewModel.embedNonExpandedHeader = { [weak self] viewModel in
            self?.headerViewController = NonExpandedHeaderViewController(viewModel: viewModel)
        }

        if let attachmentViewController = self.attachmentViewController {
            embed(attachmentViewController, inside: customView.attachmentContainer)
        }
    }

    private func presentActionSheet(context: ExpandedHeaderContactContext) {
        let actionSheet = PMActionSheet.messageDetailsContact(for: context.type) { [weak self] action in
            self?.dismissActionSheet()
            self?.handleAction(context: context, action: action)
        }
        actionSheet.presentAt(navigationController ?? self, hasTopConstant: false, animated: true)
    }

    private func handleAction(context: ExpandedHeaderContactContext, action: MessageDetailsContactActionSheetAction) {
        switch action {
        case .addToContacts:
            coordinator.navigate(to: .contacts(contact: context.contact))
        case .composeTo:
            coordinator.navigate(to: .compose(contact: context.contact))
        case .copyAddress:
            UIPasteboard.general.string = context.contact.email
        case .copyName:
            UIPasteboard.general.string = context.contact.name
        case .close:
            break
        }
    }

    private func reloadMessageRelatedData() {
        starButtonSetUp(starred: viewModel.message.starred)
    }

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
        guard self.bannerViewController == nil && !children.contains(where: { $0 is BannerViewController }) else {
            return
        }
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

    private func showActionBar() {
        guard self.actionBar == nil else {
            return
        }

        let actions = viewModel.getActionTypes()
        var actionBarItems: [PMActionBarItem] = []
        for (key, action) in actions.enumerated() {
            let actionHandler: (PMActionBarItem) -> Void = { [weak self] _ in
                switch action {
                case .more:
                    self?.moreButtonTapped()
                case .reply:
                    self?.coordinator.navigate(to: .reply)
                case .replyAll:
                    self?.coordinator.navigate(to: .replyAll)
                case .delete:
                    self?.showDeleteAlert(deleteHandler: { [weak self] _ in
                        self?.viewModel.handleActionBarAction(action)
                        self?.navigationController?.popViewController(animated: true)
                    })
                default:
                    self?.viewModel.handleActionBarAction(action)
                    self?.navigationController?.popViewController(animated: true)
                }
            }

            let actionBarItem: PMActionBarItem
            if key == actions.startIndex {
                actionBarItem = PMActionBarItem(icon: action.iconImage,
                                                text: action.name,
                                                handler: actionHandler)
            } else {
                actionBarItem = PMActionBarItem(icon: action.iconImage,
                                                backgroundColor: .clear,
                                                handler: actionHandler)
            }
            actionBarItems.append(actionBarItem)
        }
        let separator = PMActionBarItem(width: 1,
                                        verticalPadding: 6,
                                        color: UIColorManager.FloatyText)
        actionBarItems.insert(separator, at: 1)
        self.actionBar = PMActionBar(items: actionBarItems,
                                     backgroundColor: UIColorManager.FloatyBackground,
                                     floatingHeight: 42.0,
                                     width: .fit,
                                     height: 48.0)
        self.actionBar?.show(at: self)
    }

    private func showDeleteAlert(deleteHandler: ((UIAlertAction) -> Void)?) {
        let alert = UIAlertController(title: LocalString._warning,
                                      message: LocalString._messages_will_be_removed_irreversibly,
                                      preferredStyle: .alert)
        let yes = UIAlertAction(title: LocalString._general_delete_action, style: .destructive, handler: deleteHandler)
        let cancel = UIAlertAction(title: LocalString._general_cancel_button, style: .cancel)
        [yes, cancel].forEach(alert.addAction)

        self.present(alert, animated: true, completion: nil)
    }

    private func showPhishingAlert(reportHandler: ((UIAlertAction) -> Void)?) {
        let alert = UIAlertController(title: LocalString._confirm_phishing_report,
                                      message: LocalString._reporting_a_message_as_a_phishing_,
                                      preferredStyle: .alert)
        alert.addAction(.init(title: LocalString._general_cancel_button, style: .cancel, handler: { _ in }))
        alert.addAction(.init(title: LocalString._general_confirm_action, style: .default, handler: reportHandler))
        self.present(alert, animated: true, completion: nil)
    }

    private func moreButtonTapped() {
        guard let navigationVC = self.navigationController else { return }
        let actionSheetViewModel = MessageViewActionSheetViewModel(title: viewModel.message.subject,
                                                                   labelID: viewModel.labelId)
        actionSheetPresenter.present(on: navigationVC,
                                     viewModel: actionSheetViewModel) { [weak self] action in
            self?.handleActionSheetAction(action)
        }
    }

    private func changeHeader(oldController: UIViewController, newController: UIViewController) {
        guard isExpandingHeader == false else { return }
        isExpandingHeader = true
        let arrow = viewModel.isExpanded ? Asset.mailUpArrow.image : Asset.mailDownArrow.image
        let showAnimation = { [weak self] in
            UIView.animate(
                withDuration: 0.25,
                animations: {
                    self?.isHeaderContainerHidden(false)
                },
                completion: { _ in
                    self?.isExpandingHeader = false
                }
            )
        }
        UIView.animate(
            withDuration: 0.25,
            animations: { [weak self] in
                self?.isHeaderContainerHidden(true)
            }, completion: { [weak self] _ in
                self?.manageHeaderViewControllers(oldController: oldController, newController: newController)
                self?.customView.messageHeaderContainer.expandArrowImageView.image = arrow
                showAnimation()
            }
        )
    }

    private func isHeaderContainerHidden(_ isHidden: Bool) {
        customView.messageHeaderContainer.contentContainer.isHidden = isHidden
        customView.messageHeaderContainer.contentContainer.alpha = isHidden ? 0 : 1
    }

    private func manageHeaderViewControllers(oldController: UIViewController, newController: UIViewController) {
        unembed(oldController)
        embed(newController, inside: self.customView.messageHeaderContainer.contentContainer)
    }

    @objc
    private func networkStatusUpdated(_ note: Notification) {
        guard let currentReachability = note.object as? Reachability else { return }
        if currentReachability.currentReachabilityStatus() == .NotReachable && viewModel.message.body.isEmpty {
            messageBodyViewController.showReloadError()
        } else if currentReachability.currentReachabilityStatus() != .NotReachable && viewModel.message.body.isEmpty {
            viewModel.downloadDetails()
        }
    }

    required init?(coder: NSCoder) {
        nil
    }

}

private extension SingleMessageViewController {
    func handleActionSheetAction(_ action: MessageViewActionSheetAction) {
        switch action {
        case .reply, .replyAll, .forward:
            handleOpenComposerAction(action)
        case .labelAs:
            showLabelAsActionSheet()
        case .moveTo:
            showMoveToActionSheet()
        case .print:
            self.presentPrintController()
        case .viewHeaders, .viewHTML:
            handleOpenViewAction(action)
        case .dismiss:
            let actionSheet = navigationController?.view.subviews.compactMap { $0 as? PMActionSheet }.first
            actionSheet?.dismiss(animated: true)
        case .delete:
            showDeleteAlert(deleteHandler: { [weak self] _ in
                self?.viewModel.handleActionSheetAction(action, completion: { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                })
            })
        case .reportPhishing:
            showPhishingAlert { [weak self] _ in
                self?.viewModel.handleActionSheetAction(action, completion: { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                })
            }
        default:
            viewModel.handleActionSheetAction(action, completion: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
        }
    }

    private func handleOpenComposerAction(_ action: MessageViewActionSheetAction) {
        switch action {
        case .reply:
            coordinator.navigate(to: .reply)
        case .replyAll:
            coordinator.navigate(to: .replyAll)
        case .forward:
            coordinator.navigate(to: .forward)
        default:
            return
        }
    }

    private func handleOpenViewAction(_ action: MessageViewActionSheetAction) {
        switch action {
        case .viewHeaders:
            if let url = viewModel.getMessageHeaderUrl() {
                coordinator.navigate(to: .viewHeaders(url: url))
            }
        case .viewHTML:
            if let url = viewModel.getMessageBodyUrl() {
                coordinator.navigate(to: .viewHTML(url: url))
            }
        default:
            return
        }
    }
}

extension SingleMessageViewController: LabelAsActionSheetPresentProtocol {
    var labelAsActionHandler: LabelAsActionSheetProtocol {
        return viewModel
    }

    func showLabelAsActionSheet() {
        let labelAsViewModel = LabelAsActionSheetViewModel(menuLabels: labelAsActionHandler.getLabelMenuItems(),
                                                           messages: [viewModel.message])

        labelAsActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     viewModel: labelAsViewModel,
                     addNewLabel: { [weak self] in
                        self?.coordinator.navigate(to: .addNewFoler)
                     },
                     selected: { [weak self] menuLabel, isOn in
                        self?.labelAsActionHandler.updateSelectedLabelAsDestination(menuLabel: menuLabel, isOn: isOn)
                     },
                     cancel: { [weak self] isHavingUnsavedChanges in
                        if isHavingUnsavedChanges {
                            self?.showDiscardAlert(handleDiscard: {
                                self?.labelAsActionHandler.updateSelectedLabelAsDestination(menuLabel: nil, isOn: false)
                                self?.dismissActionSheet()
                            })
                        } else {
                            self?.dismissActionSheet()
                        }
                     },
                     done: { [weak self] isArchive, currentOptionsStatus  in
                        if let message = self?.viewModel.message {
                            self?.labelAsActionHandler
                                .handleLabelAsAction(messages: [message],
                                                     shouldArchive: isArchive,
                                                     currentOptionsStatus: currentOptionsStatus)
                        }
                        self?.dismissActionSheet()
                        self?.navigationController?.popViewController(animated: true)
                     })
    }
}

extension SingleMessageViewController: MoveToActionSheetPresentProtocol {
    var moveToActionHandler: MoveToActionSheetProtocol {
        return viewModel
    }

    func showMoveToActionSheet() {
        let isEnableColor = viewModel.user.isEnableFolderColor
        let isInherit = viewModel.user.isInheritParentFolderColor
        let moveToViewModel =
            MoveToActionSheetViewModel(menuLabels: viewModel.getFolderMenuItems(),
                                       messages: [viewModel.message],
                                       isEnableColor: isEnableColor,
                                       isInherit: isInherit,
                                       labelId: viewModel.labelId)
        moveToActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     viewModel: moveToViewModel,
                     addNewFolder: { [weak self] in
                        self?.coordinator.navigate(to: .addNewFoler)
                     },
                     selected: { [weak self] menuLabel, isOn in
                        self?.moveToActionHandler.updateSelectedMoveToDestination(menuLabel: menuLabel, isOn: isOn)
                     },
                     cancel: { [weak self] isHavingUnsavedChanges in
                        if isHavingUnsavedChanges {
                            self?.showDiscardAlert(handleDiscard: {
                                self?.moveToActionHandler.updateSelectedMoveToDestination(menuLabel: nil, isOn: false)
                                self?.dismissActionSheet()
                            })
                        } else {
                            self?.dismissActionSheet()
                        }
                     },
                     done: { [weak self] isHavingUnsavedChanges in
                        defer {
                            self?.dismissActionSheet()
                            self?.navigationController?.popViewController(animated: true)
                        }
                        guard isHavingUnsavedChanges, let msg = self?.viewModel.message else {
                            return
                        }
                        self?.moveToActionHandler.handleMoveToAction(messages: [msg])
                     })
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
        coordinator.navigate(to: .mailToUrl(url: mailUrl))
    }

    func openUrl(_ url: URL) {
        let browserSpecificUrl = viewModel.linkOpener.deeplink(to: url) ?? url
        switch viewModel.linkOpener {
        case .inAppSafari:
            let supports = ["https", "http"]
            let scheme = browserSpecificUrl.scheme ?? ""
            guard supports.contains(scheme) else {
                self.showUnsupportAlert(url: browserSpecificUrl)
                return
            }
            coordinator.navigate(to: .inAppSafari(url: browserSpecificUrl))
        default:
            coordinator.navigate(to: .url(url: browserSpecificUrl))
        }
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
        coordinator.navigate(to: .attachmentList)
    }
}

extension SingleMessageViewController: BannerViewControllerDelegate {
    func hideBannerController() {
        hideBanner()
    }

    func showBannerController() {
        showBanner()
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
