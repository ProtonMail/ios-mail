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

import Combine
import CoreData
import LifetimeTracker
import MBProgressHUD
import ProtonCoreUIFoundations
import ProtonMailUI
import UIKit
import SwiftUI

final class ContactsViewController: ContactsAndGroupsSharedCode {
    typealias Dependencies = ContactsAndGroupsSharedCode.Dependencies
        & HasContactViewsFactory
        & HasImportDeviceContacts
        & HasInternetConnectionStatusProviderProtocol
        & HasUserManager
        & HasAddressBookService

    private enum Layout {
        static let importContactsHeight: CGFloat = 24.0
    }

    private var noContactsView: NoContactView = SubviewFactory.noContactsView
    private let noContactsUIView: UIView = SubviewFactory.noContactsUIView
    private let importContactsStack: UIStackView = SubviewFactory.importContactsStack
    private let importContactsIcon = UIImageView(image: IconProvider.arrowsRotate.toTemplateUIImage())
    private let importContactsProgress = SubviewFactory.importContactsProgressLabel
    private var importContactsStackTopConstraint: NSLayoutConstraint = .init()
    let tableView: UITableView = .init()
    private var tableViewBottomConstraint: NSLayoutConstraint = .init()

    private let viewModel: ContactsViewModel
    private let dependencies: Dependencies
    private var searchString: String = ""
    private var refreshControl: UIRefreshControl?
    private(set) var searchController: UISearchController?

    private var diffableDataSource: SectionTitleUITableViewDiffableDataSource<String, ContactEntity>?
    private var cancellables: Set<AnyCancellable> = .init()
    private var contactAutoSyncBannerHost: BannerHostViewController<ContactAutoSyncBanner>?

    init(viewModel: ContactsViewModel, dependencies: Dependencies) {
        self.viewModel = viewModel
        self.dependencies = dependencies
        super.init(dependencies: dependencies, nibName: nil)

        trackLifetime()
        setUpUI()
        setUpConstraints()
        setUpBindings()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpUI() {
        view.addSubviews(importContactsStack, tableView, noContactsUIView)
        noContactsView.model.onDidTapAutoImport = { [weak self] in
            self?.autoImportContactIsStarted()
        }

        setUpImportContactsStack()
    }

    private func setUpImportContactsStack() {
        importContactsIcon.tintColor = ColorProvider.IconHint
        let font = UIFont.preferredFont(for: .subheadline, weight: .regular)
        let title = UILabel(LocalString._contacts_importing, font: font, textColor: ColorProvider.TextHint)

        let iconContainer = UIView()
        iconContainer.addSubview(importContactsIcon)
        importContactsIcon.rotate()

        [iconContainer, title, importContactsProgress].forEach(importContactsStack.addArrangedSubview)
        importContactsProgress.setContentCompressionResistancePriority(.required, for: .horizontal)

        [
            importContactsIcon.leadingAnchor.constraint(equalTo: iconContainer.leadingAnchor),
            importContactsIcon.widthAnchor.constraint(equalToConstant: 16),
            importContactsIcon.heightAnchor.constraint(equalToConstant: 16),
            importContactsIcon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconContainer.topAnchor.constraint(equalTo: importContactsStack.topAnchor),
            iconContainer.bottomAnchor.constraint(equalTo: importContactsStack.bottomAnchor),
            iconContainer.widthAnchor.constraint(equalTo: importContactsIcon.widthAnchor),
            title.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            importContactsProgress.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor)
        ].activate()
    }

    private func setUpConstraints() {
        let guide = self.view.safeAreaLayoutGuide
        noContactsUIView.fillSuperview()
        importContactsStack.translatesAutoresizingMaskIntoConstraints = false
        importContactsStackTopConstraint = importContactsStack.topAnchor.constraint(equalTo: guide.topAnchor)
        [
            importContactsStack.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            importContactsStackTopConstraint,
            importContactsStack.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            importContactsStack.heightAnchor.constraint(equalToConstant: Layout.importContactsHeight),
        ].activate()

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableViewBottomConstraint = tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        [
            tableView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: importContactsStack.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            tableViewBottomConstraint,
        ].activate()
    }

