import UIKit
import ProtonCore_UIFoundations

class SingleMessageContentViewController: UIViewController {

    let viewModel: SingleMessageContentViewModel

    var headerViewController: UIViewController = .init() {
        didSet {
            headerAnimationOn ?
                changeHeader(oldController: oldValue, newController: headerViewController) :
                manageHeaderViewControllers(oldController: oldValue, newController: headerViewController)
        }
    }

    private var contentOffsetToPreserve: CGPoint = .zero
    private let parentScrollView: UIScrollView
    private let navigationAction: (SingleMessageNavigationAction) -> Void
    private lazy var customView = SingleMessageContentView()
    private var isExpandingHeader = false

    private(set) var messageBodyViewController: NewMessageBodyViewController!
    private(set) var bannerViewController: BannerViewController?
    private(set) var attachmentViewController: AttachmentViewController?

    init(viewModel: SingleMessageContentViewModel,
         parentScrollView: UIScrollView,
         navigationAction: @escaping (SingleMessageNavigationAction) -> Void) {
        self.viewModel = viewModel
        self.parentScrollView = parentScrollView
        self.navigationAction = navigationAction

        if viewModel.message.numAttachments != 0 {
            attachmentViewController = AttachmentViewController(viewModel: viewModel.attachmentViewModel)
        }
        super.init(nibName: nil, bundle: nil)

        self.messageBodyViewController =
            NewMessageBodyViewController(viewModel: viewModel.messageBodyViewModel, parentScrollView: self)
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
        viewModel.updateErrorBanner = { [weak self] error in
            if let error = error {
                self?.showBanner()
                self?.bannerViewController?.showErrorBanner(error: error)
            } else {
                self?.bannerViewController?.hideBanner(type: .error)
            }
        }

        addObservations()
        embedChildren()
        setUpExpandAction()
        setUpFooterButtons()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func setUpFooterButtons() {
        customView.footerButtons.isHidden = viewModel.context.viewMode != .conversation
        let image = viewModel.message.isHavingMoreThanOneContact ?
            Asset.replyAllButtonIcon.image : Asset.replyButtonIcon.image
        customView.footerButtons.replyButton.setImage(image, for: .normal)

        if viewModel.context.viewMode == .conversation {
            customView.footerButtons.replyButton
                .addTarget(self, action: #selector(replyButtonTapped), for: .touchUpInside)
            customView.footerButtons.moreButton
                .addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)
        }
    }

    @objc private func replyButtonTapped() {
        let messageId = viewModel.message.messageID
        let action: SingleMessageNavigationAction = viewModel.message.isHavingMoreThanOneContact ?
            .replyAll(messageId: messageId) : .reply(messageId: messageId)
        navigationAction(action)
    }

    @objc private func moreButtonTapped() {
        navigationAction(.more(messageId: viewModel.message.messageID))
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

    private func manageHeaderViewControllers(oldController: UIViewController, newController: UIViewController) {
        unembed(oldController)
        embed(newController, inside: self.customView.messageHeaderContainer.contentContainer)
    }

    private func changeHeader(oldController: UIViewController, newController: UIViewController) {
        oldController.willMove(toParent: nil)
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

        customView.messageHeaderContainer.expandArrowImageView.image = newController is ExpandedHeaderViewController ?
            Asset.arrowUp.image : Asset.arrowDown.image

        let bottomConstraint = newController.view.bottomAnchor
            .constraint(equalTo: customView.messageHeaderContainer.contentContainer.bottomAnchor)

        oldBottomConstraint?.isActive = !(newController is ExpandedHeaderViewController)
        bottomConstraint.isActive = newController is ExpandedHeaderViewController

        viewModel.recalcualteCellHeight?()

        UIView.animate(withDuration: 0.25) {
            newController.view.alpha = 1
            oldController.view.alpha = 0
        } completion: { [weak self] _ in
            oldController.view.removeFromSuperview()
            oldController.removeFromParent()
            newController.didMove(toParent: self)
            bottomConstraint.isActive = true
            self?.viewModel.recalcualteCellHeight?()
        }
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


    @objc
    private func expandButton() {
        guard isExpandingHeader == false else { return }
        viewModel.isExpanded.toggle()
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

        if let attachmentViewController = self.attachmentViewController {
            embed(attachmentViewController, inside: customView.attachmentContainer)
        }

        embedHeaderController()
    }

    private var headerAnimationOn = true

    private func embedHeaderController() {
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

        headerAnimationOn.toggle()
        viewModel.isExpanded = viewModel.isExpanded
        headerAnimationOn.toggle()
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
            navigationAction(.contacts(contact: context.contact))
        case .composeTo:
            navigationAction(.compose(contact: context.contact))
        case .copyAddress:
            UIPasteboard.general.string = context.contact.email
        case .copyName:
            UIPasteboard.general.string = context.contact.name
        case .close:
            break
        }
    }

}

extension SingleMessageContentViewController: NewMessageBodyViewControllerDelegate {
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
        navigationAction(.mailToUrl(url: mailUrl))
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
            navigationAction(.inAppSafari(url: browserSpecificUrl))
        default:
            navigationAction(.url(url: browserSpecificUrl))
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

    @objc
    private func networkStatusUpdated(_ note: Notification) {
        guard let currentReachability = note.object as? Reachability else { return }
        if currentReachability.currentReachabilityStatus() == .NotReachable && viewModel.message.body.isEmpty {
            messageBodyViewController.showReloadError()
        } else if currentReachability.currentReachabilityStatus() != .NotReachable && viewModel.message.body.isEmpty {
            viewModel.downloadDetails()
        }
    }
}

extension SingleMessageContentViewController: AttachmentViewControllerDelegate {
    func openAttachmentList() {
        let messageID = viewModel.message.messageID
        let body = viewModel.messageBodyViewModel.body
        navigationAction(.attachmentList(messageId: messageID, decryptedBody: body))
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
        viewModel.messageBodyViewModel.embeddedContentPolicy = .allowed
    }

    func handleMessageExpired() {
        self.navigationController?.popViewController(animated: true)
    }

    func loadRemoteContent() {
        viewModel.messageBodyViewModel.remoteContentPolicy = WebContents.RemoteContentPolicy.allowed.rawValue
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
