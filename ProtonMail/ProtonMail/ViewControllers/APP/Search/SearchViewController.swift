//
//  SearchViewController.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
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
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import CoreData
import MBProgressHUD
import ProtonCore_DataModel
import ProtonCore_Foundations
import ProtonCore_UIFoundations
import ProtonMailAnalytics
import UIKit

protocol SearchViewUIProtocol: UIViewController {
    var listEditing: Bool { get }

    func checkNoResultView()
    func activityIndicator(isAnimating: Bool)
    func refreshActionBarItems()
    func reloadTable()
    func showSlowSearchBanner()
    func removeSearchInfoBanner()
}

class SearchViewController: ProtonMailViewController, ComposeSaveHintProtocol, CoordinatorDismissalObserver, ScheduledAlertPresenter {

    @IBOutlet private var navigationBarView: UIView!
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private var noResultLabel: UILabel!
    @IBOutlet private var toolBar: PMToolBarView!
    private let searchBar = SearchBarView()
    private var enableSearchInfoBanner: Bool = false
    private var hasTableBeenShiftedToDisplayBanner: Bool = false
    private var tableShiftOffset: CGFloat = 0.0
    private var searchInfoBanner: BannerView?
    private var slowSearchBanner: BannerView?
    private var popupView: PopUpView?
    private var grayedOutView: UIView?
    private var actionBar: PMActionBar?
    private var actionSheet: PMActionSheet?

    // MARK: - Private Constants
    private let kLongPressDuration: CFTimeInterval = 0.60 // seconds

    private let serialQueue = DispatchQueue(label: "com.protonamil.messageTapped")
    private var messageTapped = false
    private(set) var listEditing: Bool = false

    private let viewModel: SearchVMProtocol
    private var query: String = ""
    private let mailListActionSheetPresenter = MailListActionSheetPresenter()
    private lazy var moveToActionSheetPresenter = MoveToActionSheetPresenter()
    private lazy var labelAsActionSheetPresenter = LabelAsActionSheetPresenter()
    private let cellPresenter = NewMailboxMessageCellPresenter()
    var pendingActionAfterDismissal: (() -> Void)?

    init(viewModel: SearchVMProtocol) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
        self.viewModel.uiDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.edgesForExtendedLayout = UIRectEdge()
        self.extendedLayoutIncludesOpaqueBars = false
        self.navigationController?.navigationBar.isTranslucent = false
        self.view.backgroundColor = ColorProvider.BackgroundNorm

        navigationBarView.backgroundColor = ColorProvider.BackgroundNorm
        self.emptyBackButtonTitleForNextView()

        noResultLabel.text = LocalString._no_results_found

        self.setupSearchBar()
        self.setupTableview()
        self.setupActivityIndicator()
        self.viewModel.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        self.tableView.reloadData()
        self.viewModel.user.undoActionManager.register(handler: self)

