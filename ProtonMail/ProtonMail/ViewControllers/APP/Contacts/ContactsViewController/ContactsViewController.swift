//
//  ContactsViewController.swift
//  Proton Mail - Created on 3/6/17.
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

import Contacts
import CoreData
import MBProgressHUD
import ProtonCore_UIFoundations
import UIKit

protocol ContactsVCUIProtocol: AnyObject {
    func reloadTable()
}

final class ContactsViewController: ContactsAndGroupsSharedCode {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var tableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var searchView: UIView!
    @IBOutlet var searchViewConstraint: NSLayoutConstraint!

    private let viewModel: ContactsViewModel
    private var searchString: String = ""
    private var refreshControl: UIRefreshControl?
    private var searchController: UISearchController?
    private let internetConnectionStatusProvider = InternetConnectionStatusProvider()

    deinit {
        self.viewModel.resetFetchedController()
    }

    init(viewModel: ContactsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "ContactsViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ColorProvider.BackgroundNorm

        self.tableView.register(ContactsTableViewCell.nib,
                                forCellReuseIdentifier: ContactsTableViewCell.cellID)
        let refreshControl = UIRefreshControl()
        self.refreshControl = refreshControl
        self.refreshControl?.addTarget(self,
                                      action: #selector(self.fireFetch),
                                      for: UIControl.Event.valueChanged)

        self.tableView.estimatedRowHeight = 60.0
        self.tableView.addSubview(refreshControl)
        self.tableView.dataSource = self
        self.tableView.delegate = self

        self.refreshControl?.tintColor = ColorProvider.BrandNorm
        self.refreshControl?.tintColorDidChange()

        self.navigationController?.navigationBar.prefersLargeTitles = false
        self.definesPresentationContext = true
        self.extendedLayoutIncludesOpaqueBars = true
        self.tableView.noSeparatorsBelowFooter()
        self.tableView.sectionIndexColor = ColorProvider.BrandNorm
        self.tableView.backgroundColor = ColorProvider.BackgroundNorm
        
        //get all contacts
        self.viewModel.setupFetchedResults()
        self.viewModel.setup(uiDelegate: self)
        self.prepareSearchBar()

        emptyBackButtonTitleForNextView()

        let menuButton = UIBarButtonItem(
            image: Asset.topMenu.image,
            style: .plain,
            target: self,
            action: #selector(self.openMenu)
        )
        menuButton.accessibilityLabel = LocalString._menu_button
        //Self.setup(self, menuButton, shouldShowSideMenu())
        navigationItem.leftBarButtonItem = menuButton
        menuButton.action = #selector(self.openMenu)

        prepareNavigationItemRightDefault(self.viewModel.user)
        
        generateAccessibilityIdentifiers()
        navigationItem.assignNavItemIndentifiers()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.setEditing(false, animated: true)
        self.title = LocalString._contacts_title

        self.tableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.setupTimer(true)
        NotificationCenter.default.addKeyboardObserver(self)

        self.isOnMainView = true

        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .layoutChanged,
                                 argument: self.navigationController?.view)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.viewModel.stopTimer()
        NotificationCenter.default.removeKeyboardObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    // run once
    private func prepareSearchBar() {
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController?.searchBar.placeholder = LocalString._general_search_placeholder

        if #available(iOS 13.0, *) {
            // Terminating app due to uncaught exception 'NSGenericException', reason: 'Access to UISearchBar's set_cancelButtonText: ivar is prohibited. This is an application bug'
        } else {
            self.searchController?.searchBar.setValue(LocalString._general_done_button,
                                                     forKey: "_cancelButtonText")
        }

        self.searchController?.searchResultsUpdater = self
        self.searchController?.dimsBackgroundDuringPresentation = false
        self.searchController?.searchBar.delegate = self
        self.searchController?.hidesNavigationBarDuringPresentation = true
        self.searchController?.searchBar.sizeToFit()
        self.searchController?.searchBar.keyboardType = .default
        self.searchController?.searchBar.keyboardAppearance = .light
        self.searchController?.searchBar.autocapitalizationType = .none
        self.searchController?.searchBar.isTranslucent = false
        self.searchController?.searchBar.tintColor = ColorProvider.TextNorm
        self.searchController?.searchBar.barTintColor = ColorProvider.BackgroundNorm
        self.searchController?.searchBar.backgroundColor = .clear

