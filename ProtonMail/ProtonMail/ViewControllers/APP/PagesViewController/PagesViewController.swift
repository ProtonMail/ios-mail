// Copyright (c) 2022 Proton Technologies AG
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

import protocol CoreData.NSFetchRequestResult
import class CoreData.NSManagedObjectID
import LifetimeTracker
import ProtonCore_UIFoundations
import UIKit

final class PagesViewController<
    IDType,
    EntityType,
    FetchResultType: NSFetchRequestResult
>: UIPageViewController,
   UIPageViewControllerDelegate,
   UIPageViewControllerDataSource,
   LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }

    private let viewModel: PagesViewModel<IDType, EntityType, FetchResultType>
    private var services: ServiceFactory
    private var titleViewObserver: NSKeyValueObservation?
    private var spotlight: PagesSpotlightView?
    // Message objectID or ContextLabel objectID
    private var currentObjectID: ObjectID?

    typealias PageCacheType = (refIndex: Int, controller: UIViewController)
    /// Strong reference to VCs to prevent UIPagesViewController release sibling page too early
    /// When VC is released from pageCache, UIPagesViewController will keep holding it if needed.
    /// Shouldn't cause any display issue
    private var pageCache: [String: PageCacheType] = [:]

    init(viewModel: PagesViewModel<IDType, EntityType, FetchResultType>, services: ServiceFactory) {
        self.viewModel = viewModel
        self.services = services
        super.init(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: [:]
        )
        self.delegate = self
        self.dataSource = self

        trackLifetime()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.uiDelegate = self
        switch viewModel.viewMode {
        case .singleMessage:
            initializeForSingleMessage()
        case .conversation:
            initializeForConversation()
        }

        view.backgroundColor = ColorProvider.BackgroundSecondary

        setUpTitleView()
        updateCurrentID()
        emptyBackButtonTitleForNextView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showSpotlightIfNeeded { [weak self] in
            delay(0.5) {
                self?.showToolbarCustomizationSpotlightIfNeeded()
            }
        }
    }

    private func getNextViewController() -> UIViewController? {
        guard let current = viewControllers?.first else { return nil }
        switch viewModel.viewMode {
        case .singleMessage:
            return singleMessageVC(baseOn: current, offset: 1).0
        case .conversation:
            return conversationVC(baseOn: current, offset: 1).0
        }
    }

    // MARK: UIPageViewControllerDelegate
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        setUpTitleView()
        updateCurrentID()
    }

    // MARK: UIPageViewControllerDataSource
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        spotlight?.removeFromSuperview()
        switch viewModel.viewMode {
        case .singleMessage:
            let data = singleMessageVC(baseOn: viewController, offset: -1)
            removeCachedPages(from: data.1)
            return data.0
        case .conversation:
            let data = conversationVC(baseOn: viewController, offset: -1)
            removeCachedPages(from: data.1)
            return data.0
        }
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        spotlight?.removeFromSuperview()
        switch viewModel.viewMode {
        case .singleMessage:
            let data = singleMessageVC(baseOn: viewController, offset: 1)
            removeCachedPages(from: data.1)
            return data.0
        case .conversation:
            let data = conversationVC(baseOn: viewController, offset: 1)
            removeCachedPages(from: data.1)
            return data.0
        }
    }
}

// MARK: SingleMessage
extension PagesViewController {
    private func initializeForSingleMessage() {
        guard let (message, refIndex) = viewModel.item(for: viewModel.initialID, offset: 0) as? (MessageEntity, Int),
              let singleMessageVC = singleMessageVC(for: message, refIndex: refIndex) else {
            assertionFailure("Shouldn't fail")
            dismiss()
            return
        }
        setViewControllers([singleMessageVC], direction: .forward, animated: false)
    }

    private func singleMessageVC(for message: MessageEntity, refIndex: Int) -> SingleMessageViewController? {
        let messageID = message.messageID.rawValue
        if let cache = pageCache[messageID]?.controller as? SingleMessageViewController {
            return cache
        }
        guard let navigationController = self.navigationController else { return nil }
        let coordinator = SingleMessageCoordinator(
            navigationController: navigationController,
            labelId: viewModel.labelID,
            message: message,
            user: viewModel.user,
            infoBubbleViewStatusProvider: viewModel.infoBubbleViewStatusProvider
        )
        coordinator.goToDraft = viewModel.goToDraft
        let controller = coordinator.makeSingleMessageVC()
        pageCache[messageID] = (refIndex, controller)
        return controller
    }

    private func singleMessageVC(
        baseOn current: UIViewController,
        offset: Int
    ) -> (SingleMessageViewController?, Int?) {
        guard let current = current as? SingleMessageViewController,
              let messageID = current.viewModel.message.messageID as? IDType,
              let (message, refIndex) = viewModel.item(for: messageID, offset: offset) as? (MessageEntity, Int) else {
            return (nil, nil)
        }
        return (singleMessageVC(for: message, refIndex: refIndex), refIndex)
    }
}

