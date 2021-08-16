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
//  along with ProtonMail. If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations
import SafariServices
import UIKit

class SingleMessageViewController: UIViewController, UIScrollViewDelegate, ComposeSaveHintProtocol {

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
    private var actionBar: PMActionBar?
    private lazy var moveToActionSheetPresenter = MoveToActionSheetPresenter()
    private lazy var labelAsActionSheetPresenter = LabelAsActionSheetPresenter()

    init(coordinator: SingleMessageCoordinator, viewModel: SingleMessageViewModel) {
        self.coordinator = coordinator
        self.viewModel = viewModel
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
        emptyBackButtonTitleForNextView()
        showActionBar()

        starBarButton.isAccessibilityElement = true
        starBarButton.accessibilityLabel = LocalString._star_btn_in_message_view
    }

    private func embedChildren() {
        embed(contentController, inside: customView.contentContainer)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.userActivity.becomeCurrent()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        viewModel.userActivity.invalidate()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let shouldShowSeparator = scrollView.contentOffset.y >= customView.smallTitleHeaderSeparatorView.frame.maxY
        let shouldShowTitleInNavigationBar = scrollView.contentOffset.y >= customView.titleLabel.frame.maxY

        customView.navigationSeparator.isHidden = !shouldShowSeparator
        shouldShowTitleInNavigationBar ? showTitleView() : hideTitleView()
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

    required init?(coder: NSCoder) {
        nil
    }
}

// MARK: - Actions
private extension SingleMessageViewController {
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

    private func showActionBar() {
        guard self.actionBar == nil else { return }

        let actions = viewModel.getActionTypes()
        var actionBarItems: [PMActionBarItem] = []
        for (key, action) in actions.enumerated() {
            let actionHandler: (PMActionBarItem) -> Void = { [weak self] _ in
                switch action {
                case .more:
                    self?.moreButtonTapped()
                case .reply:
                    self?.coordinator.navigate(to: .reply(messageId: self?.viewModel.message.messageID ?? .empty))
                case .replyAll:
                    self?.coordinator.navigate(to: .replyAll(messageId: self?.viewModel.message.messageID ?? .empty))
                case .delete:
                    self?.showDeleteAlert(deleteHandler: { [weak self] _ in
                        self?.viewModel.handleActionBarAction(action)
                        self?.navigationController?.popViewController(animated: true)
                    })
                case .labelAs:
                    self?.showLabelAsActionSheet()
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
        let separator = PMActionBarItem(width: 1, verticalPadding: 6, color: UIColorManager.FloatyText)
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
                                                                   labelID: viewModel.labelId,
                                                                   includeStarring: false,
                                                                   isStarred: viewModel.message.starred)
        actionSheetPresenter.present(on: navigationVC,
                                     viewModel: actionSheetViewModel) { [weak self] action in
            self?.handleActionSheetAction(action)
        }
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
            coordinator.navigate(to: .reply(messageId: viewModel.message.messageID))
        case .replyAll:
            coordinator.navigate(to: .replyAll(messageId: viewModel.message.messageID))
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
        let labelAsViewModel = LabelAsActionSheetViewModelMessages(menuLabels: labelAsActionHandler.getLabelMenuItems(),
                                                                   messages: [viewModel.message])

        labelAsActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     viewModel: labelAsViewModel,
                     addNewLabel: { [weak self] in
                        self?.coordinator.pendingActionAfterDismissal = { [weak self] in
                            self?.showLabelAsActionSheet()
                        }
                        self?.coordinator.navigate(to: .addNewLabel)
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
}

extension SingleMessageViewController: MoveToActionSheetPresentProtocol {
    var moveToActionHandler: MoveToActionSheetProtocol {
        return viewModel
    }

    func showMoveToActionSheet() {
        let isEnableColor = viewModel.user.isEnableFolderColor
        let isInherit = viewModel.user.isInheritParentFolderColor
        let moveToViewModel =
            MoveToActionSheetViewModelMessages(menuLabels: viewModel.getFolderMenuItems(),
                                               messages: [viewModel.message],
                                               isEnableColor: isEnableColor,
                                               isInherit: isInherit,
                                               labelId: viewModel.labelId)
        moveToActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     viewModel: moveToViewModel,
                     addNewFolder: { [weak self] in
                        self?.coordinator.pendingActionAfterDismissal = { [weak self] in
                            self?.showMoveToActionSheet()
                        }
                        self?.coordinator.navigate(to: .addNewFolder)
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