        if UserInfo.isEncryptedSearchEnabledPaidUsers || UserInfo.isEncryptedSearchEnabledFreeUsers {
            // If encrypted search is not enabled - show a popup that it is available - if it hasn't been shown already
            if userCachedStatus.isEncryptedSearchOn == false &&
               userCachedStatus.isEncryptedSearchAvailablePopupAlreadyShown == false {
                if self.popupView == nil {  // Show popup if it is not already shown
                    self.showPopUpToEnableEncryptedSearch()
                }
                userCachedStatus.isEncryptedSearchAvailablePopupAlreadyShown = true
            } else if userCachedStatus.isEncryptedSearchOn == true ||
                      userCachedStatus.isEncryptedSearchAvailablePopupAlreadyShown == true {
                self.popupView?.remove()
                // remove gray view
                self.grayedOutView?.removeFromSuperview()
                // show keyboard again
                self.searchBar.textField.becomeFirstResponder()
            }

            // Show a search info banner depending on the ES state
            if self.enableSearchInfoBanner {
                UIView.performWithoutAnimation {
                    self.showSearchInfoBanner()
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchBar.textField.resignFirstResponder()
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.zeroMargin()
    }
}

// MARK: UI related
extension SearchViewController {
    private func setupSearchBar() {
        searchBar.cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        searchBar.clearButton.addTarget(self, action: #selector(clearAction), for: .touchUpInside)
        searchBar.textField.delegate = self
        searchBar.textField.becomeFirstResponder()
        // searchBar.textField.addTarget(self, action: #selector(), for: .editingChanged)
        navigationBarView.addSubview(searchBar)
        [
            searchBar.topAnchor.constraint(equalTo: navigationBarView.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: navigationBarView.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: navigationBarView.trailingAnchor, constant: -16),
            searchBar.bottomAnchor.constraint(equalTo: navigationBarView.bottomAnchor)
        ].activate()
    }

    private func setupTableview() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.noSeparatorsBelowFooter()
        self.tableView.register(NewMailboxMessageCell.self, forCellReuseIdentifier: NewMailboxMessageCell.defaultID())
        self.tableView.contentInsetAdjustmentBehavior = .automatic
        self.tableView.estimatedRowHeight = 100
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.backgroundColor = .clear
        self.tableView.separatorColor = ColorProvider.SeparatorNorm
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self,
                                                                      action: #selector(handleLongPress(_:)))
        longPressGestureRecognizer.minimumPressDuration = kLongPressDuration
        self.tableView.addGestureRecognizer(longPressGestureRecognizer)
    }

    private func setupActivityIndicator() {
        activityIndicator.color = ColorProvider.BrandNorm
        activityIndicator.isHidden = true
        activityIndicator.hidesWhenStopped = true
    }

    private func showPopUpToEnableEncryptedSearch() {
        // Gray out superview
        self.grayedOutView = UIView(frame: UIScreen.main.bounds)
        self.grayedOutView!.backgroundColor = ColorProvider.BlenderNorm
        self.view.addSubview(self.grayedOutView!)

        // hide keyboard when pop up is active
        self.searchBar.textField.resignFirstResponder()

        let image = UIImage(named: "es-icon")!
        let buttonAction: PopUpView.buttonActionBlock? = {
            let viewModel = SettingsEncryptedSearchViewModel(encryptedSearchCache: userCachedStatus)
            let viewController = SettingsEncryptedSearchViewController(viewModel: viewModel)
            self.show(viewController, sender: self)
        }
        let dismissAction: PopUpView.dismissActionBlock? = {
            // remove gray view
            self.grayedOutView?.removeFromSuperview()
            // show keyboard again
            self.searchBar.textField.becomeFirstResponder()
        }
        self.popupView = PopUpView(title: LocalString._encrypted_search_popup_title,
                                   description: LocalString._encrypted_search_popup_description,
                                   image: image,
                                   titleOfButton: LocalString._encrypted_search_popup_button_title,
                                   buttonAction: buttonAction,
                                   dismissAction: dismissAction)
        self.view.addSubview(self.popupView!)

        self.popupView!.translatesAutoresizingMaskIntoConstraints = false
        self.popupView!.layer.cornerRadius = 8
        NSLayoutConstraint.activate([
            self.popupView!.topAnchor.constraint(equalTo: self.view.topAnchor, constant: self.view.bounds.height-276),
            self.popupView!.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.popupView!.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.popupView!.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])

        self.popupView!.popUp(on: self.view, from: .bottom)
    }
}

extension SearchViewController {
    internal func showSearchInfoBanner() {
        var text: String = ""
        var link: String = ""

        // Remove any existing banner
        self.removeSearchInfoBanner()

        let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
        if let userID = usersManager.firstUser?.userInfo.userId {
            let state = EncryptedSearchService.shared.getESState(userID: userID)
            switch state {
            case .downloading, .refresh, .metadataIndexing:
                text = LocalString._encrypted_search_info_search_downloading
                link = LocalString._encrypted_search_info_search_downloading_link
            case .paused:
                text = LocalString._encrypted_search_info_search_paused
                link = LocalString._encrypted_search_info_search_paused_link
            case .partial:  // storage limit reached
                text = LocalString._encrypted_search_info_search_partial_prefix +
                       EncryptedSearchIndexService.shared.getOldestMessageInSearchIndex(for: userID).asString +
                       LocalString._encrypted_search_info_search_partial_suffix
                link = LocalString._encrypted_search_info_search_partial_link
            case .lowstorage:  // storage low
                text = LocalString._encrypted_search_info_search_lowstorage_prefix +
                       EncryptedSearchIndexService.shared.getOldestMessageInSearchIndex(for: userID).asString +
                       LocalString._encrypted_search_info_search_lowstorage_suffix
            case .complete, .undetermined, .background, .backgroundStopped, .disabled:
                return
            }

            DispatchQueue.main.async {
                let dismissActionCallback: BannerView.dismissActionBlock? = {
                    if self.hasTableBeenShiftedToDisplayBanner {
                        self.shiftTableUpAsBannerHasBeenRemoved()
                        self.hasTableBeenShiftedToDisplayBanner = false
                    }
                }
                let handleAttributedTextCallback: BannerView.tapAttributedTextActionBlock? = {
                    switch state {
                    case .complete, .disabled, .undetermined, .lowstorage, .background, .backgroundStopped:
                        break
                    case .partial:
                        let viewModel = SettingsEncryptedSearchDownloadedMessagesViewModel(encryptedSearchDownloadedMessagesCache: userCachedStatus)
                        let viewController = SettingsEncryptedSearchDownloadedMessagesViewController(viewModel: viewModel)
                        self.show(viewController, sender: self)
                    case .downloading, .paused, .refresh, .metadataIndexing:
                        let viewModel = SettingsEncryptedSearchViewModel(encryptedSearchCache: userCachedStatus)
                        let viewController = SettingsEncryptedSearchViewController(viewModel: viewModel)
                        self.show(viewController, sender: self)
                    }
                }

                let positionOfSearchBar = self.searchBar.superview?.convert(self.searchBar.frame.origin, to: nil)
                // Top corner of search bar + size of search bar + distance to top of banner
                let offset = (positionOfSearchBar?.y ?? 48.0) + 36.0 + 20.0
                self.searchInfoBanner = BannerView(appearance: .esGray,
                                                   message: text,
                                                   buttons: nil,
                                                   offset: offset,
                                                   dismissDuration: Double.infinity,
                                                   link: link,
                                                   handleAttributedTextTap: handleAttributedTextCallback,
                                                   dismissAction: dismissActionCallback)
                self.view.addSubview(self.searchInfoBanner!)
                self.searchInfoBanner?.displayBanner(on: self.view)
            }
        }
    }

    internal func removeSearchInfoBanner() {
        self.searchInfoBanner?.remove(animated: false)
        self.searchInfoBanner = nil

        /*if userCachedStatus.isEncryptedSearchOn == false {
            // Clear existing search results
            self.viewModel.cleanExistingSearchResults()
            // Run search on server
            self.viewModel.fetchRemoteData(query: self.query, fromStart: true, forceSearchOnServer: true)
        }*/
    }

    internal func shiftTableDownToMakeSpaceForBanner() {
        // Shift tableview down to make place for the banner
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2) {
                var frame = self.tableView.frame
                // Size of banner + distance to top of table view
                self.tableShiftOffset = ((self.searchInfoBanner?.frame.height ?? 60) + 20)
                frame.origin.y += self.tableShiftOffset
                self.tableView.frame = frame
            }
        }
    }

