//
//  SingleMessageViewController.swift
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
//  along with Proton Mail. If not, see <https://www.gnu.org/licenses/>.

import LifetimeTracker
import ProtonCore_DataModel
import ProtonCore_UIFoundations
import SafariServices
import UIKit

final class SingleMessageViewController: UIViewController, UIScrollViewDelegate, ComposeSaveHintProtocol,
                                   LifetimeTrackable, ScheduledAlertPresenter {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 3)
    }

    private lazy var contentController: SingleMessageContentViewController = { [unowned self] in
        SingleMessageContentViewController(
            viewModel: self.viewModel.contentViewModel,
            parentScrollView: self.customView.scrollView,
            viewMode: .singleMessage
        ) { action in
            self.viewModel.navigate(to: action)
        }
    }()

    let viewModel: SingleMessageViewModel

    private lazy var navigationTitleLabel = SingleMessageNavigationHeaderView()

    private lazy var starBarButton = UIBarButtonItem(
        image: nil,
        style: .plain,
        target: self,
        action: #selector(starButtonTapped)
    )

    private(set) lazy var customView = SingleMessageView()

    private lazy var actionSheetPresenter = MessageViewActionSheetPresenter()
    private lazy var moveToActionSheetPresenter = MoveToActionSheetPresenter()
    private lazy var labelAsActionSheetPresenter = LabelAsActionSheetPresenter()
    private var scheduledSendTimer: Timer?
    var isInPageView: Bool {
        (self.parent as? PagesViewController<MessageID, MessageEntity, Message>) != nil
    }

    init(viewModel: SingleMessageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        trackLifetime()
    }

    deinit {
        scheduledSendTimer?.invalidate()
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.viewDidLoad()
        viewModel.refreshView = { [weak self] in
            self?.reloadMessageRelatedData()
            self?.setUpToolBarIfNeeded()
        }
        setUpSelf()
        embedChildren()
        emptyBackButtonTitleForNextView()

        setupTimerForScheduleSendIfNeeded()
    }

    private func embedChildren() {
        embed(contentController, inside: customView.contentContainer)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.user.undoActionManager.register(handler: self)
        setUpToolBarIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.userActivity.becomeCurrent()
        if !UserInfo.isConversationSwipeEnabled {
            showToolbarCustomizeSpotlightIfNeeded()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.dismissActionSheet()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        viewModel.userActivity.invalidate()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let shouldShowSeparator = scrollView.contentOffset.y >= customView.smallTitleHeaderSeparatorView.frame.maxY
        let shouldShowTitleInNavigationBar = scrollView.contentOffset.y >= customView.titleTextView.frame.maxY

        customView.navigationSeparator.isHidden = !shouldShowSeparator

        if shouldShowTitleInNavigationBar {
            showTitleView()
        } else {
            hideTitleView()
        }
    }

    private func reloadMessageRelatedData() {
        starButtonSetUp(starred: viewModel.message.isStarred)
    }

    private func setUpSelf() {
        customView.titleTextView.attributedText = viewModel.messageTitle
        navigationTitleLabel.label.attributedText = viewModel.message.title.apply(style: FontManager.DefaultSmallStrong)
        navigationTitleLabel.label.lineBreakMode = .byTruncatingTail

        customView.navigationSeparator.isHidden = true
        customView.scrollView.delegate = self
        navigationTitleLabel.label.alpha = 0

        let backButtonItem = UIBarButtonItem.backBarButtonItem(target: self, action: #selector(tapBackButton))
        navigationItem.backBarButtonItem = backButtonItem
        navigationItem.rightBarButtonItem = starBarButton
        navigationItem.titleView = navigationTitleLabel
        starButtonSetUp(starred: viewModel.message.isStarred)

        // Accessibility
        navigationItem.backBarButtonItem?.accessibilityLabel = LocalString._general_back_action
        starBarButton.isAccessibilityElement = true
        starBarButton.accessibilityLabel = LocalString._star_btn_in_message_view
    }

    private func starButtonSetUp(starred: Bool) {
        starBarButton.image = starred ?
        IconProvider.starFilled : IconProvider.star
        starBarButton.tintColor = starred ? ColorProvider.NotificationWarning : ColorProvider.IconWeak
    }

    /// Setup timer to dismiss the view if the view is showing a scheduled-send message.
    private func setupTimerForScheduleSendIfNeeded() {
        guard viewModel.message.isScheduledSend,
              viewModel.message.contains(location: .scheduled),
              let scheduledTime = viewModel.message.time else {
            return
        }
        scheduledSendTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true, block: { [weak self] _ in
            if scheduledTime.timeIntervalSince(Date()) <= 0 {
                self?.viewModel.navigateToNextMessage(
                    isInPageView: self?.isInPageView ?? false,
                    popCurrentView: {
                        self?.navigationController?.popViewController(animated: true)
                    }
                )
            }
        })
    }

    required init?(coder: NSCoder) {
        nil
    }
}