    private func setUpBindings() {
        viewModel
            .importContactsProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                guard let self else { return }
                let willBeVisible = importContactsStack.isHidden && !progress.isEmpty
                self.importContactsProgress.text = progress
                self.importContactsStack.isHidden = progress.isEmpty
                self.importContactsStackTopConstraint.constant = progress.isEmpty ? -Layout.importContactsHeight : 0
                if willBeVisible { importContactsIcon.rotate() }
            }
            .store(in: &cancellables)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ColorProvider.BackgroundNorm

        self.tableView.register(ContactsTableViewCell.nib, forCellReuseIdentifier: ContactsTableViewCell.cellID)
        let refreshControl = UIRefreshControl()
        self.refreshControl = refreshControl
        self.refreshControl?.addTarget(self, action: #selector(self.fireFetch), for: UIControl.Event.valueChanged)

        self.tableView.estimatedRowHeight = 60.0
        self.tableView.addSubview(refreshControl)
        self.tableView.delegate = self

        self.refreshControl?.tintColor = ColorProvider.BrandNorm
        self.refreshControl?.tintColorDidChange()

        self.navigationController?.navigationBar.prefersLargeTitles = false
        self.definesPresentationContext = true
        self.extendedLayoutIncludesOpaqueBars = true
        self.tableView.noSeparatorsBelowFooter()
        self.tableView.sectionIndexColor = ColorProvider.BrandNorm
        self.tableView.backgroundColor = ColorProvider.BackgroundNorm

        setupDataSource()
        tableView.dataSource = diffableDataSource
        viewModel.contentDidChange = { [weak self] snapshot in
            self?.publisher.send(snapshot)
        }
        publisher
            .throttle(
                for: .seconds(1), // we need it to avoid glitches when adding contacts manually
                scheduler: DispatchQueue.main,
                latest: true
            )
            .sink { [weak self] snapshot in
                self?.diffableDataSource?.apply(snapshot, animatingDifferences: false)
                self?.showNoContactViewIfNeeded(hasContact: snapshot.numberOfItems > 0)
            }
            .store(in: &cancellables)

        self.viewModel.setupFetchedResults()
        self.prepareSearchBar()

        emptyBackButtonTitleForNextView()

        setupMenuButton(userInfo: dependencies.user.userInfo)

        prepareNavigationItemRightDefault()

        generateAccessibilityIdentifiers()
        navigationItem.assignNavItemIndentifiers()
    }

    private let publisher: CurrentValueSubject<NSDiffableDataSourceSnapshot<String, ContactEntity>, Never> = .init(.init())

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.setEditing(false, animated: true)
        self.title = LocalString._contacts_title

        noContactsView.model.isAutoImportContactsEnabled = dependencies.autoImportContactsFeature.isSettingEnabledForUser

        // reload table view in a way that will refresh no-contact views
        publisher.send(publisher.value)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.setupTimer(true)
        NotificationCenter.default.addKeyboardObserver(self)

        self.isOnMainView = true
        self.setupMenuButton(userInfo: dependencies.user.userInfo)

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

