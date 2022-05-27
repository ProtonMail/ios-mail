//
//  ContactGroupSelectEmailViewController.swift
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

import ProtonCore_UIFoundations
import UIKit

class ContactGroupSelectEmailViewController: UIViewController {
    private let viewModel: ContactGroupSelectEmailViewModel

    @IBOutlet private var tableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var searchView: UIView!
    @IBOutlet private var searchViewHeightConstraint: NSLayoutConstraint!
    private var doneButton: UIBarButtonItem!
    private var cancelButton: UIBarButtonItem!

    private var queryString = ""
    private var searchController: UISearchController!

    let kContactGroupEditCellIdentifier = "ContactGroupEditCell"

    init(viewModel: ContactGroupSelectEmailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorProvider.BackgroundNorm
        self.definesPresentationContext = true
        title = LocalString._contact_groups_add_contacts

        self.tableView.allowsMultipleSelection = true
        self.tableView.register(UINib(nibName: "ContactGroupEditViewCell", bundle: Bundle.main),
                                forCellReuseIdentifier: self.kContactGroupEditCellIdentifier)
        self.prepareSearchBar()

        self.doneButton = UIBarButtonItem(title: LocalString._general_done_button,
                                          style: UIBarButtonItem.Style.plain,
                                          target: self, action: #selector(self.didTapDoneButton))
        let attributes = FontManager.DefaultStrong.foregroundColor(ColorProvider.InteractionNorm)
        self.doneButton.setTitleTextAttributes(attributes, for: .normal)
        self.navigationItem.rightBarButtonItem = self.doneButton

        self.navigationItem.leftBarButtonItem = UIBarButtonItem.backBarButtonItem(target: self, action: #selector(self.didTapCancelButton(_:)))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // if the user is tricky enough the hold the view using the edge geatures
        // we will need to turn this off temporarily
        self.extendedLayoutIncludesOpaqueBars = false
        NotificationCenter.default.addKeyboardObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // set this after the layout is completed
        // so when the view disappeared, the search bar view won't leave a
        // black block underneath it
        self.extendedLayoutIncludesOpaqueBars = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeKeyboardObserver(self)
    }

    func inactiveViewModel() {}

    private func prepareSearchBar() {
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController.searchBar.placeholder = LocalString._general_search_placeholder

        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchBar.delegate = self
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.searchBar.sizeToFit()
        self.searchController.searchBar.keyboardType = .default
        self.searchController.searchBar.autocapitalizationType = .none
        self.searchController.searchBar.isTranslucent = false
        self.searchController.searchBar.tintColor = .white
        self.searchController.searchBar.backgroundColor = ColorProvider.BackgroundNorm

        self.searchViewHeightConstraint.constant = 0.0
        self.searchView.isHidden = true
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.hidesSearchBarWhenScrolling = false
        self.navigationItem.searchController = self.searchController
    }

    @objc
    private func didTapCancelButton(_ sender: UIBarButtonItem) {
        if viewModel.havingUnsavedChanges == true {
            let alertController = UIAlertController(title: LocalString._warning,
                                                    message: LocalString._changes_will_discarded, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: LocalString._general_discard, style: .destructive, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
            present(alertController, animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    @objc
    private func didTapDoneButton() {
        viewModel.save()
        navigationController?.popViewController(animated: true)
    }
}

extension ContactGroupSelectEmailViewController: UISearchBarDelegate, UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.search(query: searchController.searchBar.text)
        queryString = searchController.searchBar.text ?? ""
        tableView.reloadData()
    }
}

extension ContactGroupSelectEmailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getTotalEmailCount()
    }

    // https://medium.com/ios-os-x-development/ios-multiple-selections-in-table-view-88dc2249c3a2
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.kContactGroupEditCellIdentifier,
                                                 for: indexPath) as! ContactGroupEditViewCell

        let ret = viewModel.getCellData(at: indexPath)
        cell.config(emailID: ret.ID,
                    name: ret.name,
                    email: ret.email,
                    queryString: self.queryString,
                    state: .selectEmailView)

        cell.selectionStyle = .none
        if ret.isSelected {
            /*
             Calling this method does not cause the delegate to receive a
             tableView(_:willSelectRowAt:) or tableView(_:didSelectRowAt:) message,
             nor does it send selectionDidChangeNotification notifications to observers.
             */
            self.selectRow(at: indexPath, cell: cell)
        } else {
            self.deselectRow(at: indexPath, cell: cell)
        }

        return cell
    }

    func selectRow(at indexPath: IndexPath, cell: ContactGroupEditViewCell) {
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        cell.setSelected(true, animated: true)
        self.viewModel.selectEmail(ID: cell.emailID)
    }

    func deselectRow(at indexPath: IndexPath, cell: ContactGroupEditViewCell) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        cell.setSelected(false, animated: true)
        self.viewModel.deselectEmail(ID: cell.emailID)
    }
}

extension ContactGroupSelectEmailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? ContactGroupEditViewCell {
            self.selectRow(at: indexPath, cell: cell)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? ContactGroupEditViewCell {
            self.deselectRow(at: indexPath, cell: cell)
        }
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol

extension ContactGroupSelectEmailViewController: NSNotificationCenterKeyboardObserverProtocol {
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
                           animations: {
                               self.view.layoutIfNeeded()
                           }, completion: nil)
        }
    }
}