// MARK: - Actions
extension SingleMessageViewController {
    @objc
    private func tapBackButton() {
        navigationController?.popViewController(animated: true)
    }

    @objc
    private func starButtonTapped() {
        viewModel.starTapped()
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

    func setUpToolBarIfNeeded() {
        let actions = calculateToolBarActions()
        guard customView.toolbar.types != actions.map(\.type) else {
            return
        }
        customView.toolbar.setUpActions(actions)
    }

    private func calculateToolBarActions() -> [PMToolBarView.ActionItem] {
        let types = viewModel.toolbarActionTypes()
        let result: [PMToolBarView.ActionItem] = types.compactMap { type in
            return PMToolBarView.ActionItem(type: type,
                                            handler: { [weak self] in
                self?.handleActionSheetAction(type)
            })
        }
        return result
    }

    @objc
    private func trashAction() {
        let continueAction: () -> Void = { [weak self] in
            self?.viewModel.handleToolBarAction(.trash)
            self?.viewModel.navigateToNextMessage(
                isInPageView: self?.isInPageView ?? false,
                popCurrentView: {
                    self?.navigationController?.popViewController(animated: true)
                }
            )
        }

        viewModel.searchForScheduled(displayAlert: {
            self.displayScheduledAlert(scheduledNum: 1) {
                self.showMessageMoved(title: LocalString._message_moved_to_drafts)
                continueAction()
            }
        }, continueAction: {
            self.showMessageMoved(title: LocalString._messages_has_been_moved, undoActionType: .trash)
            continueAction()
        })
    }

    @objc
    private func unreadReadAction() {
        viewModel.handleToolBarAction(.markUnread)
        navigationController?.popViewController(animated: true)
    }

    @objc
    private func moveToAction() {
        showMoveToActionSheet()
    }

    @objc
    private func labelAsAction() {
        showLabelAsActionSheet()
    }

    @objc
    private func deleteAction() {
        showDeleteAlert(deleteHandler: { [weak self] _ in
            self?.viewModel.handleToolBarAction(.delete)
            self?.viewModel.navigateToNextMessage(
                isInPageView: self?.isInPageView ?? false,
                popCurrentView: {
                    self?.navigationController?.popViewController(animated: true)
                }
            )
        })
    }

    @objc
    func moreButtonTapped() {
        guard let navigationVC = self.navigationController else { return }
        let isBodyDecryptable = viewModel.contentViewModel.messageInfoProvider.isBodyDecryptable
        let renderStyle = viewModel.contentViewModel.messageInfoProvider.currentMessageRenderStyle
        let shouldDisplayRMOptions = viewModel.contentViewModel.messageInfoProvider.shouldDisplayRenderModeOptions
        let isScheduledSend = viewModel.contentViewModel.messageInfoProvider.message.isScheduledSend
        let actionSheetViewModel = MessageViewActionSheetViewModel(title: viewModel.message.title,
                                                                   labelID: viewModel.labelId,
                                                                   isStarred: viewModel.message.isStarred,
                                                                   isBodyDecryptable: isBodyDecryptable,
                                                                   messageRenderStyle: renderStyle,
                                                                   shouldShowRenderModeOption: shouldDisplayRMOptions,
                                                                   isScheduledSend: isScheduledSend)
        actionSheetPresenter.present(on: navigationVC,
                                     listener: self,
                                     viewModel: actionSheetViewModel) { [weak self] action in
            self?.handleActionSheetAction(action)
        }
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

    func showToolbarCustomizeSpotlightIfNeeded() {
        guard viewModel.shouldShowToolbarCustomizeSpotlight(),
              let targetRect = customView.toolbarCGRect(),
              let navView = navigationController?.view,
              !navView.subviews.contains(where: { $0 is ToolbarCustomizeSpotlightView })
        else {
            return
        }
        let convertedRect = customView.convert(targetRect, to: self.navigationController?.view)
        let spotlight = ToolbarCustomizeSpotlightView()
        spotlight.presentOn(
            view: navView,
            targetFrame: convertedRect
        )
        spotlight.navigateToToolbarCustomizeView = { [weak self] in
            self?.viewModel.navigate(to: .toolbarSettingView)
        }
        viewModel.setToolbarCustomizeSpotlightViewIsShown()
    }
}

private extension SingleMessageViewController {
    // swiftlint:disable:next function_body_length
    func handleActionSheetAction(_ action: MessageViewActionSheetAction) {
        switch action {
        case .reply, .replyAll, .forward, .replyInConversation, .forwardInConversation, .replyOrReplyAllInConversation, .replyAllInConversation:
            handleOpenComposerAction(action)
        case .labelAs:
            showLabelAsActionSheet()
        case .moveTo:
            showMoveToActionSheet()
        case .print:
            let renderer = ConversationPrintRenderer([contentController])
            contentController.presentPrintController(renderer: renderer, jobName: viewModel.message.title)
        case .saveAsPDF:

            let renderer = ConversationPrintRenderer([contentController])
            contentController.exportPDF(
                renderer: renderer,
                fileName: "\(viewModel.message.title).pdf",
                sourceView: customView.toolbar
            )
        case .viewHeaders, .viewHTML:
            handleOpenViewAction(action)
        case .dismiss:
            let actionSheet = navigationController?.view.subviews.compactMap { $0 as? PMActionSheet }.first
            actionSheet?.dismiss(animated: true)
        case .delete:
            showDeleteAlert(deleteHandler: { [weak self] _ in
                self?.viewModel.handleActionSheetAction(action, completion: { [weak self] in
                    self?.viewModel.navigateToNextMessage(
                        isInPageView: self?.isInPageView ?? false,
                        popCurrentView: {
                            self?.navigationController?.popViewController(animated: true)
                        }
                    )
                })
            })
        case .reportPhishing:
            showPhishingAlert { [weak self] _ in
                self?.viewModel.handleActionSheetAction(action, completion: { [weak self] in
                    self?.viewModel.navigateToNextMessage(
                        isInPageView: self?.isInPageView ?? false,
                        popCurrentView: {
                            self?.navigationController?.popViewController(animated: true)
                        }
                    )
                })
            }
        case .toolbarCustomization:
            showToolbarActionCustomizationView()
        case .markUnread, .markRead:
            unreadReadAction()
        case .more:
            moreButtonTapped()
        case .viewInDarkMode, .viewInLightMode:
            viewModel.handleActionSheetAction(action, completion: {})
        case .archive, .spam, .inbox, .spamMoveToInbox, .star, .unstar:
            viewModel.handleActionSheetAction(action) { [weak self] in
                self?.viewModel.navigateToNextMessage(
                    isInPageView: self?.isInPageView ?? false,
                    popCurrentView: {
                        self?.navigationController?.popViewController(animated: true)
                    }
                )
            }
        case .trash:
            let continueAction: () -> Void = { [weak self] in
                self?.viewModel.handleActionSheetAction(action, completion: { [weak self] in
                    self?.viewModel.navigateToNextMessage(
                        isInPageView: self?.isInPageView ?? false,
                        popCurrentView: {
                            self?.navigationController?.popViewController(animated: true)
                        }
                    )
                })
            }
            viewModel.searchForScheduled(displayAlert: { [weak self] in
                self?.displayScheduledAlert(scheduledNum: 1, continueAction: continueAction)
            }, continueAction: continueAction)
        case .replyOrReplyAll:
            if viewModel.message.allRecipients.count > 1 {
                handleOpenComposerAction(.replyAll)
            } else {
                handleOpenComposerAction(.reply)
            }
        }
    }

    private func handleOpenComposerAction(_ action: MessageViewActionSheetAction) {
        switch action {
        case .reply, .replyInConversation:
            viewModel.navigate(to: .reply(messageId: viewModel.message.messageID))
        case .replyAll, .replyAllInConversation:
            viewModel.navigate(to: .replyAll(messageId: viewModel.message.messageID))
        case .forward, .forwardInConversation:
            viewModel.navigate(to: .forward(messageId: viewModel.message.messageID))
        default:
            return
        }
    }

    private func handleOpenViewAction(_ action: MessageViewActionSheetAction) {
        switch action {
        case .viewHeaders:
            if let url = viewModel.getMessageHeaderUrl() {
                viewModel.navigate(to: .viewHeaders(url: url))
            }
        case .viewHTML:
            if let url = viewModel.getMessageBodyUrl() {
                viewModel.navigate(to: .viewHTML(url: url))
            }
        default:
            return
        }
    }

    private func showToolbarActionCustomizationView() {
        viewModel.navigate(to: .toolbarCustomization(
            currentActions: viewModel.actionsForToolbarCustomizeView(),
            allActions: viewModel.toolbarCustomizationAllAvailableActions()
        ))
    }
}

extension SingleMessageViewController: LabelAsActionSheetPresentProtocol {
    var labelAsActionHandler: LabelAsActionSheetProtocol {
        return viewModel
    }

    func showLabelAsActionSheet() {
        let labelAsViewModel = LabelAsActionSheetViewModelMessages(
            menuLabels: labelAsActionHandler.getLabelMenuItems(),
            messages: [viewModel.message]
        )

        labelAsActionSheetPresenter
            .present(
                on: self.navigationController ?? self,
                listener: self,
                viewModel: labelAsViewModel,
                addNewLabel: { [weak self] in
                    guard let self = self else { return }
                    if self.allowToCreateLabels(existingLabels: labelAsViewModel.menuLabels.count) {
                        self.viewModel.coordinator.pendingActionAfterDismissal = { [weak self] in
                            self?.showLabelAsActionSheet()
                        }
                        self.viewModel.navigate(to: .addNewLabel)
                    } else {
                        self.showAlertLabelCreationNotAllowed()
                    }
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
                done: { [weak self] isArchive, currentOptionsStatus in
                    if let message = self?.viewModel.message {
                        self?.labelAsActionHandler
                            .handleLabelAsAction(messages: [message],
                                                 shouldArchive: isArchive,
                                                 currentOptionsStatus: currentOptionsStatus)
                    }
                    self?.dismissActionSheet()
                    if isArchive {
                        self?.showMessageMoved(title: LocalString._messages_has_been_moved, undoActionType: .archive)
                        self?.viewModel.navigateToNextMessage(
                            isInPageView: self?.isInPageView ?? false,
                            popCurrentView: nil
                        )
                    }
                }
            )
    }

    private func allowToCreateLabels(existingLabels: Int) -> Bool {
        let isFreeAccount = viewModel.user.userInfo.subscribed.isEmpty
        if isFreeAccount {
            return existingLabels < Constants.FreePlan.maxNumberOfLabels
        }
        return true
    }

    private func showAlertLabelCreationNotAllowed() {
        let title = LocalString._creating_label_not_allowed
        let message = LocalString._upgrade_to_create_label
        showAlert(title: title, message: message)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addOKAction()
        self.present(alert, animated: true, completion: nil)
    }

    private func showMessageMoved(title: String, undoActionType: UndoAction? = nil) {
        if var type = undoActionType {
            switch type {
            case .custom(let labelID) where labelID == Message.Location.archive.labelID:
                type = .archive
            case .custom(let labelID) where labelID == Message.Location.trash.labelID:
                type = .trash
            case .custom(let labelID) where labelID == Message.Location.spam.labelID:
                type = .spam
            default:
                break
            }
            viewModel.user.undoActionManager.addTitleWithAction(title: title, action: type)
        }
        let banner = PMBanner(message: title, style: PMBannerNewStyle.info, bannerHandler: PMBanner.dismiss)
        banner.show(at: .bottom, on: self)
    }
}

extension SingleMessageViewController: MoveToActionSheetPresentProtocol {
    var moveToActionHandler: MoveToActionSheetProtocol {
        return viewModel
    }

    // swiftlint:disable function_body_length
    func showMoveToActionSheet() {
        let isEnableColor = viewModel.user.isEnableFolderColor
        let isInherit = viewModel.user.isInheritParentFolderColor
        let moveToViewModel =
            MoveToActionSheetViewModelMessages(menuLabels: viewModel.getFolderMenuItems(),
                                               messages: [viewModel.message],
                                               isEnableColor: isEnableColor,
                                               isInherit: isInherit)
        moveToActionSheetPresenter.present(
            on: self.navigationController ?? self,
            listener: self,
            viewModel: moveToViewModel,
            addNewFolder: { [weak self] in
                guard let self = self else { return }
                if self.allowToCreateFolders(existingFolders: self.viewModel.getCustomFolderMenuItems().count) {
                    self.viewModel.coordinator.pendingActionAfterDismissal = { [weak self] in
                        self?.showMoveToActionSheet()
                    }
                    self.viewModel.navigate(to: .addNewFolder)
                } else {
                    self.showAlertFolderCreationNotAllowed()
                }
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
                    self?.viewModel.navigateToNextMessage(
                        isInPageView: self?.isInPageView ?? false,
                        popCurrentView: {
                            self?.navigationController?.popViewController(animated: true)
                        }
                    )
                }
                guard isHavingUnsavedChanges,
                      let msg = self?.viewModel.message,
                      let destinationId = self?.moveToActionHandler.selectedMoveToFolder?.location.labelID else {
                    return
                }

                let continueAction: () -> Void = { [weak self] in
                    self?.moveToActionHandler
                        .handleMoveToAction(messages: [msg],
                                            isFromSwipeAction: false)
                }

                if self?.moveToActionHandler.selectedMoveToFolder?.location == .trash {
                    self?.viewModel.searchForScheduled(displayAlert: {
                        self?.displayScheduledAlert(scheduledNum: 1) {
                            self?.showMessageMoved(title: LocalString._message_moved_to_drafts)
                            continueAction()
                        }
                    }, continueAction: {
                        self?.showMessageMoved(title: LocalString._messages_has_been_moved,
                                               undoActionType: .custom(destinationId))
                        continueAction()

                    })
                } else {
                    self?.showMessageMoved(title: LocalString._messages_has_been_moved,
                                           undoActionType: .custom(destinationId))
                    continueAction()
                }
            })
    }

    private func allowToCreateFolders(existingFolders: Int) -> Bool {
        let isFreeAccount = viewModel.user.userInfo.subscribed.isEmpty
        if isFreeAccount {
            return existingFolders < Constants.FreePlan.maxNumberOfFolders
        }
        return true
    }

    private func showAlertFolderCreationNotAllowed() {
        let title = LocalString._creating_folder_not_allowed
        let message = LocalString._upgrade_to_create_folder
        showAlert(title: title, message: message)
    }
}

extension SingleMessageViewController: PMActionSheetEventsListener {
    func willPresent() {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    func willDismiss() {}

    func didDismiss() {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
}

extension SingleMessageViewController: UndoActionHandlerBase {
    var undoActionManager: UndoActionManagerProtocol? {
        viewModel.user.undoActionManager
    }

    var delaySendSeconds: Int {
        self.viewModel.user.userInfo.delaySendSeconds
    }

    var composerPresentingVC: UIViewController? {
        self
    }

    func showUndoAction(undoTokens: [String], title: String) { }
}
