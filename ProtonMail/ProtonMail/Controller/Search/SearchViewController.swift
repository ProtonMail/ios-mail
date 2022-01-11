//
//  SearchViewController.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
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

import UIKit
import CoreData
import MBProgressHUD
import ProtonCore_UIFoundations

protocol SearchViewUIProtocol: UIViewController {
    var listEditing: Bool { get }
    func update(progress: Float)
    func setupProgressBar(isHidden: Bool)
    func checkNoResultView()
    func activityIndicator(isAnimating: Bool)
    func reloadTable()
    func reloadRows(rows: [IndexPath])
    func showSlowSearchBanner()
}

class SearchViewController: ProtonMailViewController, ComposeSaveHintProtocol, CoordinatorDismissalObserver {
    
    @IBOutlet var navigationBarView: UIView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var noResultLabel: UILabel!
    private let searchBar = SearchBarView()
    private var searchInfoBanner: BannerView? = nil
    private var slowSearchBanner: BannerView? = nil
    private var searchInfoActivityIndicator: UIActivityIndicatorView? = nil
    private var actionBar: PMActionBar?
    private var actionSheet: PMActionSheet?
    // TODO: need better UI solution for this progress bar
    private lazy var progressBar: UIProgressView = {
        let bar = UIProgressView()
        bar.trackTintColor = .black
        bar.progressTintColor = .white
        bar.progressViewStyle = .bar
        
        let label = UILabel.init(font: UIFont.italicSystemFont(ofSize: UIFont.smallSystemFontSize), text: "Indexing local messages", textColor: .gray)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(label)
        bar.topAnchor.constraint(equalTo: label.topAnchor).isActive = true
        bar.leadingAnchor.constraint(equalTo: label.leadingAnchor).isActive = true
        bar.trailingAnchor.constraint(equalTo: label.trailingAnchor).isActive = true
        
        return bar
    }()

    // MARK: - Private Constants
    private let kAnimationDuration: TimeInterval = 0.3
    private let kLongPressDuration: CFTimeInterval    = 0.60 // seconds
    
    private let serialQueue = DispatchQueue(label: "com.protonamil.messageTapped")
    private var messageTapped = false
    private(set) var listEditing: Bool = false
    
    private(set) var viewModel: SearchVMProtocol!
    private var currentPage = 0
    private var query: String = ""
    private let mailListActionSheetPresenter = MailListActionSheetPresenter()
    private lazy var moveToActionSheetPresenter = MoveToActionSheetPresenter()
    private lazy var labelAsActionSheetPresenter = LabelAsActionSheetPresenter()
    private let cellPresenter = NewMailboxMessageCellPresenter()
    var pendingActionAfterDismissal: (() -> Void)?