// MARK: Conversation
extension PagesViewController {
    private func initializeForConversation() {
        let targetID = viewModel.getTargetMessageID()
        guard
            let (conversation, refIndex) = viewModel
                .item(for: viewModel.initialID, offset: 0) as? (ConversationEntity, Int),
            let conversationVC = conversationVC(for: conversation, refIndex: refIndex, targetMessageID: targetID)
        else {
            assertionFailure("Shouldn't fail")
            dismiss()
            return
        }
        setViewControllers([conversationVC], direction: .forward, animated: false)
    }

    private func conversationVC(
        for conversation: ConversationEntity,
        refIndex: Int,
        targetMessageID: MessageID?
    ) -> ConversationViewController? {
        let conversationID = conversation.conversationID.rawValue
        if let cache = pageCache[conversationID]?.controller as? ConversationViewController {
            return cache
        }
        guard let navigationController = self.navigationController else { return nil }
        let coordinator = ConversationCoordinator(
            labelId: viewModel.labelID,
            navigationController: navigationController,
            conversation: conversation,
            user: viewModel.user,
            internetStatusProvider: services.get(by: InternetConnectionStatusProvider.self),
            infoBubbleViewStatusProvider: viewModel.infoBubbleViewStatusProvider,
            contextProvider: services.get(by: CoreDataService.self),
            targetID: targetMessageID
        )
        coordinator.goToDraft = viewModel.goToDraft
        let controller = coordinator.makeConversationVC()
        pageCache[conversationID] = (refIndex, controller)
        return controller
    }

    private func conversationVC(baseOn current: UIViewController, offset: Int) -> (ConversationViewController?, Int?) {
        guard let current = current as? ConversationViewController,
              let conversationID = current.viewModel.conversation.conversationID as? IDType,
              let (conversation, refIndex) = viewModel
            .item(for: conversationID, offset: offset) as? (ConversationEntity, Int) else { return (nil, nil) }
        return (conversationVC(for: conversation, refIndex: refIndex, targetMessageID: nil), refIndex)
    }
}

extension PagesViewController: PagesViewUIProtocol {
    func dismiss() {
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }

    func getCurrentObjectID() -> ObjectID? {
        currentObjectID
    }

    func handlePageViewNavigationDirection(
        action: PagesSwipeAction,
        shouldReload: Bool = false
    ) {
        guard let current = self.viewControllers?.first else { return }
        let direction: UIPageViewController.NavigationDirection = action == .forward ? .forward : .reverse
        switch viewModel.viewMode {
        case .singleMessage:
            if let nextVC = self.singleMessageVC(baseOn: current, offset: action.rawValue).0 {
                setViewControllers([nextVC], direction: direction, animated: true) { _ in
                    self.setUpTitleView()
                    self.updateCurrentID()
                    if shouldReload {
                        self.viewModel.refetchData()
                    }
                }
            } else {
                navigationController?.popViewController(animated: true)
            }
        case .conversation:
            if let nextVC = conversationVC(baseOn: current, offset: action.rawValue).0 {
                setViewControllers([nextVC], direction: direction, animated: true) { _ in
                    self.setUpTitleView()
                    self.updateCurrentID()
                    if shouldReload {
                        self.viewModel.refetchData()
                    }
                }
            } else {
                navigationController?.popViewController(animated: true)
            }
        }
    }
}

extension PagesViewController {
    private func setUpTitleView() {
        guard let currentVC = self.viewControllers?.first else {
            navigationItem.titleView = nil
            navigationItem.rightBarButtonItem = nil
            return
        }
        navigationItem.rightBarButtonItem = currentVC.navigationItem.rightBarButtonItem
        navigationItem.titleView = currentVC.navigationItem.titleView
        // SingleMessage mode use the same titleView
        // Conversation mode use different titleView, observe it
        guard viewModel.viewMode == .conversation else { return }
        titleViewObserver = currentVC.observe(\.navigationItem.titleView, options: [.new]) { [weak self] currentVC, _ in
            self?.navigationItem.titleView = currentVC.navigationItem.titleView
        }
    }

    private func updateCurrentID() {
        guard let currentVC = self.viewControllers?.first else { return }
        if let singleMessageVC = currentVC as? SingleMessageViewController {
            currentObjectID = singleMessageVC.viewModel.message.objectID
        } else if let conversationVC = currentVC as? ConversationViewController,
                  let contextLabel = conversationVC.viewModel
                      .conversation
                      .contextLabelRelations
                      .first(where: { $0.labelID == viewModel.labelID }) {
            currentObjectID = contextLabel.objectID
        }
    }