    internal func shiftTableUpAsBannerHasBeenRemoved() {
        // Shift tableview back up as banner has been removed
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2) {
                var frame = self.tableView.frame
                frame.origin.y -= self.tableShiftOffset
                self.tableView.frame = frame
            }
        }
    }
}

// MARK: Actions
extension SearchViewController {
    @objc
    private func handleLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        self.showCheckOptions(longPressGestureRecognizer)
    }

    @objc
    private func cancelButtonTapped() {
        if listEditing {
            self.cancelEditingMode()
        } else {
            self.viewModel.cleanLocalIndex()
            // clean ES search query to disable keyword highlighting
            EncryptedSearchService.shared.searchQuery = []
            self.dismiss(animated: true, completion: nil)
        }
    }

    @objc
    private func clearAction() {
        searchBar.textField.text = nil
        searchBar.textField.sendActions(for: .editingChanged)
    }

    @IBAction func tapAction(_ sender: AnyObject) {
        searchBar.textField.resignFirstResponder()
    }
}

// MARK: Action bar / sheet related
extension SearchViewController {
    func refreshActionBarItems() {
        let actions = self.viewModel.getActionBarActions()
        var actionItems: [PMToolBarView.ActionItem] = []

        for action in actions {
            let actionHandler: () -> Void = { [weak self] in
                guard let self = self else { return }
                if action == .more {
                    self.moreButtonTapped()
                } else {
                    guard !self.viewModel.selectedIDs.isEmpty else {
                        self.showNoEmailSelected(title: LocalString._warning)
                        return
                    }
                    switch action {
                    case .delete:
                        self.showDeleteAlert { [weak self] in
                            guard let `self` = self else { return }
                            self.viewModel.handleBarActions(action)
                            self.showMessageMoved(title: LocalString._messages_has_been_deleted)
                        }
                    case .moveTo:
                        self.folderButtonTapped()
                    case .labelAs:
                        self.labelButtonTapped()
                    case .markAsUnread, .markAsRead:
                        self.viewModel.handleBarActions(action)
                    case .trash:
                        self.showTrashScheduleAlertIfNeeded { [weak self] scheduledNum in
                            self?.viewModel.handleBarActions(action)
                            let title: String
                            if scheduledNum == 0 {
                                title = LocalString._messages_has_been_moved
                            } else {
                                title = String(format: LocalString._message_moved_to_drafts, scheduledNum)
                            }
                            self?.showMessageMoved(title: title)
                        }

                    case .more:
                        assertionFailure("handled above")
                    }
                }
            }

            let barItem = PMToolBarView.ActionItem(type: action, handler: actionHandler)
            actionItems.append(barItem)
        }
        self.toolBar.setUpActions(actionItems)
    }

