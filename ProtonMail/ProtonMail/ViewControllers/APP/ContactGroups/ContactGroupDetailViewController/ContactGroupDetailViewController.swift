//
//  ContactGroupDetailViewController.swift
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

import LifetimeTracker
import PromiseKit
import ProtonCoreFoundations
import ProtonCoreUIFoundations
import UIKit

final class ContactGroupDetailViewController: UIViewController, ComposeSaveHintProtocol, AccessibleView, LifetimeTrackable {
    typealias Dependencies = HasComposerViewFactory & HasContactViewsFactory & HasCoreDataContextProviderProtocol  & HasPaymentsUIFactory

    class var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }

    var viewModel: ContactGroupDetailVMProtocol!
    private let dependencies: Dependencies

    @IBOutlet weak var headerContainerView: UIView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var groupDetailLabel: UILabel!
    @IBOutlet weak var sendImage: UIImageView!
    @IBOutlet weak var groupImage: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    private var editBarItem: UIBarButtonItem!
    private var upsellCoordinator: UpsellCoordinator?

    private let kContactGroupViewCellIdentifier = "ContactGroupEditCell"

    init(viewModel: ContactGroupDetailVMProtocol, dependencies: Dependencies) {
        self.viewModel = viewModel
        self.dependencies = dependencies
        super.init(nibName: "ContactGroupDetailViewController", bundle: nil)
        self.viewModel.reloadView = { [weak self] in
            DispatchQueue.main.async {
                self?.refresh()
            }
        }
        self.viewModel.dismissView = { [weak self] in
            DispatchQueue.main.async {
                self?.navigationController?.popViewController(animated: true)
            }
        }
        trackLifetime()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(viewModel != nil)

        editBarItem = UIBarButtonItem(title: LocalString._general_edit_action,
                                      style: .plain,
                                      target: self,
                                      action: #selector(self.editButtonTapped(_:)))
        let attributes = FontManager.DefaultStrong.foregroundColor(ColorProvider.InteractionNorm)
        editBarItem.setTitleTextAttributes(attributes, for: .normal)
        navigationItem.rightBarButtonItem = editBarItem

        view.backgroundColor = ColorProvider.BackgroundNorm
        tableView.backgroundColor = ColorProvider.BackgroundNorm

        headerContainerView.backgroundColor = ColorProvider.BackgroundNorm

        sendImage.image = IconProvider.paperPlaneHorizontal.withRenderingMode(.alwaysTemplate)
        sendImage.tintColor = ColorProvider.InteractionNorm

        prepareTable()
        prepareHeader()
        generateAccessibilityIdentifiers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.user.undoActionManager.register(handler: self)
    }

    @IBAction func sendButtonTapped(_ sender: UIButton) {
        guard self.viewModel.user.hasPaidMailPlan else {
            presentPlanUpgrade()
            return
        }
        guard !self.viewModel.user.isStorageExceeded else {
            LocalString._storage_exceeded.alertToastBottom()
            return
        }

        let contactGroupVO = ContactGroupVO(
            ID: viewModel.groupID.rawValue,
            name: viewModel.name,
            contextProvider: dependencies.contextProvider
        )
        contactGroupVO.selectAllEmailFromGroup()

        let composer = dependencies.composerViewFactory.makeComposer(
            msg: nil,
            action: .newDraft,
            isEditingScheduleMsg: false,
            toContact: contactGroupVO
        )

        self.present(composer, animated: true)
    }

    @IBAction func editButtonTapped(_ sender: UIBarButtonItem) {
        if self.viewModel.user.hasPaidMailPlan == false {
            presentPlanUpgrade()
            return
        }
        let newView = dependencies.contactViewsFactory.makeGroupEditView(
            state: .edit,
            groupID: viewModel.groupID.rawValue,
            name: viewModel.name,
            color: viewModel.color,
            emailIDs: Set(viewModel.emails)
        )
        newView.delegate = self
        let nav = UINavigationController(rootViewController: newView)
        self.present(nav, animated: true, completion: nil)
    }

    private func refresh() {
        prepareHeader()
        tableView.reloadData()
    }

    private func prepareHeader() {
        groupNameLabel.attributedText = viewModel.name.apply(style: .Default)

        groupDetailLabel.attributedText = viewModel.getTotalEmailString().apply(style: .DefaultSmallWeek)

        groupImage.image = IconProvider.users
        groupImage.setupImage(tintColor: UIColor.white,
                              backgroundColor: UIColor.init(hexString: viewModel.color, alpha: 1))
        if let image = sendButton.imageView?.image {
            sendButton.imageView?.contentMode = .center
            sendButton.imageView?.image = UIImage.resize(image: image, targetSize: CGSize.init(width: 20, height: 20))
        }
    }

    private func prepareTable() {
        tableView.register(UINib(nibName: "ContactGroupEditViewCell", bundle: Bundle.main),
                           forCellReuseIdentifier: kContactGroupViewCellIdentifier)
        tableView.noSeparatorsBelowFooter()
        tableView.estimatedRowHeight = 60.0
        tableView.allowsSelection = false
    }

    private func presentPlanUpgrade() {
        guard let tabBarController else {
            return
        }

        upsellCoordinator = dependencies.paymentsUIFactory.makeUpsellCoordinator(rootViewController: tabBarController)
        upsellCoordinator?.start(entryPoint: .contactGroups)
    }
}

extension ContactGroupDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.emails.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 && !viewModel.emails.isEmpty {
            return LocalString._menu_contacts_title
        }
        return nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kContactGroupViewCellIdentifier,
                                                 for: indexPath) as! ContactGroupEditViewCell
        guard let data = viewModel.emails[safe: indexPath.row] else {
            return cell
        }
        cell.config(emailID: data.emailID,
                    name: data.name,
                    email: data.email,
                    queryString: "",
                    state: .detailView)

        return cell
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let titleView = view as? UITableViewHeaderFooterView {
            titleView.textLabel?.text = titleView.textLabel?.text?.capitalized
        }
    }
}

extension ContactGroupDetailViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        refresh()
    }
}

extension ContactGroupDetailViewController: UndoActionHandlerBase {
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

extension ContactGroupDetailViewController: ContactGroupEditDelegate {
    func didDeleteGroup() {
        self.navigationController?.popViewController(animated: true)
    }
}
