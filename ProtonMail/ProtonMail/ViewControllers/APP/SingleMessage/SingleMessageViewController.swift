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
        .init(maxCount: 1)
    }

    private lazy var contentController: SingleMessageContentViewController = { [unowned self] in
        SingleMessageContentViewController(
            viewModel: self.viewModel.contentViewModel,
            parentScrollView: self.customView.scrollView,
            viewMode: .singleMessage) { action in
            self.coordinator.navigate(to: action)
        }
    }()

    let viewModel: SingleMessageViewModel

    private lazy var navigationTitleLabel = SingleMessageNavigationHeaderView()

    private let coordinator: SingleMessageCoordinator
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

    init(coordinator: SingleMessageCoordinator, viewModel: SingleMessageViewModel) {
        self.coordinator = coordinator
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

        setUpToolBarIfNeeded()
        setupTimerForScheduleSendIfNeeded()
    }

    private func embedChildren() {
        embed(contentController, inside: customView.contentContainer)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.user.undoActionManager.register(handler: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.userActivity.becomeCurrent()
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
        var customViewTitle = viewModel.messageTitle
        if #available(iOS 12.0, *) {
            // Highlight search keywords
            customViewTitle = EncryptedSearchService.shared.addKeywordHighlightingToAttributedString(stringToHighlight: customViewTitle)
        }
        customView.titleTextView.attributedText = customViewTitle

        var navigationTitle = viewModel.message.title.applyMutable(style: .DefaultSmallStrong)
        if #available(iOS 12.0, *) {
            // Highlight search keywords
            navigationTitle = EncryptedSearchService.shared.addKeywordHighlightingToAttributedString(stringToHighlight: navigationTitle)
        }
        navigationTitleLabel.label.attributedText = navigationTitle
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
                self?.navigationController?.popViewController(animated: true)
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

    private func setUpToolBarIfNeeded() {
        let actions = calculateToolBarActions()
        guard customView.toolBar.types != actions.map(\.type) else {
            return
        }
        customView.toolBar.setUpActions(actions)
    }

    private func calculateToolBarActions() -> [PMToolBarView.ActionItem] {
        let types = viewModel.toolbarActionTypes()
        let result: [PMToolBarView.ActionItem] = types.compactMap { type in
            switch type {
            case .markAsRead, .markAsUnread:
                return PMToolBarView.ActionItem(type: type,
                                                handler: { [weak self] in self?.unreadReadAction() })
            case .labelAs:
                return PMToolBarView.ActionItem(type: type,
                                                handler: { [weak self] in self?.labelAsAction() })
            case .trash:
                return PMToolBarView.ActionItem(type: type,
                                                handler: { [weak self] in self?.trashAction() })
            case .delete:
                return PMToolBarView.ActionItem(type: type,
                                                handler: { [weak self] in self?.deleteAction() })
            case .moveTo:
                return PMToolBarView.ActionItem(type: type,
                                                handler: { [weak self] in self?.moveToAction() })
            case .more:
                return PMToolBarView.ActionItem(type: type,
                                                handler: { [weak self] in self?.moreButtonTapped() })
            }
        }
        return result
    }

    @objc
    private func trashAction() {
        let continueAction: () -> Void = { [weak self] in
            self?.viewModel.handleToolBarAction(.trash)
            self?.navigationController?.popViewController(animated: true)
        }

        viewModel.searchForScheduled(displayAlert: {
            self.displayScheduledAlert(scheduledNum: 1, continueAction: continueAction)
        }, continueAction: continueAction)
    }

    @objc
    private func unreadReadAction() {
        viewModel.handleToolBarAction(.markAsUnread)
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
            self?.navigationController?.popViewController(animated: true)
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
                                                                   includeStarring: false,
                                                                   isStarred: viewModel.message.isStarred,
                                                                   isBodyDecryptable: isBodyDecryptable,
                                                                   messageRenderStyle: renderStyle,
                                                                   shouldShowRenderModeOption: shouldDisplayRMOptions,
                                                                   viewMode: .singleMessage,
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
            contentController.presentPrintController()
        case .saveAsPDF:
            contentController.exportPDF()
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
        case .trash:
            let continueAction: () -> Void = { [weak self] in
                self?.viewModel.handleActionSheetAction(action, completion: { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                })
            }
            viewModel.searchForScheduled(displayAlert: { [weak self] in
                self?.displayScheduledAlert(scheduledNum: 1, continueAction: continueAction)
            }, continueAction: continueAction)
        default:
            viewModel.handleActionSheetAction(action, completion: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
        }
    }

    private func handleOpenComposerAction(_ action: MessageViewActionSheetAction) {
        switch action {
        case .reply:
            coordinator.navigate(to: .reply(messageId: viewModel.message.messageID))
        case .replyAll:
            coordinator.navigate(to: .replyAll(messageId: viewModel.message.messageID))
        case .forward:
            coordinator.navigate(to: .forward(messageId: viewModel.message.messageID))
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
        let labelAsViewModel = LabelAsActionSheetViewModelMessages(
            menuLabels: labelAsActionHandler.getLabelMenuItems(),
            messages: [viewModel.message])

        labelAsActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     listener: self,
                     viewModel: labelAsViewModel,
                     addNewLabel: { [weak self] in
                        guard let self = self else { return }
                        if self.allowToCreateLabels(existingLabels: labelAsViewModel.menuLabels.count) {
                            self.coordinator.pendingActionAfterDismissal = { [weak self] in
                                self?.showLabelAsActionSheet()
                            }
                            self.coordinator.navigate(to: .addNewLabel)
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
                     done: { [weak self] isArchive, currentOptionsStatus  in
                        if let message = self?.viewModel.message {
                            self?.labelAsActionHandler
                                .handleLabelAsAction(messages: [message],
                                                     shouldArchive: isArchive,
                                                     currentOptionsStatus: currentOptionsStatus)
                        }
                        self?.dismissActionSheet()
                     })
    }

    private func allowToCreateLabels(existingLabels: Int) -> Bool {
        let isFreeAccount = viewModel.user.userInfo.subscribed == 0
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
                    self.coordinator.pendingActionAfterDismissal = { [weak self] in
                        self?.showMoveToActionSheet()
                    }
                    self.coordinator.navigate(to: .addNewFolder)
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
                    self?.navigationController?.popViewController(animated: true)
                }
                guard isHavingUnsavedChanges, let msg = self?.viewModel.message else {
                    return
                }

                let continueAction: () -> Void = { [weak self] in
                    self?.moveToActionHandler
                        .handleMoveToAction(messages: [msg],
                                            isFromSwipeAction: false)
                }

                if self?.moveToActionHandler.selectedMoveToFolder?.location == .trash {
                    self?.viewModel.searchForScheduled(displayAlert: {
                        self?.displayScheduledAlert(scheduledNum: 1, continueAction: continueAction)
                    }, continueAction: continueAction)
                } else {
                    continueAction()
                }
            })
    }

    private func allowToCreateFolders(existingFolders: Int) -> Bool {
        let isFreeAccount = viewModel.user.userInfo.subscribed == 0
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
    var delaySendSeconds: Int {
        self.viewModel.user.userInfo.delaySendSeconds
    }

    var composerPresentingVC: UIViewController? {
        nil
    }

    func showUndoAction(undoTokens: [String], title: String) { }
}