    private func showActionBar() {
        self.setToolBarHidden(false)
    }

    private func hideActionBar() {
        self.setToolBarHidden(true)
    }

    private func setToolBarHidden(_ hidden: Bool) {
        /*
         http://www.openradar.me/25087688

         > isHidden seems to be cumulative in UIStackViews, so we have to ensure to not set it the same value twice.
         */
        guard self.toolBar.isHidden != hidden else {
            return
        }

        UIView.animate(withDuration: 0.25) {
            self.toolBar.isHidden = hidden
        }
    }

    private func hideActionSheet() {
        self.actionSheet?.dismiss(animated: true)
        self.actionSheet = nil
    }

    private func moreButtonTapped() {
        mailListActionSheetPresenter.present(
            on: navigationController ?? self,
            viewModel: viewModel.getActionSheetViewModel(),
            action: { [weak self] in
                self?.viewModel.handleActionSheetAction($0)
                self?.handleActionSheetAction($0)
            }
        )
    }

    private func folderButtonTapped() {
        guard !self.viewModel.selectedIDs.isEmpty else {
            showNoEmailSelected(title: LocalString._apply_labels)
            return
        }

        let isEnableColor = viewModel.user.isEnableFolderColor
        let isInherit = viewModel.user.isInheritParentFolderColor
        let messages = viewModel.selectedMessages
        if !messages.isEmpty {
            showMoveToActionSheet(messages: messages,
                                  isEnableColor: isEnableColor,
                                  isInherit: isInherit)
        }
    }

    private func labelButtonTapped() {
        guard !viewModel.selectedIDs.isEmpty else {
            showNoEmailSelected(title: LocalString._apply_labels)
            return
        }
        showLabelAsActionSheet(messages: viewModel.selectedMessages)
    }

    private func handleActionSheetAction(_ action: MailListSheetAction) {
        switch action {
        case .dismiss:
            dismissActionSheet()
        case .remove, .moveToArchive, .moveToSpam, .moveToInbox:
            showMessageMoved(title: LocalString._messages_has_been_moved)
            cancelButtonTapped()
        case .markRead, .markUnread, .star, .unstar:
            break
        case .delete:
            showDeleteAlert { [weak self] in
                guard let `self` = self else { return }
                self.viewModel.deleteSelectedMessages()
            }
        case .labelAs:
            labelButtonTapped()
        case .moveTo:
            folderButtonTapped()
        }
    }

    private func showNoEmailSelected(title: String) {
        let alert = UIAlertController(title: title,
                                      message: LocalString._message_list_no_email_selected,
                                      preferredStyle: .alert)
        alert.addOKAction()
        self.present(alert, animated: true, completion: nil)
    }