    func set(viewModel: SearchVMProtocol) {
        self.viewModel = viewModel
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(self.viewModel != nil, "Please set view model")

        self.edgesForExtendedLayout = UIRectEdge()
        self.extendedLayoutIncludesOpaqueBars = false
        self.navigationController?.navigationBar.isTranslucent = false
        self.view.backgroundColor = ColorProvider.BackgroundNorm

        navigationBarView.backgroundColor = ColorProvider.BackgroundNorm

        self.setupSearchBar()
        self.setupTableview()
        self.setupProgressBar()
        self.setupActivityIndicator()
        self.viewModel.viewDidLoad()

        // show pop up to turn ES on
        if userCachedStatus.isEncryptedSearchOn == false {
            self.showPopUpToEnableEncryptedSearch()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchBar.textField.resignFirstResponder()
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
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
        //searchBar.textField.addTarget(self, action: #selector(), for: .editingChanged)
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
        let longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGestureRecognizer.minimumPressDuration = kLongPressDuration
        self.tableView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    private func setupProgressBar() {
        self.progressBar.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.progressBar)
        self.progressBar.topAnchor.constraint(equalTo: self.tableView.topAnchor).isActive = true
        self.progressBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.progressBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.progressBar.heightAnchor.constraint(equalToConstant: UIFont.smallSystemFontSize).isActive = true
    }
    
    private func setupActivityIndicator() {
        activityIndicator.color = ColorProvider.BrandNorm
        activityIndicator.isHidden = true
        activityIndicator.hidesWhenStopped = true
    }

    private func showPopUpToEnableEncryptedSearch() {
        // Gray out superview
        let grayView = UIView(frame: UIScreen.main.bounds)
        grayView.backgroundColor = ColorProvider.BlenderNorm
        self.view.addSubview(grayView)

        // hide keyboard when pop up is active
        self.searchBar.textField.resignFirstResponder()

        let image = UIImage(named: "es-icon")!
        let buttonAction: PopUpView.buttonActionBlock? = {
            let vm = SettingsEncryptedSearchViewModel(encryptedSearchCache: userCachedStatus)
            let vc = SettingsEncryptedSearchViewController()
            vc.set(viewModel: vm)
            //vc.set(coordinator: self.coordinator!)
            self.show(vc, sender: self)
        }
        let dismissAction: PopUpView.dismissActionBlock? = {
            // remove gray view
            grayView.removeFromSuperview()
            // show keyboard again
            self.searchBar.textField.becomeFirstResponder()
        }
        let popUp = PopUpView(title: LocalString._encrypted_search_popup_title, description: LocalString._encrypted_search_popup_description, image: image, titleOfButton: LocalString._encrypted_search_popup_button_title, buttonAction: buttonAction, dismissAction: dismissAction)
        self.view.addSubview(popUp)
        
        popUp.translatesAutoresizingMaskIntoConstraints = false
        popUp.layer.cornerRadius = 8
        NSLayoutConstraint.activate([
            popUp.topAnchor.constraint(equalTo: self.view.topAnchor, constant: self.view.bounds.height-376),
            popUp.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            popUp.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            popUp.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])

        popUp.popUp(on: self.view, from: .bottom)
    }
}

extension SearchViewController {
    internal func showSearchInfoBanner() {
        var text: String = ""
        var link: String = ""
        let state = EncryptedSearchService.shared.state
        switch state {
        case .downloading:
            text = LocalString._encrypted_search_info_search_downloading
            link = LocalString._encrypted_search_info_search_downloading_link
            break
        case .complete, .undetermined, .background, .backgroundStopped, .partial, .refresh, .paused, .lowstorage, .disabled:
            return
        }

        DispatchQueue.main.async {
            let dismissActionCallback: BannerView.dismissActionBlock? = {
                self.searchInfoActivityIndicator?.stopAnimating()
            }
            let handleAttributedTextCallback: BannerView.tapAttributedTextActionBlock? = {
                switch state {
                case .complete, .disabled, .undetermined, .lowstorage, .background, .backgroundStopped, .partial, .paused, .refresh:
                    break
                case .downloading:
                    let vm = SettingsEncryptedSearchViewModel(encryptedSearchCache: userCachedStatus)
                    let vc = SettingsEncryptedSearchViewController()
                    vc.set(viewModel: vm)
                    //vc.set(coordinator: self.coordinator!)    //TODO where to get the coordinator from?
                    self.show(vc, sender: self)
                    break
                }
            }
            self.searchInfoBanner = BannerView(appearance: .esGray, message: text, buttons: nil, offset: 104.0, dismissDuration: Double.infinity, link: link, handleAttributedTextTap: handleAttributedTextCallback, dismissAction: dismissActionCallback)
            self.view.addSubview(self.searchInfoBanner!)
            self.searchInfoBanner!.drop(on: self.view, from: .top)

            // Show spinner
            if #available(iOS 13.0, *) {
                self.searchInfoActivityIndicator = UIActivityIndicatorView(style: .medium)
            } else {
                self.searchInfoActivityIndicator = UIActivityIndicatorView(style: .white)
            }
            self.searchInfoActivityIndicator?.startAnimating()
            self.searchInfoActivityIndicator?.hidesWhenStopped = true
            self.searchInfoActivityIndicator?.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(self.searchInfoActivityIndicator!)
            NSLayoutConstraint.activate([
                self.searchInfoActivityIndicator!.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                self.searchInfoActivityIndicator!.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
            ])
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
// TODO: This is quite overlap what we did in MailboxVC, try to share the logic
extension SearchViewController {
    private func showActionBar() {
        guard self.actionBar == nil else { return }

        let actions = self.viewModel.getActionTypes()
        var actionItems: [PMActionBarItem] = []
        
        for (key, action) in actions.enumerated() {
            
            let actionHandler: (PMActionBarItem) -> Void = { [weak self] _ in
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
                    default:
                        self.viewModel.handleBarActions(action)
                        if action != .readUnread {
                            self.showMessageMoved(title: LocalString._messages_has_been_moved)
                        }
                        self.cancelButtonTapped()
                    }
                }
            }
            
            if key == actions.startIndex {
                let barItem = PMActionBarItem(icon: action.iconImage.withRenderingMode(.alwaysTemplate),
                                              text: action.name,
                                              itemColor: ColorProvider.FloatyText,
                                              handler: actionHandler)
                actionItems.append(barItem)
            } else {
                let barItem = PMActionBarItem(icon: action.iconImage.withRenderingMode(.alwaysTemplate),
                                              itemColor: ColorProvider.FloatyText,
                                              backgroundColor: .clear,
                                              handler: actionHandler)
                actionItems.append(barItem)
            }
        }
        let separator = PMActionBarItem(width: 1,
                                        verticalPadding: 6,
                                        color: ColorProvider.FloatyText)
        actionItems.insert(separator, at: 1)
        self.actionBar = PMActionBar(items: actionItems,
                                         backgroundColor: ColorProvider.FloatyBackground,
                                         floatingHeight: 42.0,
                                         width: .fit,
                                         height: 48.0)
        self.actionBar?.show(at: self)
    }
    