        updateHeaderConstraint()
    }

    private func prepareSearchBar() {
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController?.searchBar.placeholder = LocalString._general_search_placeholder
        self.searchController?.searchResultsUpdater = self
        self.searchController?.obscuresBackgroundDuringPresentation = false
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

        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.hidesSearchBarWhenScrolling = false
        self.navigationItem.searchController = self.searchController
        self.navigationItem.assignNavItemIndentifiers()
    }

    override func addContactGroupTapped() {
        if viewModel.hasPaidMailPlan {
            let newView = dependencies.contactViewsFactory.makeGroupEditView(
                state: .create,
                groupID: nil,
                name: nil,
                color: nil,
                emailIDs: []
            )
            let nav = UINavigationController(rootViewController: newView)
            self.present(nav, animated: true, completion: nil)
        } else {
            presentPlanUpgrade()
        }
    }

    override func showContactImportView() {
        self.isOnMainView = true

        let newView = dependencies.contactViewsFactory.makeImportView()
        setPresentationStyleForSelfController(presentingController: newView, style: .overFullScreen)
        newView.reloadAllContact = { [weak self] in
            self?.tableView.reloadData()
        }
        self.present(newView, animated: false, completion: nil)
    }

    private func showContactDetailView(contact: ContactEntity) {
        let newView = dependencies.contactViewsFactory.makeDetailView(contact: contact)
        self.show(newView, sender: nil)
        isOnMainView = false

        // detect view dismiss above iOS 13
        if let nav = self.navigationController {
            nav.children[0].presentationController?.delegate = self
        }
        newView.presentationController?.delegate = self
    }

    override func addContactTapped() {
        let newView = dependencies.contactViewsFactory.makeEditView(contact: nil)
        let nav = UINavigationController(rootViewController: newView)
        self.present(nav, animated: true)

        // detect view dismiss above iOS 13
        nav.children[0].presentationController?.delegate = self
        nav.presentationController?.delegate = self
    }

    @objc
    private func fireFetch() {
        guard dependencies.internetConnectionStatusProvider.status.isConnected else {
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
            }
            return
        }
        self.viewModel.fetchContacts { [weak self] error in
            DispatchQueue.main.async {
                if let error = error as NSError? {
                    let alertController = error.alertController()
                    alertController.addOKAction()
                    self?.present(alertController, animated: true, completion: nil)
                }
                self?.refreshControl?.endRefreshing()
            }
        }
    }

    private func showDeleteContactAlert(for contact: ContactEntity) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(
            UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil)
        )
        alertController.addAction(
            UIAlertAction(
                title: LocalString._delete_contact,
                style: .destructive,
                handler: { _ in
                    MBProgressHUD.showAdded(to: self.view, animated: true)
                    self.viewModel.delete(contactID: contact.contactID, complete: { error in
                        MBProgressHUD.hide(for: self.view, animated: true)
                        if let err = error {
                            err.alert(at: self.view)
                        }
                    })
                }
            )
        )

        alertController.popoverPresentationController?.sourceView = tableView
        alertController.popoverPresentationController?.sourceRect = CGRect(
            x: tableView.bounds.midX,
            y: tableView.bounds.maxY - 100,
            width: 0,
            height: 0
        )
        alertController.assignActionsAccessibilityIdentifiers()
        present(alertController, animated: true, completion: nil)
    }

    private func setupDataSource() {
        diffableDataSource = SectionTitleUITableViewDiffableDataSource(tableView: self.tableView, cellProvider: { [weak self] tableView, indexPath, contact in
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ContactsTableViewCell.cellID,
                for: indexPath
            ) as? ContactsTableViewCell
            cell?.config(
                name: contact.name,
                email: contact.displayEmails,
                highlight: self?.searchString ?? .empty
            )
            return cell
        })
        diffableDataSource?.sectionTitleProvider = { _, section in
            section
        }
        diffableDataSource?.useSectionIndex = true
    }

    private func showContactAutoSyncBannerIfNeeded() {
        guard viewModel.showShowContactAutoSyncBanner() else {
            removeContactAutoSyncBanner()
            return
        }

        let banner = ContactAutoSyncBanner(
            title: L10n.AutoImportContacts.contactBannerTitle,
            buttonTitle: L10n.AutoImportContacts.contactBannerButtonTitle,
            buttonTriggered: { [weak self] in
                self?.dependencies.addressBookService
                    .requestAuthorizationWithCompletion({ granted, error in
                    DispatchQueue.main.async {
                        if granted {
                            self?.viewModel.enableAutoContactSync()
                        } else {
                            let alert = UIAlertController.makeContactAccessDeniedAlert()
                            self?.present(alert, animated: true, completion: nil)
                        }
                        self?.removeContactAutoSyncBanner()
                        self?.viewModel.markAutoContactSyncAsSeen()
                    }
                })
            },
            dismiss: { [weak self] in
                self?.viewModel.markAutoContactSyncAsSeen()
                self?.removeContactAutoSyncBanner()
            }
        )
        let hostVC = BannerHostViewController(rootView: banner)
        guard let viewToAdd = hostVC.view else { return }
        tableView.tableHeaderView = viewToAdd
        contactAutoSyncBannerHost = hostVC
        updateHeaderConstraint()
    }

    private func updateHeaderConstraint() {
        if !tableView.frame.isEmpty, let headerView = tableView.tableHeaderView {
            // Apparently setting the frame and setting the tableViewHeader property again is needed
            // https://stackoverflow.com/questions/16471846/is-it-possible-to-use-autolayout-with-uitableviews-tableheaderview
            headerView.frame.size = headerView.systemLayoutSizeFitting(
                CGSize(width: tableView.frame.width, height: 0)
            )
            tableView.tableHeaderView = headerView
        }
    }

    private func removeContactAutoSyncBanner() {
        tableView.tableHeaderView = nil
        contactAutoSyncBannerHost = nil
    }
}