        self.searchViewConstraint.constant = 0.0
        self.searchView.isHidden = true
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.hidesSearchBarWhenScrolling = false
        self.navigationItem.searchController = self.searchController
        self.navigationItem.assignNavItemIndentifiers()
    }

    override func addContactGroupTapped() {
        if self.viewModel.user.hasPaidMailPlan {
            let viewModel = ContactGroupEditViewModelImpl(state: .create,
                                                          user: viewModel.user,
                                                          groupID: nil,
                                                          name: nil,
                                                          color: nil,
                                                          emailIDs: Set<EmailEntity>())
            let newView = ContactGroupEditViewController(viewModel: viewModel)
            let nav = UINavigationController(rootViewController: newView)
            self.present(nav, animated: true, completion: nil)
        } else {
            presentPlanUpgrade()
        }
    }

    override func showContactImportView() {
        self.isOnMainView = true

        let newView = ContactImportViewController(user: viewModel.user)
        self.setPresentationStyleForSelfController(self,
                                                   presentingController: newView,
                                                   style: .overFullScreen)
        newView.reloadAllContact = { [weak self] in
            self?.tableView.reloadData()
        }
        self.present(newView, animated: false, completion: nil)
    }

    private func showContactDetailView(contact: ContactEntity) {
        let viewModel = ContactDetailsViewModelImpl(contact: contact,
                                                    user: viewModel.user,
                                                    coreDateService: viewModel.coreDataService)
        let newView = ContactDetailViewController(viewModel: viewModel)
        self.show(newView, sender: nil)
        isOnMainView = false

        if #available(iOS 13, *) { // detect view dismiss above iOS 13
            if let nav = self.navigationController {
                nav.children[0].presentationController?.delegate = self
            }
            newView.presentationController?.delegate = self
        }
    }

    override func addContactTapped() {
        let viewModel = ContactAddViewModelImpl(user: viewModel.user,
                                                coreDataService: viewModel.coreDataService)
        let newView = ContactEditViewController(viewModel: viewModel)
        let nav = UINavigationController(rootViewController: newView)
        self.present(nav, animated: true)

        if #available(iOS 13, *) { // detect view dismiss above iOS 13
            nav.children[0].presentationController?.delegate = self
            nav.presentationController?.delegate = self
        }
    }

    @objc internal func fireFetch() {
        self.internetConnectionStatusProvider.registerConnectionStatus { [weak self] status in
            guard status.isConnected else {
                DispatchQueue.main.async {
                    self?.refreshControl?.endRefreshing()
                }
                return
            }

            self?.viewModel.fetchContacts { (_: [Contact]?, error: NSError?) in
                if let error = error as NSError? {
                    let alertController = error.alertController()
                    alertController.addOKAction()
                    self?.present(alertController, animated: true, completion: nil)
                }
                self?.refreshControl?.endRefreshing()
            }
        }
    }
}

// Search part
extension ContactsViewController: UISearchBarDelegate, UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        self.searchString = searchController.searchBar.text ?? ""
        self.viewModel.search(text: self.searchString)
        self.tableView.reloadData()
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.refreshControl?.endRefreshing()
        self.refreshControl?.removeFromSuperview()
        self.viewModel.set(searching: true)
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if let refreshControl = self.refreshControl {
            self.tableView.addSubview(refreshControl)
        }
        self.viewModel.set(searching: false)
    }
}

// MARK: - UITableViewDataSource

extension ContactsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.sectionCount()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.rowCount(section: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ContactsTableViewCell.cellID,
                                                 for: indexPath)
        if let contactCell = cell as? ContactsTableViewCell {
            if let contact = self.viewModel.item(index: indexPath) {
                contactCell.config(name: contact.name,
                                   email: contact.displayEmails,
                                   highlight: self.searchString)
            }
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ContactsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {}

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteClosure = { (_: UITableViewRowAction!, indexPath: IndexPath!) in
            if let contact = self.viewModel.item(index: indexPath) {
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
                alertController.addAction(UIAlertAction(title: LocalString._delete_contact,
                                                        style: .destructive, handler: { _ in
                                                            MBProgressHUD.showAdded(to: self.view, animated: true)
                                                            self.viewModel.delete(contactID: contact.contactID, complete: { error in
                                                                MBProgressHUD.hide(for: self.view, animated: true)
                                                                if let err = error {
                                                                    err.alert(at: self.view)
                                                                }
                                                            })
                                                        }))

                alertController.popoverPresentationController?.sourceView = self.tableView
                alertController.popoverPresentationController?.sourceRect = CGRect(x: self.tableView.bounds.midX, y: self.tableView.bounds.maxY - 100, width: 0, height: 0)
                alertController.assignActionsAccessibilityIdentifiers()

                self.present(alertController, animated: true, completion: nil)
            }
        }

        let deleteAction = UITableViewRowAction(style: .default,
                                                title: LocalString._general_delete_action,
                                                handler: deleteClosure)
        return [deleteAction]
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let contact = self.viewModel.item(index: indexPath) {
            self.showContactDetailView(contact: contact)
        }
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return self.viewModel.sectionForSectionIndexTitle(title: title, atIndex: index)
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return self.viewModel.sectionIndexTitle()
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol

extension ContactsViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        self.tableViewBottomConstraint.constant = 0
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
            self.tableViewBottomConstraint.constant = keyboardSize.height

            UIView.animate(withDuration: keyboardInfo.duration,
                           delay: 0,
                           options: keyboardInfo.animationOption,
                           animations: { () in
                               self.view.layoutIfNeeded()
                           }, completion: nil)
        }
    }
}

// detect view dismiss above iOS 13
@available(iOS 13, *)
extension ContactsViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        self.isOnMainView = true
    }
}

extension ContactsViewController: ContactsVCUIProtocol {
    func reloadTable() {
        self.tableView.reloadData()
    }
}
