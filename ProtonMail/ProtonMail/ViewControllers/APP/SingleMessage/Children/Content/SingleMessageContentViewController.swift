import UIKit
import MBProgressHUD
import ProtonCoreUIFoundations

class SingleMessageContentViewController: UIViewController {

    let viewModel: SingleMessageContentViewModel

    private var headerViewController: HeaderViewController? {
        didSet {
            guard
                let newController = headerViewController
            else {
                return
            }
            if let oldController = oldValue, oldController === newController {
                return
            }

            headerAnimationOn ?
                changeHeader(oldController: oldValue, newController: newController) :
                manageHeaderViewControllers(oldController: oldValue, newController: newController)
        }
    }

    private var contentOffsetToPreserve: CGPoint = .zero
    private let parentScrollView: UIScrollView
    private let navigationAction: (SingleMessageNavigationAction) -> Void
    let customView: SingleMessageContentView
    private var isExpandingHeader = false

    private(set) var messageBodyViewController: NewMessageBodyViewController!
    private(set) var bannerViewController: BannerViewController?
    private(set) var editScheduleBannerController: BannerViewController?
    private(set) var attachmentViewController: AttachmentViewController?
    private let applicationStateProvider: ApplicationStateProvider

    private(set) var shouldReloadWhenAppIsActive = false

    init(viewModel: SingleMessageContentViewModel,
         parentScrollView: UIScrollView,
         viewMode: ViewMode,
         navigationAction: @escaping (SingleMessageNavigationAction) -> Void,
         applicationStateProvider: ApplicationStateProvider = UIApplication.shared) {
        self.viewModel = viewModel
        self.parentScrollView = parentScrollView
        self.navigationAction = navigationAction
        let moreThanOneContact = viewModel.message.isHavingMoreThanOneContact
        let replyState = HeaderContainerView.ReplyState.from(moreThanOneContact: moreThanOneContact,
                                                             isScheduled: viewModel.message.contains(location: .scheduled))
        self.customView =  SingleMessageContentView(replyState: replyState)
        self.applicationStateProvider = applicationStateProvider
        super.init(nibName: nil, bundle: nil)

        self.messageBodyViewController =
            NewMessageBodyViewController(viewModel: viewModel.messageBodyViewModel, parentScrollView: self, viewMode: viewMode)
        self.messageBodyViewController.delegate = self

        if viewModel.message.expirationTime != nil {
            showBanner()
        }
        showEditScheduleBanner()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func loadView() {
        view = customView
    }

    private func showErrorOrProtonUnreachableBanner(error: NSError) {
        if error.httpCode == 503 {
            viewModel.isProtonUnreachable { [weak self] isProtonUnreachable in
                guard let self else { return }
                if isProtonUnreachable {
                    PMBanner.showProtonUnreachable(on: self)
                } else {
                    self.showError(error: error)
                }
            }
        } else {
            showError(error: error)
        }
    }

    private func showError(error: NSError) {
        showBanner()
        bannerViewController?.showErrorBanner(error: error)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.set(uiDelegate: self)
        viewModel.updateErrorBanner = { [weak self] error in
            if let error = error {
                self?.showErrorOrProtonUnreachableBanner(error: error)
            } else {
                self?.bannerViewController?.hideBanner(type: .error)
            }
        }
        customView.showHideHistoryButtonContainer.showHideHistoryButton.isHidden = !viewModel.messageInfoProvider.hasStrippedVersion
        customView.showHideHistoryButtonContainer.showHideHistoryButton.addTarget(self, action: #selector(showHide), for: .touchUpInside)
        viewModel.messageHadChanged = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.embedAttachmentViewIfNeeded()
            }
        }

        viewModel.startMonitorConnectionStatus { [weak self] in
            return self?.applicationStateProvider.applicationState == .active
        } reloadWhenAppIsActive: { [weak self] in
            self?.shouldReloadWhenAppIsActive = true
        }

        viewModel.showProgressHub = { [weak self] in
            guard let self = self else { return }
            MBProgressHUD.showAdded(to: self.view, animated: true)
        }

        viewModel.hideProgressHub = { [weak self] in
            guard let self = self else { return }
            MBProgressHUD.hide(for: self.view, animated: true)
        }

        addObservations()
        setUpHeaderActions()
        embedChildren()
        setUpFooterButtons()

        viewModel.viewDidLoad()
        updateAttachmentBannerIfNeeded()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            let isDarkModeStyle = traitCollection.userInterfaceStyle == .dark
            viewModel.sendMetricAPIIfNeeded(isDarkModeStyle: isDarkModeStyle)
        super.traitCollectionDidChange(previousTraitCollection)
    }