    private func removeCachedPages(from index: Int?) {
        guard let index = index else { return }
        // When swipe action is detected but not success
        // The current pages are [previous, current, next]
        // Since this function is called when initialize next or previous
        // Buffer = 2 can cover possible pages, e.g. starts from next, buffer -2 can cover previous
        let upperBuffer = 2
        let lowerBuffer = -2
        let upperBound = index + upperBuffer
        let lowerBound = index + lowerBuffer
        for data in pageCache where data.value.refIndex > upperBound || data.value.refIndex < lowerBound {
            pageCache.removeValue(forKey: data.key)
        }
    }
}

// MARK: - Spotlight
extension PagesViewController {
    private func showSpotlightIfNeeded(animationCompletion: @escaping () -> Void) {
        if viewModel.hasUserSeenSpotlight() {
            animationCompletion()
            return
        }

        guard
            let position = viewModel.spotlightPosition(),
            let scrollView = view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView,
            let spotlight = setUpSpotlight(in: scrollView, position: position)
        else {
            animationCompletion()
            return
        }
        self.spotlight = spotlight
        updateSpotlightTitleHeight(spotlight: spotlight)
        viewModel.userHasSeenSpotlight()
        setUpSpotlightAnimation(in: scrollView, position: position, completion: animationCompletion)
    }

    private func showToolbarCustomizationSpotlightIfNeeded() {
        let currentViewController = viewControllers?.first
        if let conversationViewController = currentViewController as? ConversationViewController {
            conversationViewController.showToolbarCustomizeSpotlightIfNeeded()
        } else if let messageViewController = currentViewController as? SingleMessageViewController {
            messageViewController.showToolbarCustomizeSpotlightIfNeeded()
        }
    }

    private func setUpSpotlight(
        in scrollView: UIScrollView,
        position: PagesViewModel<IDType, EntityType, FetchResultType>.SpotlightPosition
    ) -> PagesSpotlightView? {
        let spotlight: PagesSpotlightView
        switch position {
        case .left:
            guard let target = scrollView.subviews[safe: 0] else { return nil }
            spotlight = PagesSpotlightView(flipIcon: true)
            target.addSubview(spotlight)
            [
                spotlight.topAnchor.constraint(equalTo: target.topAnchor),
                spotlight.trailingAnchor.constraint(equalTo: target.trailingAnchor),
                spotlight.bottomAnchor.constraint(equalTo: target.bottomAnchor),
                spotlight.widthAnchor.constraint(equalToConstant: 64)
            ].activate()
        case .right:
            guard let target = scrollView.subviews[safe: 2] else { return nil }
            spotlight = PagesSpotlightView(flipIcon: false)
            target.addSubview(spotlight)
            [
                spotlight.topAnchor.constraint(equalTo: target.topAnchor),
                spotlight.leadingAnchor.constraint(equalTo: target.leadingAnchor),
                spotlight.bottomAnchor.constraint(equalTo: target.bottomAnchor),
                spotlight.widthAnchor.constraint(equalToConstant: 64)
            ].activate()
        }
        return spotlight
    }

    private func updateSpotlightTitleHeight(spotlight: PagesSpotlightView) {
        guard let currentVC = self.viewControllers?.first else { return }
        if let conversationView = currentVC as? ConversationViewController {
            let tableView = conversationView.customView.tableView
            let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0))
            let cellHeight = cell?.frame.height ?? 0
            spotlight.mockTitleViewHeight?.constant = cellHeight - 2
        } else if let singleMessageView = currentVC as? SingleMessageViewController {
            let height = singleMessageView.customView.stackView.arrangedSubviews.first?.frame.height ?? 0
            spotlight.mockTitleViewHeight?.constant = height + 1
        }
    }

    private func setUpSpotlightAnimation(
        in scrollView: UIScrollView,
        position: PagesViewModel<IDType, EntityType, FetchResultType>.SpotlightPosition,
        completion: (() -> Void)?
    ) {
        let originalOffset = scrollView.contentOffset
        var offset = scrollView.contentOffset
        switch position {
        case .left:
            offset.x -= 64
        case .right:
            offset.x += 64
        }

        let delayBeforeAnimationIn = 0.1
        let animationDurationIn = 0.5
        let delayBeforeAnimationOut = 0.2
        let animationDurationOut = 0.25
        Timer.scheduledTimer(withTimeInterval: delayBeforeAnimationIn, repeats: false) { [weak scrollView] _ in
            UIView.animate(
                withDuration: animationDurationIn,
                animations: {
                    scrollView?.contentOffset = offset
                },
                completion: { _ in
                    Timer.scheduledTimer(withTimeInterval: delayBeforeAnimationOut, repeats: false) { _ in
                        UIView.animate(
                            withDuration: animationDurationOut,
                            animations: {
                                scrollView?.contentOffset = originalOffset
                            }, completion: { _ in
                                completion?()
                            }
                        )
                    }
                })
        }
    }
}