    private func hideActionBar() {
        self.actionBar?.dismiss()
        self.actionBar = nil
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
            cancelButtonTapped()
        case .delete:
            showDeleteAlert { [weak self] in
                guard let `self` = self else { return }
                self.viewModel.deleteSelectedMessage()
            }
        case .labelAs:
            labelButtonTapped()
        case .moveTo:
            folderButtonTapped()
        }
    }

    private func showNoEmailSelected(title: String) {
        let alert = UIAlertController(title: title, message: LocalString._message_list_no_email_selected, preferredStyle: .alert)
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
        let cancel = UIAlertAction(title: LocalString._general_cancel_button, style: .cancel) { [weak self] _ in
            self?.cancelButtonTapped()
        }
        [yes, cancel].forEach(alert.addAction)
        present(alert, animated: true, completion: nil)
    }

    private func showMessageMoved(title : String) {
        guard UIApplication.shared.applicationState == .active else {
            return
        }
        let banner = PMBanner(message: title, style: TempPMBannerNewStyle.info, dismissDuration: 3)
        banner.show(at: .bottom, on: self)
    }

    private var moveToActionHandler: MoveToActionSheetProtocol? {
        guard let searchVM = self.viewModel as? SearchViewModel else {
            return nil
        }
        return searchVM
    }
    