    @objc private func showHide(_ sender: UIButton) {
        sender.isHidden = true
        viewModel.messageInfoProvider.displayMode.toggle()
        delay(0.5) {
            sender.isHidden = false
        }
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func setUpFooterButtons() {
        if viewModel.message.contains(location: .scheduled) {
            customView.footerButtons.removeFromSuperview()
        } else if !viewModel.message.isHavingMoreThanOneContact {
            customView.footerButtons.stackView.distribution = .fillEqually
            customView.footerButtons.replyAllButton.removeFromSuperview()
        } else {
            customView.footerButtons.replyAllButton.tap = { [weak self] in
                self?.replyAllButtonTapped()
            }
        }

        customView.footerButtons.replyButton.tap = { [weak self] in
            self?.replyButtonTapped()
        }
        customView.footerButtons.forwardButton.tap = { [weak self] in
            self?.forwardButtonTapped()
        }
    }

    private func replyButtonTapped() {
        guard !self.viewModel.user.isStorageExceeded else {
            LocalString._storage_exceeded.alertToastBottom()
            return
        }
        let messageId = viewModel.message.messageID
        let action: SingleMessageNavigationAction = .reply(
            messageId: messageId,
            remoteContentPolicy: viewModel.messageInfoProvider.remoteContentPolicy,
            embeddedContentPolicy: viewModel.messageInfoProvider.embeddedContentPolicy
        )
        navigationAction(action)
    }

    private func replyAllButtonTapped() {
        guard !self.viewModel.user.isStorageExceeded else {
            LocalString._storage_exceeded.alertToastBottom()
            return
        }
        let messageId = viewModel.message.messageID
        let action = SingleMessageNavigationAction.replyAll(
            messageId: messageId,
            remoteContentPolicy: viewModel.messageInfoProvider.remoteContentPolicy,
            embeddedContentPolicy: viewModel.messageInfoProvider.embeddedContentPolicy
        )
        navigationAction(action)
    }

    private func forwardButtonTapped() {
        guard !self.viewModel.user.isStorageExceeded else {
            LocalString._storage_exceeded.alertToastBottom()
            return
        }
        let messageId = viewModel.message.messageID
        let action = SingleMessageNavigationAction.forward(
            messageId: messageId,
            remoteContentPolicy: viewModel.messageInfoProvider.remoteContentPolicy,
            embeddedContentPolicy: viewModel.messageInfoProvider.embeddedContentPolicy
        )
        navigationAction(action)
    }

    @objc
    private func moreButtonTapped() {
        navigationAction(.more(messageId: viewModel.message.messageID))
    }

    @objc
    private func replyActionButtonTapped() {
        switch customView.replyState {
        case .reply:
            replyButtonTapped()
        case .replyAll:
            replyAllButtonTapped()
        case .none:
            return
        }
    }

    private func showEditScheduleBanner() {
        guard self.editScheduleBannerController == nil && viewModel.message.isScheduledSend else {
            return
        }
        let controller = BannerViewController(viewModel: viewModel.bannerViewModel, isScheduleBannerOnly: true)
        self.editScheduleBannerController = controller
        embed(controller, inside: customView.editScheduleSendBannerContainer)
    }

    private func showBanner() {
        guard self.bannerViewController == nil else {
            return
        }
        let controller = BannerViewController(viewModel: viewModel.bannerViewModel)
        controller.delegate = self
        self.bannerViewController = controller
        embed(controller, inside: customView.bannerContainer)
    }

    private func hideBanner() {
        guard let controler = self.bannerViewController else {
            return
        }
        unembed(controler)
        self.bannerViewController = nil
    }

    private func manageHeaderViewControllers(oldController: UIViewController?, newController: UIViewController) {
        if let oldController = oldController {
            unembed(oldController)
        }

        embed(newController, inside: self.customView.messageHeaderContainer.contentContainer)
    }

    private func changeHeader(oldController: UIViewController?, newController: UIViewController) {
        oldController?.willMove(toParent: nil)
        newController.view.translatesAutoresizingMaskIntoConstraints = false

        self.addChild(newController)
        self.customView.messageHeaderContainer.contentContainer.addSubview(newController.view)

        let oldBottomConstraint = customView.messageHeaderContainer.contentContainer
            .constraints.first(where: { $0.firstAttribute == .bottom })

        newController.view.alpha = 0

        [
            newController.view.topAnchor.constraint(equalTo: customView.messageHeaderContainer.contentContainer.topAnchor),
            newController.view.leadingAnchor.constraint(equalTo: customView.messageHeaderContainer.contentContainer.leadingAnchor),
            newController.view.trailingAnchor.constraint(equalTo: customView.messageHeaderContainer.contentContainer.trailingAnchor)
        ].activate()
        
        let bottomConstraint = newController.view.bottomAnchor
            .constraint(equalTo: customView.messageHeaderContainer.contentContainer.bottomAnchor)
        
        UIView.setAnimationsEnabled(true)
        
        oldBottomConstraint?.isActive = false
        bottomConstraint.isActive = true
        viewModel.recalculateCellHeight?(false)

        UIView.animate(withDuration: 0.25) {
            newController.view.alpha = 1
            oldController?.view.alpha = 0
        } completion: { [weak self] _ in
            newController.view.layoutIfNeeded()
            oldController?.view.removeFromSuperview()
            oldController?.removeFromParent()
            newController.didMove(toParent: self)
            self?.viewModel.recalculateCellHeight?(false)
        }
    }

    private func addObservations() {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(restoreOffset),
                                                   name: UIWindowScene.willEnterForegroundNotification,
                                                   object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(saveOffset),
                                                   name: UIWindowScene.didEnterBackgroundNotification,
                                                   object: nil)
            NotificationCenter.default
                .addObserver(self,
                             selector: #selector(willBecomeActive),
                             name: UIScene.willEnterForegroundNotification,
                             object: nil)
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(preferredContentSizeChanged),
                         name: UIContentSizeCategory.didChangeNotification,
                         object: nil)
    }

    @objc
    private func expandButton() {
        guard isExpandingHeader == false else { return }
        viewModel.isExpanded.toggle()
    }

    private func setUpHeaderActions() {
        // Action
        customView.messageHeaderContainer.moreControl.addTarget(self, action: #selector(self.moreButtonTapped), for: .touchUpInside)
        customView.messageHeaderContainer.replyControl.addTarget(self, action: #selector(self.replyActionButtonTapped), for: .touchUpInside)

    }

    private func embedChildren() {
        precondition(messageBodyViewController != nil)
        embed(messageBodyViewController, inside: customView.messageBodyContainer)
        if let headerViewController = headerViewController {
            embed(headerViewController, inside: customView.messageHeaderContainer.contentContainer)
        }
        embedAttachmentViewIfNeeded()
        embedHeaderController()
        showBanner()
    }

    private func embedAttachmentViewIfNeeded() {
        guard self.attachmentViewController == nil else { return }
        if viewModel.attachmentViewModel.viewShouldBeShown {
            let attachmentVC = AttachmentViewController(viewModel: viewModel.attachmentViewModel)
            attachmentVC.delegate = self
            embed(attachmentVC, inside: customView.attachmentContainer)
            attachmentViewController = attachmentVC
        }
    }

    private var headerAnimationOn = true

    private func embedHeaderController() {
        viewModel.embedExpandedHeader = { [weak self] viewModel in
            let viewController = ExpandedHeaderViewController(viewModel: viewModel)
            viewController.contactTapped = {
                self?.presentActionSheet(context: $0)
            }
            viewController.observeHideDetails {
                self?.expandButton()
            }
            self?.headerViewController = viewController
        }

        viewModel.embedNonExpandedHeader = { [weak self] viewModel in
            let header = NonExpandedHeaderViewController(viewModel: viewModel)
            header.contactTapped = {
                self?.presentActionSheet(context: $0)
            }
            header.observeShowDetails {
                self?.expandButton()
            }
            self?.headerViewController = header
        }

        headerAnimationOn.toggle()
        viewModel.isExpanded = viewModel.isExpanded
        headerAnimationOn.toggle()
    }

    private func presentActionSheet(context: MessageHeaderContactContext) {
        let title: String
        let showOfficialBadge: Bool
        let senderBlockStatus: PMActionSheet.SenderBlockStatus

        switch context {
        case .eventParticipant(let emailAddress):
            title = emailAddress
            showOfficialBadge = false
            senderBlockStatus = .notApplicable
        case .recipient(let contactVO):
            title = contactVO.title
            showOfficialBadge = false
            senderBlockStatus = .notApplicable
        case .sender(let sender):
            title = viewModel.messageInfoProvider.senderName.string
            showOfficialBadge = sender.isFromProton
            senderBlockStatus = viewModel.isSenderCurrentlyBlocked ? .blocked : .notBlocked
        }

        let actionSheet = PMActionSheet.messageDetailsContact(
            title: title,
            subtitle: context.contact.subtitle,
            showOfficialBadge: showOfficialBadge,
            senderBlockStatus: senderBlockStatus
        ) { [weak self] action in
            self?.dismissActionSheet()
            self?.handleAction(context: context, action: action)
        }

        actionSheet.presentAt(navigationController ?? self, hasTopConstant: false, animated: true)
    }

    private func handleAction(context: MessageHeaderContactContext, action: MessageDetailsContactActionSheetAction) {
        switch action {
        case .addToContacts:
            navigationAction(.contacts(contact: context.contact))
        case .blockSender:
            blockSenderTapped()
        case .composeTo:
            guard !self.viewModel.user.isStorageExceeded else {
                LocalString._storage_exceeded.alertToastBottom(view: self.view)
                return
            }
            navigationAction(.compose(contact: context.contact))
        case .copyAddress:
            UIPasteboard.general.string = context.contact.email
        case .copyName:
            UIPasteboard.general.string = context.contact.name
        case .close:
            break
        case .unblockSender:
            unblockSender()
        }
    }

    private func blockSenderTapped() {
        let senderEmail = viewModel.messageInfoProvider.senderEmail.string

        let alert = UIAlertController(
            title: L10n.BlockSender.blockActionTitleLong,
            message: String(format: L10n.BlockSender.explanation, senderEmail),
            preferredStyle: .alert
        )

        alert.addCancelAction()

        let confirmAction = UIAlertAction(
            title: L10n.BlockSender.blockActionTitleShort,
            style: .destructive
        ) { [weak self] _ in
            guard let self = self else { return }

            if self.viewModel.updateSenderBlockedStatus(blocked: true) {
                self.showBottomToast(message: String(format: L10n.BlockSender.successfulBlockConfirmation, senderEmail))
            }
        }
        alert.addAction(confirmAction)

        present(alert, animated: true)
    }

    private func showBottomToast(message: String) {
        let banner = PMBanner(message: message, style: PMBannerNewStyle.info, bannerHandler: PMBanner.dismiss)

        let toastPresenter: UIViewController

        if let singleMessageViewController = parent as? SingleMessageViewController {
            toastPresenter = singleMessageViewController
        } else if let conversationViewController = parent?.parent as? ConversationViewController {
            toastPresenter = conversationViewController
        } else {
            PMAssertionFailure("Cannot find a suitable parent")
            toastPresenter = parent ?? self
        }

        banner.show(at: PMBanner.onTopOfTheBottomToolBar, on: toastPresenter)
    }

    @objc
    private func willBecomeActive() {
        if shouldReloadWhenAppIsActive {
            viewModel.downloadDetails()
            shouldReloadWhenAppIsActive = false
        }
    }

    @objc
    private func preferredContentSizeChanged(_ notification: Notification) {
        SystemLogger.log(
            message: "\(notification.name.rawValue) \(notification.userInfo?[UIContentSizeCategory.newValueUserInfoKey] ?? "")",
            category: .dynamicFontSize
        )
        customView.preferredContentSizeChanged()
        if let expandedVC = headerViewController as? ExpandedHeaderViewController {
            expandedVC.preferredContentSizeChanged()
        } else if let nonExpandedVC = headerViewController as? NonExpandedHeaderViewController {
            nonExpandedVC.preferredContentSizeChanged()
        }
        messageBodyViewController.preferredContentSizeChanged()
    }
}

extension SingleMessageContentViewController: NewMessageBodyViewControllerDelegate {
    func openMailUrl(_ mailUrl: URL) {
        navigationAction(.mailToUrl(url: mailUrl))
    }

    func openUrl(_ url: URL) {
        let browserSpecificUrl = viewModel.linkOpener.deeplink(to: url)
        switch viewModel.linkOpener {
        case .inAppSafari:
            let supports = ["https", "http"]
            let scheme = browserSpecificUrl.scheme ?? ""
            guard supports.contains(scheme) else {
                self.showUnsupportAlert(url: browserSpecificUrl)
                return
            }
            navigationAction(.inAppSafari(url: browserSpecificUrl))
        default:
            navigationAction(.url(url: browserSpecificUrl))
        }
    }

    func openFullCryptoPage() {
        guard let url = self.viewModel.getCypherURL() else { return }
        navigationAction(.viewCypher(url: url))
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

    @objc
    private func tryDecryptionAgain() {
        if let vi = self.navigationController?.view {
            MBProgressHUD.showAdded(to: vi, animated: true)
        }
        viewModel.messageInfoProvider.tryDecryptionAgain { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let vi = self.navigationController?.view {
                    MBProgressHUD.hide(for: vi, animated: true)
                }
            }
        }
    }
}

extension SingleMessageContentViewController: AttachmentViewControllerDelegate {
    func openAttachmentList(with attachments: [AttachmentInfo]) {
        let messageID = viewModel.message.messageID
        // Attachment list needs to check if the body contains content IDs
        // So needs to use full message body or it could miss inline image in the quote
        let body = viewModel.messageInfoProvider.bodyParts?.originalBody
        navigationAction(.attachmentList(messageId: messageID, decryptedBody: body, attachments: attachments))
    }

    func invitationViewWasChanged() {
        viewModel.recalculateCellHeight?(false)
    }

    func participantTapped(emailAddress: String) {
        presentActionSheet(context: .eventParticipant(emailAddress: emailAddress))
    }

    func showError(error: Error) {
        let banner = PMBanner(
            message: error.localizedDescription,
            style: PMBannerNewStyle.error,
            dismissDuration: 5.0,
            bannerHandler: PMBanner.dismiss
        )
        banner.show(at: .top, on: self)
    }
}

extension SingleMessageContentViewController: BannerViewControllerDelegate {
    func hideBannerController() {
        hideBanner()
    }

    func showBannerController() {
        showBanner()
    }

    func loadEmbeddedImage() {
        viewModel.messageInfoProvider.embeddedContentPolicy = .allowed
    }

    func handleMessageExpired() {
        self.viewModel.deleteExpiredMessages()
        self.navigationController?.popViewController(animated: true)
    }

    func loadRemoteContent() {
        viewModel.messageInfoProvider.set(policy: .allowedThroughProxy)
    }

    func reloadImagesWithoutProtection() {
        viewModel.messageInfoProvider.reloadImagesWithoutProtection()
    }

    func unblockSender() {
        guard viewModel.updateSenderBlockedStatus(blocked: false) else {
            return
        }

        showBottomToast(
            message: String(
                format: L10n.BlockSender.successfulUnblockConfirmation,
                viewModel.messageInfoProvider.senderEmail.string
            )
        )
    }
}

extension SingleMessageContentViewController: ScrollableContainer {
    var scroller: UIScrollView {
        return parentScrollView
    }

    func propagate(scrolling delta: CGPoint, boundsTouchedHandler: () -> Void) {
        let scrollView = parentScrollView
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
        self.contentOffsetToPreserve = scroller.contentOffset
    }

    @objc
    func restoreOffset() {
        scroller.setContentOffset(self.contentOffsetToPreserve, animated: false)
    }
}

extension SingleMessageContentViewController: SingleMessageContentUIProtocol {
    func updateContentBanner(
        shouldShowRemoteContentBanner: Bool,
        shouldShowEmbeddedContentBanner: Bool,
        shouldShowImageProxyFailedBanner: Bool,
        shouldShowSenderIsBlockedBanner: Bool
    ) {
        let shouldShowRemoteContentBanner =
            shouldShowRemoteContentBanner && !viewModel.bannerViewModel.shouldAutoLoadRemoteContent
        let shouldShowEmbeddedImageBanner =
            shouldShowEmbeddedContentBanner && !viewModel.bannerViewModel.shouldAutoLoadEmbeddedImage

        showBanner()
        bannerViewController?.showContentBanner(
            remoteContent: shouldShowRemoteContentBanner,
            embeddedImage: shouldShowEmbeddedImageBanner,
            imageProxyFailure: shouldShowImageProxyFailedBanner,
            senderIsBlocked: shouldShowSenderIsBlockedBanner
        )
    }

    func setDecryptionErrorBanner(shouldShow: Bool) {
        if shouldShow {
            showBanner()
            bannerViewController?.showDecryptionBanner { [weak self] in
                self?.tryDecryptionAgain()
            }
        } else {
            bannerViewController?.hideDecryptionBanner()
        }
    }

    func update(hasStrippedVersion: Bool) {
        customView.showHideHistoryButtonContainer.showHideHistoryButton.isHidden = !hasStrippedVersion
    }

    func updateAttachmentBannerIfNeeded() {
        embedAttachmentViewIfNeeded()
	}

    func trackerProtectionSummaryChanged() {
        headerViewController?.trackerProtectionSummaryChanged()
    }

    func didUnSnooze() {
        navigationController?.popViewController(animated: true)
        guard let mailboxVC = navigationController?.viewControllers.first else { return }
        let banner = PMBanner(
            message: L10n.Snooze.unsnoozeSuccessBannerTitle,
            style: PMBannerNewStyle.info,
            bannerHandler: PMBanner.dismiss
        )
        banner.show(at: .bottom, on: mailboxVC)
    }
}
