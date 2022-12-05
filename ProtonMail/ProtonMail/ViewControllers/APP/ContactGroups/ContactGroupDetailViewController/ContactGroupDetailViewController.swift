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
import MBProgressHUD
import PromiseKit
import ProtonCore_Foundations
import ProtonCore_PaymentsUI
import ProtonCore_UIFoundations
import UIKit

final class ContactGroupDetailViewController: UIViewController, ComposeSaveHintProtocol, AccessibleView, LifetimeTrackable {
    class var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }

    var viewModel: ContactGroupDetailVMProtocol!

    @IBOutlet weak var headerContainerView: UIView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var groupDetailLabel: UILabel!
    @IBOutlet weak var sendImage: UIImageView!
    @IBOutlet weak var groupImage: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    private var editBarItem: UIBarButtonItem!
    private var paymentsUI: PaymentsUI?

    private let kContactGroupViewCellIdentifier = "ContactGroupEditCell"

    init(viewModel: ContactGroupDetailVMProtocol) {
        self.viewModel = viewModel
        super.init(nibName: "ContactGroupDetailViewController", bundle: nil)
        self.viewModel.reloadView = { [weak self] in
            self?.reload()
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
        generateAccessibilityIdentifiers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
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

        let user = self.viewModel.user
        let viewModel = ContainableComposeViewModel(msg: nil,
                                                    action: .newDraft,
                                                    msgService: user.messageService,
                                                    user: user,
                                                    coreDataContextProvider: sharedServices.get(by: CoreDataService.self))

        let contactGroupVO = ContactGroupVO(ID: self.viewModel.groupID.rawValue, name: self.viewModel.name)
        contactGroupVO.selectAllEmailFromGroup()
        viewModel.addToContacts(contactGroupVO)

        let coordinator = ComposeContainerViewCoordinator(presentingViewController: self, editorViewModel: viewModel)
        coordinator.start()
    }

    @IBAction func editButtonTapped(_ sender: UIBarButtonItem) {
        if self.viewModel.user.hasPaidMailPlan == false {
            presentPlanUpgrade()
            return
        }
        let viewModel = ContactGroupEditViewModelImpl(state: .edit,
                                                      user: viewModel.user,
                                                      groupID: viewModel.groupID.rawValue,
                                                      name: viewModel.name,
                                                      color: viewModel.color,
                                                      emailIDs: Set(viewModel.emails))
        let newView = ContactGroupEditViewController(viewModel: viewModel)
        let nav = UINavigationController(rootViewController: newView)
        self.present(nav, animated: true, completion: nil)
    }

    private func reload() {
        let isReloadSuccessful = self.viewModel.reload()
        if isReloadSuccessful {
            self.refresh()
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    private func refresh() {
        prepareHeader()
        tableView.reloadData()
    }

    private func prepareHeader() {
        groupNameLabel.attributedText = viewModel.name.apply(style: .Default)

        groupDetailLabel.attributedText = viewModel.getTotalEmailString().apply(style: .DefaultSmallWeek)

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
        self.paymentsUI = PaymentsUI(payments: self.viewModel.user.payments, clientApp: .mail, shownPlanNames: Constants.shownPlanNames)
        self.paymentsUI?.showUpgradePlan(presentationType: .modal,
                                         backendFetch: true) { _ in }
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

@available (iOS 13, *)
extension ContactGroupDetailViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        reload()
    }
}

extension ContactGroupDetailViewController: UndoActionHandlerBase {
    var delaySendSeconds: Int {
        self.viewModel.user.userInfo.delaySendSeconds
    }

    var composerPresentingVC: UIViewController? {
        self
    }

    func showUndoAction(undoTokens: [String], title: String) { }
}