// MARK: No contact hint
extension ContactsViewController {
    private func showNoContactViewIfNeeded(hasContact: Bool) {
        guard dependencies.autoImportContactsFeature.isFeatureEnabled else {
            noContactsUIView.isHidden = true
            return
        }
        guard searchString.isEmpty, !hasContact else {
            showContactAutoSyncBannerIfNeeded()
            noContactsUIView.isHidden = true
            return
        }
        noContactsUIView.isHidden = false

        removeContactAutoSyncBanner()
    }

    private func autoImportContactIsStarted() {
        dependencies.autoImportContactsFeature.enableSettingForUser()
        let params = ImportDeviceContacts.Params(
            userKeys: dependencies.user.userInfo.userKeys,
            mailboxPassphrase: dependencies.user.mailboxPassword
        )
        dependencies.importDeviceContacts.execute(params: params)
    }
}

extension ContactsViewController: UISearchBarDelegate, UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        self.searchString = searchController.searchBar.text ?? ""
        self.viewModel.search(text: self.searchString)
        self.tableView.reloadData()
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.refreshControl?.endRefreshing()
        self.refreshControl?.removeFromSuperview()
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if let refreshControl = self.refreshControl {
            self.tableView.addSubview(refreshControl)
        }
    }
}

// MARK: - UITableViewDelegate

extension ContactsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let contextItem = UIContextualAction(
            style: .destructive,
            title: LocalString._general_delete_action
        ) { [weak self] _, _, completion in
            guard let self,
                  let contact = self.diffableDataSource?.itemIdentifier(for: indexPath) else {
                completion(false)
                return
            }
            self.showDeleteContactAlert(for: contact)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [contextItem])
    }

    func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let contact = diffableDataSource?.itemIdentifier(for: indexPath) {
            self.showContactDetailView(contact: contact)
        }
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
            self.tableViewBottomConstraint.constant = -keyboardSize.height

            UIView.animate(withDuration: keyboardInfo.duration,
                           delay: 0,
                           options: keyboardInfo.animationOption,
                           animations: { () in
                               self.view.layoutIfNeeded()
                           }, completion: nil)
        }
    }
}

extension ContactsViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        self.isOnMainView = true
    }
}

extension ContactsViewController {
    private enum SubviewFactory {

        static var importContactsStack: UIStackView {
            .stackView(axis: .horizontal, distribution: .fillProportionally, alignment: .top, spacing: 4.0)
        }

        static var importContactsProgressLabel: UILabel {
            let font = UIFont.preferredFont(for: .subheadline, weight: .regular)
            let label = UILabel("", font: font, textColor: ColorProvider.TextHint)
            label.textAlignment = .right
            return label
        }

        static var noContactsView: NoContactView {
            NoContactView()
        }

        static var noContactsUIView: UIView {
            let componentVC = ComponentViewController(rootView: Self.noContactsView)
            return componentVC.view
        }
    }
}

extension UIImageView {
    func rotate() {
        let rotation : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 2
        rotation.isCumulative = true
        rotation.repeatCount = Float.greatestFiniteMagnitude
        self.layer.add(rotation, forKey: "rotationAnimation")
    }
}
