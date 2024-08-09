//
//  ContactGroupViewController.swift
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
import LifetimeTracker
import MBProgressHUD
import PromiseKit
import ProtonCoreUIFoundations
import StoreKit
import UIKit

protocol ContactGroupsUIProtocol: UIViewController {
    func reloadTable()
}

/**
 When the core data that provides data to this controller has data changes,
 the update will be performed immediately and automatically by core data
 */
final class ContactGroupsViewController: ContactsAndGroupsSharedCode, ComposeSaveHintProtocol, LifetimeTrackable {
    typealias Dependencies = HasComposerViewFactory
    & HasContactViewsFactory
    & HasCoreDataContextProviderProtocol
    & ContactsAndGroupsSharedCode.Dependencies
    & HasUserManager

    class var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }

    private let viewModel: ContactGroupsViewModel
    private let dependencies: Dependencies
    private var queryString = ""

    // long press related vars
    private var isEditingState: Bool = false
    private let kLongPressDuration: CFTimeInterval = 0.60 // seconds
    private var trashcanBarButtonItem: UIBarButtonItem?
    private var cancelBarButtonItem: UIBarButtonItem?
    private var totalSelectedContactGroups: Int = 0 {
        didSet {
            if isEditingState {
                title = String(format: LocalString._selected_navogationTitle, totalSelectedContactGroups)
            }
        }
    }

    private let kContactGroupCellIdentifier = "ContactGroupsViewCell"

    private var refreshControl: UIRefreshControl?
    private var searchController: UISearchController?
    private let internetConnectionStatusProvider = InternetConnectionStatusProvider.shared

    @IBOutlet private var tableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var searchView: UIView!
    @IBOutlet private var searchViewConstraint: NSLayoutConstraint!
    @IBOutlet var tableView: UITableView!

    init(viewModel: ContactGroupsViewModel, dependencies: Dependencies) {
        self.viewModel = viewModel
        self.dependencies = dependencies
        super.init(dependencies: dependencies, nibName: "ContactGroupsViewController")
        trackLifetime()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        definesPresentationContext = true
        extendedLayoutIncludesOpaqueBars = true

        prepareTable()
        prepareSearchBar()
        viewModel.set(uiDelegate: self)
        viewModel.setupDataSource()

        generateAccessibilityIdentifiers()

        emptyBackButtonTitleForNextView()
        view.backgroundColor = ColorProvider.BackgroundNorm
        tableView.backgroundColor = ColorProvider.BackgroundNorm

        setupMenuButton(userInfo: dependencies.user.userInfo)

        if self.viewModel.initEditing() {
            isEditingState = true
            tableView.allowsMultipleSelection = true
            prepareNavigationItemTitle()
            navigationItem.leftBarButtonItem = navigationItem.backBarButtonItem
        } else {
            prepareRefreshController()
            prepareLongPressGesture()
            prepareNavigationItemRightDefault()
            updateNavigationBar()
        }

        navigationItem.assignNavItemIndentifiers()
        generateAccessibilityIdentifiers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.timerStart(true)
        self.isOnMainView = true
        self.viewModel.user.undoActionManager.register(handler: self)

        if !viewModel.initEditing() {
            setupMenuButton(userInfo: dependencies.user.userInfo)
        }

        NotificationCenter.default.addKeyboardObserver(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.timerStop()
        viewModel.save()
        NotificationCenter.default.removeKeyboardObserver(self)
    }

    private func prepareRefreshController() {
        let refreshControl = UIRefreshControl()
        self.refreshControl = refreshControl
        self.refreshControl?.backgroundColor = ColorProvider.BackgroundNorm
        self.refreshControl?.addTarget(self,
                                 action: #selector(fireFetch),
                                 for: UIControl.Event.valueChanged)
        tableView.addSubview(refreshControl)
        self.refreshControl?.tintColor = ColorProvider.InteractionNorm
        self.refreshControl?.tintColorDidChange()
    }

    private func prepareTable() {
        tableView.register(UINib(nibName: "ContactGroupsViewCell", bundle: Bundle.main),
                           forCellReuseIdentifier: kContactGroupCellIdentifier)

        tableView.noSeparatorsBelowFooter()
        tableView.estimatedRowHeight = 60.0
        tableView.rowHeight = UITableView.automaticDimension
    }

    private func prepareLongPressGesture() {
        totalSelectedContactGroups = 0

        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGestureRecognizer.minimumPressDuration = kLongPressDuration
        tableView.addGestureRecognizer(longPressGestureRecognizer)
    }

    @objc private func handleLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        // blocks contact group view from editing
        if viewModel.user.hasPaidMailPlan == false {
            presentPlanUpgrade()
            return
        }

        // mark the location that it is on
        markLongPressLocation(longPressGestureRecognizer)
    }

    private func markLongPressLocation(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        let pressingLocation = longPressGestureRecognizer.location(in: tableView)
        let pressedIndexPath = tableView.indexPathForRow(at: pressingLocation)

        if let pressedIndexPath = pressedIndexPath {
            if longPressGestureRecognizer.state == UIGestureRecognizer.State.began {
                // set state
                isEditingState = true
                tableView.allowsMultipleSelection = true

                // prepare the navigationItems
                updateNavigationBar()

                // set cell
                if let visibleIndexPaths = tableView.indexPathsForVisibleRows {
                    for visibleIndexPath in visibleIndexPaths {
                        if visibleIndexPath == pressedIndexPath {
                            // mark this indexPath as selected
                            if let cell = tableView.cellForRow(at: visibleIndexPath) as? ContactGroupsViewCell {
                                selectRow(at: visibleIndexPath, groupID: cell.getLabelID())
                            }
                        }
                    }
                }
            }
        }
    }

    private func updateNavigationBar() {
        prepareNavigationItemLeft()
        prepareNavigationItemTitle()
        prepareNavigationItemRight()
    }

    private func prepareNavigationItemLeft() {
        if isEditingState {
            // make cancel button and selector
            if cancelBarButtonItem == nil {
                cancelBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                      target: self,
                                                      action: #selector(cancelBarButtonTapped))
            }

            navigationItem.leftBarButtonItems = [cancelBarButtonItem!]
        } else {
            // restore the left bar
            navigationItem.leftBarButtonItems = navigationItemLeftNotEditing
        }
    }

    // end long press event
    @objc private func cancelBarButtonTapped() {
        // reset state
        isEditingState = false
        tableView.allowsMultipleSelection = false

        // reset navigation bar
        updateNavigationBar()

        // unselect all
        totalSelectedContactGroups = 0
        viewModel.removeAllSelectedGroups()
        if let selectedIndexPaths = tableView.indexPathsForSelectedRows {
            for selectedIndexPath in selectedIndexPaths {
                tableView.deselectRow(at: selectedIndexPath,
                                      animated: true)
            }
        }
    }

    private func prepareNavigationItemTitle() {
        if isEditingState {
            title = String(format: LocalString._selected_navogationTitle, 0)
        } else {
            title = LocalString._menu_contact_group_title
        }
    }

    private func prepareNavigationItemRight() {
        if isEditingState {
            // make trash can and selector
            if trashcanBarButtonItem == nil {
                trashcanBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash,
                                                        target: self,
                                                        action: #selector(trashcanBarButtonTapped))
            }

            navigationItem.rightBarButtonItems = [trashcanBarButtonItem!]
        } else {
            // restore the right bar
            navigationItem.rightBarButtonItems = navigationItemRightNotEditing
        }
    }

    private func resetStateFromMultiSelect() {
        // reset state
        isEditingState = false
        tableView.allowsMultipleSelection = false
        totalSelectedContactGroups = 0

        // reset navigation bar
        updateNavigationBar()
    }

    @objc private func trashcanBarButtonTapped() {
        let deleteHandler = {
            (_: UIAlertAction) -> Void in
                firstly {
                    () -> Promise<Void> in
                        // attempt to delete selected groups
                        MBProgressHUD.showAdded(to: self.view, animated: true)
                        return self.viewModel.deleteGroups()
                }.done { [weak self] in
                    self?.resetStateFromMultiSelect()
                    let isOnline = self?.isOnline ?? true
                    if !isOnline {
                        LocalString._contacts_saved_offline_hint.alertToastBottom()
                    }
                }.ensure {
                    MBProgressHUD.hide(for: self.view, animated: true)
                }.catch {
                    error in
                    error.alert(at: self.view)
                }
        }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button,
                                                style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: LocalString._contact_groups_delete,
                                                style: .destructive,
                                                handler: deleteHandler))

        alertController.popoverPresentationController?.barButtonItem = trashcanBarButtonItem
        present(alertController, animated: true, completion: nil)
    }

    private func prepareSearchBar() {
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchBar.placeholder = LocalString._general_search_placeholder

        searchController?.searchResultsUpdater = self
        searchController?.obscuresBackgroundDuringPresentation = false
        searchController?.searchBar.delegate = self
        searchController?.hidesNavigationBarDuringPresentation = true
        searchController?.searchBar.sizeToFit()
        searchController?.searchBar.keyboardType = .default
        searchController?.searchBar.autocapitalizationType = .none
        searchController?.searchBar.isTranslucent = false
        searchController?.searchBar.tintColor = ColorProvider.TextNorm
        searchController?.searchBar.barTintColor = ColorProvider.TextHint
        searchController?.searchBar.backgroundColor = ColorProvider.BackgroundNorm

        searchViewConstraint.constant = 0.0
        searchView.isHidden = true
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = searchController
    }

    @objc func fireFetch() {
        guard internetConnectionStatusProvider.status.isConnected else {
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
            }
            return
        }
        self.viewModel.fetchLatestContactGroup { [weak self] error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    error.alert(at: self.view)
                } else {
                    self.refreshControl?.endRefreshing()
                }
            }
        }
    }

    override func addContactGroupTapped() {
        if viewModel.user.hasPaidMailPlan {
            let newView = dependencies.contactViewsFactory.makeGroupEditView(
                state: .create,
                groupID: nil,
                name: nil,
                color: nil,
                emailIDs: []
            )
            let nav = UINavigationController(rootViewController: newView)
            present(nav, animated: true, completion: nil)
        } else {
            presentPlanUpgrade()
        }
    }

    override func showContactImportView() {
        isOnMainView = true

        let newView = dependencies.contactViewsFactory.makeImportView()
        setPresentationStyleForSelfController(presentingController: newView, style: .overFullScreen)
        newView.reloadAllContact = { [weak self] in
            self?.tableView.reloadData()
        }
        present(newView, animated: false, completion: nil)
    }

    override func addContactTapped() {
        let newView = dependencies.contactViewsFactory.makeEditView(contact: nil)
        let nav = UINavigationController(rootViewController: newView)
        present(nav, animated: true)

            // detect view dismiss above iOS 13
            nav.children[0].presentationController?.delegate = self
            nav.presentationController?.delegate = self
    }

    func selectRow(at indexPath: IndexPath, groupID: String) {
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        viewModel.addSelectedGroup(ID: groupID)
        totalSelectedContactGroups = viewModel.getSelectedCount()
    }

    func deselectRow(at indexPath: IndexPath, groupID: String) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.removeSelectedGroup(ID: groupID)
        totalSelectedContactGroups = viewModel.getSelectedCount()
    }
}