    private func showDeleteAlert(yesHandler: @escaping () -> Void) {
        let messagesCount = viewModel.selectedIDs.count
        let title = messagesCount > 1 ?
            String(format: LocalString._messages_delete_confirmation_alert_title, messagesCount) :
            LocalString._single_message_delete_confirmation_alert_title
        let message = messagesCount > 1 ?
            String(format: LocalString._messages_delete_confirmation_alert_message, messagesCount) :
            LocalString._single_message_delete_confirmation_alert_message
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let yes = UIAlertAction(title: LocalString._general_delete_action, style: .destructive) { [weak self] _ in
            yesHandler()
            self?.cancelButtonTapped()
        }
        let cancel = UIAlertAction(title: LocalString._general_cancel_button, style: .cancel)
        [yes, cancel].forEach(alert.addAction)
        present(alert, animated: true, completion: nil)
    }

    private func showTrashScheduleAlertIfNeeded(continueAction: @escaping (Int) -> Void) {
        let num = viewModel.scheduledMessagesFromSelected().count
        guard num > 0 else {
            continueAction(0)
            return
        }
        displayScheduledAlert(scheduledNum: num) {
            continueAction(num)
        }
    }

    private func showMessageMoved(title: String) {
        guard UIApplication.shared.applicationState == .active else {
            return
        }
        let banner = PMBanner(
            message: title,
            style: PMBannerNewStyle.info,
            dismissDuration: 3,
            bannerHandler: PMBanner.dismiss
        )
        banner.show(at: .bottom, on: self)
    }

    private var moveToActionHandler: MoveToActionSheetProtocol? {
        guard let searchVM = self.viewModel as? SearchViewModel else {
            return nil
        }
        return searchVM
    }

    private func showMoveToActionSheet(messages: [MessageEntity], isEnableColor: Bool, isInherit: Bool) {
        guard let handler = moveToActionHandler else { return }
        let moveToViewModel =
            MoveToActionSheetViewModelMessages(menuLabels: handler.getFolderMenuItems(),
                                               messages: messages,
                                               isEnableColor: isEnableColor,
                                               isInherit: isInherit)
        moveToActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     viewModel: moveToViewModel,
                     addNewFolder: { [weak self] in
                        self?.pendingActionAfterDismissal = { [weak self] in
                            self?.showMoveToActionSheet(messages: messages,
                                                        isEnableColor: isEnableColor,
                                                        isInherit: isInherit)
                        }
                        self?.presentCreateFolder(type: .folder)
                     },
                     selected: { menuLabel, isOn in
                        handler.updateSelectedMoveToDestination(menuLabel: menuLabel, isOn: isOn)
                     },
                     cancel: { [weak self] isHavingUnsavedChanges in
                        if isHavingUnsavedChanges {
                            self?.showDiscardAlert(handleDiscard: {
                                handler.updateSelectedMoveToDestination(menuLabel: nil, isOn: false)
                                self?.dismissActionSheet()
                            })
                        } else {
                            self?.dismissActionSheet()
                        }
                     },
                     done: { [weak self] isHavingUnsavedChanges in
                        defer {
                            self?.dismissActionSheet()
                            self?.cancelButtonTapped()
                        }
                        guard isHavingUnsavedChanges else {
                            return
                        }
                        handler.handleMoveToAction(messages: messages, isFromSwipeAction: false)
                     })
    }

    private var labelAsActionHandler: LabelAsActionSheetProtocol? {
        guard let searchVM = self.viewModel as? SearchViewModel else {
            return nil
        }
        return searchVM
    }

    private func showLabelAsActionSheet(messages: [MessageEntity]) {
        guard let handler = labelAsActionHandler else { return }
        let labelAsViewModel = LabelAsActionSheetViewModelMessages(menuLabels: handler.getLabelMenuItems(),
                                                                   messages: messages)

        labelAsActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     viewModel: labelAsViewModel,
                     addNewLabel: { [weak self] in
                        self?.pendingActionAfterDismissal = { [weak self] in
                            self?.showLabelAsActionSheet(messages: messages)
                        }
                        self?.presentCreateFolder(type: .label)
                     },
                     selected: { menuLabel, isOn in
                        handler.updateSelectedLabelAsDestination(menuLabel: menuLabel, isOn: isOn)
                     },
                     cancel: { [weak self] isHavingUnsavedChanges in
                        if isHavingUnsavedChanges {
                            self?.showDiscardAlert(handleDiscard: {
                                handler.updateSelectedLabelAsDestination(menuLabel: nil, isOn: false)
                                self?.dismissActionSheet()
                            })
                        } else {
                            self?.dismissActionSheet()
                        }
                     },
                     done: { [weak self] isArchive, currentOptionsStatus in
                        handler.handleLabelAsAction(messages: messages,
                                                    shouldArchive: isArchive,
                                                    currentOptionsStatus: currentOptionsStatus)
                        self?.dismissActionSheet()
                     })
    }

    private func presentCreateFolder(type: PMLabelType) {
        let folderLabels = viewModel.user.labelService.getMenuFolderLabels()
        let dependencies = LabelEditViewModel.Dependencies(userManager: viewModel.user)
        let labelEditNavigationController = LabelEditStackBuilder.make(
            editMode: .creation,
            type: type,
            labels: folderLabels,
            dependencies: dependencies,
            coordinatorDismissalObserver: self
        )
        self.navigationController?.present(labelEditNavigationController, animated: true, completion: nil)
    }
}