    private func showMoveToActionSheet(messages: [Message], isEnableColor: Bool, isInherit: Bool) {
        guard let handler = moveToActionHandler else { return }
        let moveToViewModel =
            MoveToActionSheetViewModelMessages(menuLabels: handler.getFolderMenuItems(),
                                               messages: messages,
                                               isEnableColor: isEnableColor,
                                               isInherit: isInherit,
                                               labelId: viewModel.labelID)
        moveToActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     viewModel: moveToViewModel,
                     addNewFolder: { [weak self] in
                        self?.pendingActionAfterDismissal = { [weak self] in
                            self?.showMoveToActionSheet(messages: messages, isEnableColor: isEnableColor, isInherit: isInherit)
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

    private func showLabelAsActionSheet(messages: [Message]) {
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
                        self?.cancelButtonTapped()
                     })
    }
    
    private func presentCreateFolder(type: PMLabelType) {
        let coreDataService = sharedServices.get(by: CoreDataService.self)
        let folderLabels = viewModel.user.labelService.getMenuFolderLabels(context: coreDataService.mainContext)
        let viewModel = LabelEditViewModel(user: viewModel.user, label: nil, type: type, labels: folderLabels)
        let viewController = LabelEditViewController.instance()
        let coordinator = LabelEditCoordinator(services: sharedServices,
                                               viewController: viewController,
                                               viewModel: viewModel,
                                               coordinatorDismissalObserver: self)
        coordinator.start()
        if let navigation = viewController.navigationController {
            self.navigationController?.present(navigation, animated: true, completion: nil)
        }
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
    
    private func prepareForDraft(_ message: Message) {
        self.updateTapped(status: true)
        self.viewModel.fetchMessageDetail(message: message) { [weak self] error in
            self?.updateTapped(status: false)
            guard let _self = self else { return }
            guard error == nil else {
                let alert = LocalString._unable_to_edit_offline.alertController()
                alert.addOKAction()
                _self.present(alert, animated: true, completion: nil)
                _self.tableView.indexPathsForSelectedRows?.forEach {
                    _self.tableView.deselectRow(at: $0, animated: true)
                }
                return
            }
            _self.showComposer(message: message)
        }
    }
    
    private func showComposer(message: Message) {
        let viewModel = self.viewModel.getComposeViewModel(message: message)
        guard let navigationController = self.navigationController else { return }
        let composerVM = ComposeContainerViewModel(editorViewModel: viewModel,
                                                   uiDelegate: nil)
        let coordinator = ComposeContainerViewCoordinator(nav: navigationController,
                                                          viewModel: composerVM,
                                                          services: ServiceFactory.default)
        coordinator.start()
    }

    private func prepareFor(message: Message) {
        guard self.viewModel.viewMode == .singleMessage else {
            self.prepareConversationFor(message: message)
            return
        }
        if message.draft {
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
        coordinator.start()
    }

    private func prepareConversationFor(message: Message) {
        guard let navigation = self.navigationController else {
            self.updateTapped(status: false)
            return
        }
        MBProgressHUD.showAdded(to: self.view, animated: true)
        let conversationID = message.conversationID
        let messageID = message.messageID
        self.viewModel.getConversation(conversationID: conversationID, messageID: messageID).done { [weak self] conversation in
            guard let self = self else { return }
            let coordinator = ConversationCoordinator(
                labelId: self.viewModel.labelID,
                navigationController: navigation,
                conversation: conversation,
                user: self.viewModel.user,
                targetID: messageID
            )
            coordinator.start()
        }.catch { error in
            error.alert(at: nil)
        }.finally { [weak self] in
            guard let self = self else { return }
            self.updateTapped(status: false)
            MBProgressHUD.hide(for: self.view, animated: true)
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
    func update(progress: Float) {
        self.progressBar.setProgress(progress, animated: true)
    }

    func setupProgressBar(isHidden: Bool) {
        self.progressBar.isHidden = isHidden
    }

    func checkNoResultView() {
        if self.activityIndicator.isAnimating {
            self.noResultLabel.isHidden = true
            return
        }
        self.noResultLabel.isHidden = !self.viewModel.messages.isEmpty
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

    func reloadRows(rows: [IndexPath]) {
        self.tableView.beginUpdates()
        self.tableView.reloadRows(at: rows, with: .automatic)
        self.tableView.endUpdates()
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
            self.slowSearchBanner = BannerView(appearance: .esGray, message: LocalString._encrypted_search_banner_slow_search, buttons: nil, offset: 104.0, dismissDuration: Double.infinity, link: LocalString._encrypted_search_banner_slow_search_link, handleAttributedTextTap: handleAttributedTextCallback, dismissAction: nil)
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

        let message = self.viewModel.messages[indexPath.row]
        let viewModel = self.viewModel.getMessageCellViewModel(message: message)
        cellPresenter.present(viewModel: viewModel, in: mailboxCell.customView)

        mailboxCell.id = message.messageID
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
        guard !listEditing else {
            self.handleEditingDataSelection(of: message.messageID,
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

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        query = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        searchBar.clearButton.isHidden = query.isEmpty == true
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.query = self.query.trim()
        textField.text = self.query
        guard self.query.count > 0 else {
            return true
        }
        // If Encrypted search is on, display a notification if the index is still being built
        if userCachedStatus.isEncryptedSearchOn {
            self.showSearchInfoBanner()    // display only when ES is on
        }
        self.viewModel.fetchRemoteData(query: self.query, fromStart: true, forceSearchOnServer: false)
        self.cancelEditingMode()
        return true
    }
}