extension ContactGroupsViewController: UISearchBarDelegate, UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.search(text: searchController.searchBar.text, searchActive: searchController.isActive)
        queryString = searchController.searchBar.text ?? ""
        tableView.reloadData()
    }
}

extension ContactGroupsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.count()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: kContactGroupCellIdentifier, for: indexPath)
        if let cell = cell as? ContactGroupsViewCell {
            let data = viewModel.dateForRow(at: indexPath)
            cell.config(labelID: data.ID,
                        name: data.name,
                        queryString: queryString,
                        count: data.count,
                        color: data.color,
                        showSendEmailIcon: data.showEmailIcon,
                        delegate: self)
            if viewModel.isSelected(groupID: data.ID) {
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? ContactGroupsViewCell else {
            return
        }
        if viewModel.initEditing() {
            if viewModel.isSelected(groupID: cell.getLabelID()) {
                selectRow(at: indexPath, groupID: cell.getLabelID())
            }
        }
    }
}

extension ContactGroupsViewController: ContactGroupsViewCellDelegate {
    func isMultiSelect() -> Bool {
        return isEditingState || viewModel.initEditing()
    }

    func sendEmailToGroup(ID: String, name: String) {
        guard viewModel.user.hasPaidMailPlan else {
            presentPlanUpgrade()
            return
        }
        guard !viewModel.user.isStorageExceeded else {
            LocalString._storage_exceeded.alertToastBottom()
            return
        }

        let contactGroupVO = ContactGroupVO.init(ID: ID, name: name, contextProvider: dependencies.contextProvider)
        contactGroupVO.selectAllEmailFromGroup()
        let composer = dependencies.composerViewFactory.makeComposer(
            msg: nil,
            action: .newDraft,
            isEditingScheduleMsg: false,
            toContact: contactGroupVO
        )

        self.present(composer, animated: true)
    }
}