extension SearchViewController {
    private func updateTapped(status: Bool) {
        serialQueue.sync {
            self.messageTapped = status
        }
    }

    private func getTapped() -> Bool {
        serialQueue.sync {
            let ret = self.messageTapped
            if ret == false {
                self.messageTapped = true
            }
            return ret
        }
    }

    private func prepareForDraft(_ message: MessageEntity) {
        self.updateTapped(status: true)
        self.viewModel.fetchMessageDetail(message: message) { [weak self] error in
            self?.updateTapped(status: false)
            guard let self = self else { return }
            guard error == nil else {
                let alert = LocalString._unable_to_edit_offline.alertController()
                alert.addOKAction()
                self.present(alert, animated: true, completion: nil)
                self.tableView.indexPathsForSelectedRows?.forEach {
                    self.tableView.deselectRow(at: $0, animated: true)
                }
                return
            }
            self.showComposer(message: message)
        }
    }
    private func showComposer(message: MessageEntity) {
        guard let viewModel = self.viewModel.getComposeViewModel(message: message),
              let navigationController = self.navigationController else { return }
        let coordinator = ComposeContainerViewCoordinator(presentingViewController: navigationController,
                                                          editorViewModel: viewModel,
                                                          services: ServiceFactory.default)
        coordinator.start()
    }

    private func showComposer(msgID: MessageID) {
        guard let viewModel = self.viewModel.getComposeViewModel(by: msgID, isEditingScheduleMsg: true),
              let navigationController = self.navigationController else {
            return
        }
        let coordinator = ComposeContainerViewCoordinator(presentingViewController: navigationController,
                                                          editorViewModel: viewModel,
                                                          services: ServiceFactory.default)
        coordinator.start()
    }

    private func prepareFor(message: MessageEntity) {
        guard self.viewModel.viewMode == .singleMessage else {
            self.prepareConversationFor(message: message)
            return
        }
        if message.isDraft {
            self.prepareForDraft(message)
            return
        }
        self.updateTapped(status: false)
        guard let navigationController = navigationController else { return }
        let coordinator = SingleMessageCoordinator(
            navigationController: navigationController,
            labelId: "",
            message: message,
            user: self.viewModel.user
        )
        coordinator.goToDraft = { [weak self] msgID in
            guard let self = self else { return }
            // trigger the data to be updated.
            _ = self.textFieldShouldReturn(self.searchBar.textField)
            self.showComposer(msgID: msgID)
        }
        coordinator.start()
    }