extension ContactGroupsViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        resetStateFromMultiSelect()

        let deleteHandler: UIContextualAction.Handler = { _, _, completion in
                let deleteActionHandler = {
                    (_: UIAlertAction) -> Void in

                        firstly {
                            () -> Promise<Void> in
                                // attempt to delete selected groups
                                MBProgressHUD.showAdded(to: self.view, animated: true)
                                if let cell = self.tableView.cellForRow(at: indexPath) as? ContactGroupsViewCell {
                                    self.viewModel.addSelectedGroup(ID: cell.getLabelID())
                                }
                                return self.viewModel.deleteGroups()
                        }.ensure {
                            MBProgressHUD.hide(for: self.view, animated: true)
                        }.catch {
                            error in
                            error.alert(at: self.view)
                        }
                }

                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button,
                                                        style: .cancel,
                                                        handler: nil))
                alertController.addAction(UIAlertAction(title: LocalString._contact_groups_delete,
                                                        style: .destructive,
                                                        handler: deleteActionHandler))

                alertController.popoverPresentationController?.sourceView = self.tableView
                alertController.popoverPresentationController?.sourceRect = CGRect(x: self.tableView.bounds.midX, y: self.tableView.bounds.maxY - 100, width: 0, height: 0)

                self.present(alertController, animated: true, completion: nil)
            completion(false)
        }

        let deleteAction = UIContextualAction(
            style: .destructive,
            title: LocalString._general_delete_action,
            handler: deleteHandler
        )
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isEditingState {
            // blocks contact email cell contact group editing
            if viewModel.user.hasPaidMailPlan == false {
                tableView.deselectRow(at: indexPath, animated: true)
                presentPlanUpgrade()
                return
            }
            if let cell = tableView.cellForRow(at: indexPath) as? ContactGroupsViewCell {
                selectRow(at: indexPath, groupID: cell.getLabelID())
                if viewModel.initEditing() {
                    cell.setCount(viewModel.dateForRow(at: indexPath).count)
                }
            }
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            if let label = viewModel.labelForRow(at: indexPath) {
                presentContactGroupDetailView(label: label)
            }
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isEditingState {
            // blocks contact email cell contact group editing
            if viewModel.user.hasPaidMailPlan == false {
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                presentPlanUpgrade()
                return
            }

            if let cell = tableView.cellForRow(at: indexPath) as? ContactGroupsViewCell {
                deselectRow(at: indexPath, groupID: cell.getLabelID())
                if viewModel.initEditing() {
                    cell.setCount(viewModel.dateForRow(at: indexPath).count)
                }
            }
        }
    }

    private func presentContactGroupDetailView(label: LabelEntity) {
        let newView = dependencies.contactViewsFactory.makeGroupDetailView(label: label)
        show(newView, sender: nil)
        isOnMainView = false
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol

extension ContactGroupsViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        tableViewBottomConstraint.constant = 0
        let keyboardInfo = notification.keyboardInfo
        UIView.animate(withDuration: keyboardInfo.duration,
                       delay: 0,
                       options: keyboardInfo.animationOption,
                       animations: { () in
                           self.view.layoutIfNeeded()
                       }, completion: nil)
    }

    func keyboardWillShowNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        let info: NSDictionary = notification.userInfo! as NSDictionary
        if let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            tableViewBottomConstraint.constant = keyboardSize.height

            UIView.animate(withDuration: keyboardInfo.duration,
                           delay: 0,
                           options: keyboardInfo.animationOption,
                           animations: { () in
                               self.view.layoutIfNeeded()
                           }, completion: nil)
        }
    }
}

extension ContactGroupsViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        isOnMainView = true
    }
}

extension ContactGroupsViewController: ContactGroupsUIProtocol {
    func reloadTable() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
}

extension ContactGroupsViewController: UndoActionHandlerBase {
    var undoActionManager: UndoActionManagerProtocol? {
        nil
    }

    var delaySendSeconds: Int {
        self.viewModel.user.userInfo.delaySendSeconds
    }

    var composerPresentingVC: UIViewController? {
        self
    }

    func showUndoAction(undoTokens: [String], title: String) { }
}