    private func prepareConversationFor(message: MessageEntity) {
        guard let navigation = self.navigationController else {
            self.updateTapped(status: false)
            return
        }
        MBProgressHUD.showAdded(to: self.view, animated: true)
        let conversationID = message.conversationID
        let messageID = message.messageID
        self.viewModel.getConversation(conversationID: conversationID, messageID: messageID) { [weak self] result in
            guard let self = self else { return }

            self.updateTapped(status: false)
            MBProgressHUD.hide(for: self.view, animated: true)

            switch result {
            case .success(let conversation):
                let coordinator = ConversationCoordinator(
                    labelId: self.viewModel.labelID,
                    navigationController: navigation,
                    conversation: conversation,
                    user: self.viewModel.user,
                    internetStatusProvider: sharedServices.get(by: InternetConnectionStatusProvider.self),
                    targetID: messageID
                )
                coordinator.goToDraft = { [weak self] msgID in
                    guard let self = self else { return }
                    // trigger the data to be updated.
                    _ = self.textFieldShouldReturn(self.searchBar.textField)
                    self.showComposer(msgID: msgID)
                }
                coordinator.start()
            case .failure(let error):
                error.alert(at: nil)
            }
        }
    }

    private func showCheckOptions(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        let point: CGPoint = longPressGestureRecognizer.location(in: self.tableView)
        let indexPath: IndexPath? = self.tableView.indexPathForRow(at: point)
        guard let touchedRowIndexPath = indexPath,
              longPressGestureRecognizer.state == .began && listEditing == false else { return }
        enterListEditingMode(indexPath: touchedRowIndexPath)
    }

    private func hideCheckOptions() {
        guard listEditing else { return }
        self.listEditing = false
        self.tableView.reloadData()
    }

    private func enterListEditingMode(indexPath: IndexPath) {
        self.listEditing = true

        guard let visibleRowsIndexPaths = self.tableView.indexPathsForVisibleRows else { return }
        visibleRowsIndexPaths.forEach { visibleRowIndexPath in
            let visibleCell = self.tableView.cellForRow(at: visibleRowIndexPath)
            guard let messageCell = visibleCell as? NewMailboxMessageCell else { return }
            cellPresenter.presentSelectionStyle(style: .selection(isSelected: false), in: messageCell.customView)
            guard indexPath == visibleRowIndexPath else { return }
            tableView(tableView, didSelectRowAt: indexPath)
        }
    }

    private func handleEditingDataSelection(of id: String, indexPath: IndexPath) {
        let itemAlreadySelected = self.viewModel.isSelected(messageID: id)
        let selectionAction = itemAlreadySelected ? self.viewModel.removeSelected : self.viewModel.addSelected
        selectionAction(id)

        if self.viewModel.selectedIDs.isEmpty {
            self.hideActionBar()
        } else {
            self.refreshActionBarItems()
            self.showActionBar()
        }

        // update checkbox state
        if let mailboxCell = tableView.cellForRow(at: indexPath) as? NewMailboxMessageCell {
            cellPresenter.presentSelectionStyle(
                style: .selection(isSelected: !itemAlreadySelected),
                in: mailboxCell.customView
            )
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    private func cancelEditingMode() {
        self.viewModel.removeAllSelectedIDs()
        self.hideCheckOptions()
        self.hideActionBar()
        self.hideActionSheet()
    }
}

extension SearchViewController: SearchViewUIProtocol {
    func checkNoResultView() {
        if self.activityIndicator.isAnimating {
            self.noResultLabel.isHidden = true
            return
        }

        if UserInfo.isEncryptedSearchEnabledFreeUsers || UserInfo.isEncryptedSearchEnabledPaidUsers {
            if userCachedStatus.isEncryptedSearchOn {
                if let searchState = EncryptedSearchService.shared.searchState,
                    searchState.isComplete {
                    self.noResultLabel.isHidden = !self.viewModel.messages.isEmpty
                }
            }
        }
    }

    func activityIndicator(isAnimating: Bool) {
        isAnimating ? activityIndicator.startAnimating(): activityIndicator.stopAnimating()
        if isAnimating {
            self.noResultLabel.isHidden = true
        }
    }

    func reloadTable() {
        self.checkNoResultView()
        self.tableView.reloadData()
    }

    func showSlowSearchBanner() {
        DispatchQueue.main.async {
            let handleAttributedTextCallback: BannerView.tapAttributedTextActionBlock? = {
                // Dismiss banner
                self.slowSearchBanner?.remove(animated: true)
                // Clear existing search results
                self.viewModel.cleanExistingSearchResults()
                // Run search on server
                self.viewModel.fetchRemoteData(query: self.query, fromStart: true, forceSearchOnServer: true)
            }
            self.slowSearchBanner = BannerView(appearance: .esGray,
                                               message: LocalString._encrypted_search_banner_slow_search,
                                               buttons: nil,
                                               offset: 104.0,
                                               dismissDuration: Double.infinity,
                                               link: LocalString._encrypted_search_banner_slow_search_link,
                                               handleAttributedTextTap: handleAttributedTextCallback,
                                               dismissAction: nil)
            self.view.addSubview(self.slowSearchBanner!)
            self.slowSearchBanner!.drop(on: self.view, from: .top)
        }
    }
}

// MARK: - UITableView
extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.messages.isEmpty ? 0 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let mailboxCell = tableView.dequeueReusableCell(
                withIdentifier: NewMailboxMessageCell.defaultID(),
                for: indexPath
        ) as? NewMailboxMessageCell else {
            assert(false)
            return UITableViewCell()
        }

        guard !self.viewModel.messages.isEmpty else {
            return UITableViewCell()
        }

        let message = self.viewModel.messages[indexPath.row]
        let viewModel = self.viewModel.getMessageCellViewModel(message: message)
        cellPresenter.present(viewModel: viewModel, in: mailboxCell.customView)

        mailboxCell.id = message.messageID.rawValue
        mailboxCell.cellDelegate = self
        mailboxCell.generateCellAccessibilityIdentifiers(message.title)
        return mailboxCell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.zeroMargin()
        self.viewModel.loadMoreDataIfNeeded(currentRow: indexPath.row)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = self.viewModel.messages[indexPath.row]
        let breadcrumbMsg = "SearchVC selected message (msgId: \(message.messageID.rawValue), convId: \(message.conversationID.rawValue)"
        Breadcrumbs.shared.add(message: breadcrumbMsg, to: .malformedConversationRequest)
        guard !listEditing else {
            self.handleEditingDataSelection(of: message.messageID.rawValue,
                                            indexPath: indexPath)
            return
        }
        if self.getTapped() {
            // Fetching other draft data
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        self.prepareFor(message: message)
    }
}

extension SearchViewController: NewMailboxMessageCellDelegate {
    func didSelectButtonStatusChange(id: String?) {
        let tappedCell = tableView.visibleCells
            .compactMap { $0 as? NewMailboxMessageCell }
            .first(where: { $0.id == id })
        guard let cell = tappedCell, let indexPath = tableView.indexPath(for: cell) else { return }

        if !listEditing {
            self.enterListEditingMode(indexPath: indexPath)
        } else {
            tableView(self.tableView, didSelectRowAt: indexPath)
        }
    }

    func getExpirationDate(id: String) -> String? {
        // todo
        return nil
    }
}

// MARK: - UITextFieldDelegate

extension SearchViewController: UITextFieldDelegate {

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        query = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        searchBar.clearButton.isHidden = query.isEmpty == true
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.query = self.query.trim()
        textField.text = self.query
        guard !self.query.isEmpty else {
            return true
        }
        if UserInfo.isEncryptedSearchEnabledPaidUsers || UserInfo.isEncryptedSearchEnabledFreeUsers {
            // If Encrypted search is on, display a notification if the index is still being built
            if userCachedStatus.isEncryptedSearchOn {
                let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
                if let userID = usersManager.firstUser?.userInfo.userId {
                    let expectedESStates: [EncryptedSearchService.EncryptedSearchIndexState] =
                    [.downloading, .paused, .refresh, .lowstorage, .partial]
                    if expectedESStates.contains(EncryptedSearchService.shared.getESState(userID: userID)) {
                        self.enableSearchInfoBanner = true
                        self.showSearchInfoBanner()    // display only when ES is on
                        if self.hasTableBeenShiftedToDisplayBanner == false {
                            self.shiftTableDownToMakeSpaceForBanner()
                            self.hasTableBeenShiftedToDisplayBanner = true
                        }
                    }
                }
            }
        }
        self.viewModel.fetchRemoteData(query: self.query, fromStart: true, forceSearchOnServer: false)
        self.cancelEditingMode()
        return true
    }
}

extension SearchViewController: UndoActionHandlerBase {
    var delaySendSeconds: Int {
        self.viewModel.user.userInfo.delaySendSeconds
    }

    var composerPresentingVC: UIViewController? {
        navigationController
    }

    func showUndoAction(undoTokens: [String], title: String) { }
}
