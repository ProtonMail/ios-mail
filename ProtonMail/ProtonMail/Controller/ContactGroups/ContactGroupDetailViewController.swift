//
//  ContactGroupDetailViewController.swift
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
import PromiseKit
import MBProgressHUD
import ProtonCore_UIFoundations
import ProtonCore_PaymentsUI

class ContactGroupDetailViewController: ProtonMailViewController, ViewModelProtocol, ComposeSaveHintProtocol {
    typealias viewModelType = ContactGroupDetailViewModel

    var viewModel: ContactGroupDetailViewModel!
    
    @IBOutlet weak var headerContainerView: UIView!
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var groupDetailLabel: UILabel!
    @IBOutlet weak var sendImage: UIImageView!
    @IBOutlet weak var groupImage: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    private var editBarItem: UIBarButtonItem!
    private var paymentsUI: PaymentsUI?
    
    private let kToContactGroupEditSegue = "toContactGroupEditSegue"
    private let kContactGroupViewCellIdentifier = "ContactGroupEditCell"
    private let kToComposerSegue = "toComposer"
    
    func set(viewModel: ContactGroupDetailViewModel) {
        self.viewModel = viewModel
        self.viewModel.reloadView = { [weak self] in
            self?.reload()
        }
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
        self.performSegue(withIdentifier: kToComposerSegue, sender: (ID: viewModel.getGroupID(), name: viewModel.getName()))
    }
    
    @IBAction func editButtonTapped(_ sender: UIBarButtonItem) {
        if self.viewModel.user.hasPaidMailPlan == false {
            presentPlanUpgrade()
            return
        }
        performSegue(withIdentifier: kToContactGroupEditSegue,
                     sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

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

        sendImage.image = Asset.mailSendIcon.image.withRenderingMode(.alwaysTemplate)
        sendImage.tintColor = ColorProvider.InteractionNorm

        prepareTable()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }
    
    private func reload() {
        firstly { () -> Promise<Bool> in
            MBProgressHUD.showAdded(to: self.view, animated: true)
            return self.viewModel.reload()
        }.ensure {
            MBProgressHUD.hide(for: self.view, animated: true)
        }.done { (isDeleted) in
            
            if isDeleted {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.refresh()
            }
        }.catch { error in
            //PMLog.D(error)
        }
    }

    private func refresh() {
        prepareHeader()
        tableView.reloadData()
    }

    private func prepareHeader() {
        groupNameLabel.attributedText = viewModel.getName().apply(style: .Default)
        
        groupDetailLabel.attributedText = viewModel.getTotalEmailString().apply(style: .DefaultSmallWeek)
        
        groupImage.setupImage(tintColor: UIColor.white,
                              backgroundColor: UIColor.init(hexString: viewModel.getColor(),
                                                            alpha: 1))
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kToContactGroupEditSegue {
            let contactGroupEditViewController = segue.destination.children[0] as! ContactGroupEditViewController
            
            if let sender = sender as? ContactGroupDetailViewController,
                let viewModel = sender.viewModel {
                sharedVMService.contactGroupEditViewModel(contactGroupEditViewController,
                                                          user: self.viewModel.user,
                                                          state: .edit,
                                                          groupID: viewModel.getGroupID(),
                                                          name: viewModel.getName(),
                                                          color: viewModel.getColor(),
                                                          emailIDs: viewModel.getEmailIDs())
            } else {
                // TODO: handle error
                PMLog.D("FatalError: Can't prepare for the contact group edit view")
                return
            }
        } else if segue.identifier == kToComposerSegue {
            guard let nav = segue.destination as? UINavigationController,
                let next = nav.viewControllers.first as? ComposeContainerViewController else
            {
                return
            }
            let user = self.viewModel.user
            let viewModel = ContainableComposeViewModel(msg: nil,
                                                        action: .newDraft,
                                                        msgService: user.messageService,
                                                        user: user,
                                                        coreDataService: sharedServices.get(by: CoreDataService.self))
            if let result = sender as? (String, String) {
                let contactGroupVO = ContactGroupVO(ID: result.0, name: result.1)
                contactGroupVO.selectAllEmailFromGroup()
                viewModel.addToContacts(contactGroupVO)
            }
            next.set(viewModel: ComposeContainerViewModel(editorViewModel: viewModel, uiDelegate: next))
            next.set(coordinator: ComposeContainerViewCoordinator(controller: next))
        }
        
        if #available(iOS 13, *) {
            if let nav = segue.destination as? UINavigationController {
                nav.children[0].presentationController?.delegate = self
            }
            segue.destination.presentationController?.delegate = self
        }
    }

    private func presentPlanUpgrade() {
        self.paymentsUI = PaymentsUI(payments: self.viewModel.user.payments, clientApp: .mail, shownPlanNames: Constants.shownPlanNames)
        self.paymentsUI?.showUpgradePlan(presentationType: .modal,
                                         backendFetch: true,
                                         updateCredits: false) { _ in }
    }

}

extension ContactGroupDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getTotalEmails()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 && viewModel.getTotalEmails() > 0 {
            return LocalString._menu_contacts_title
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kContactGroupViewCellIdentifier,
                                                 for: indexPath) as! ContactGroupEditViewCell
        
        let ret = viewModel.getEmail(at: indexPath)
        cell.config(emailID: ret.emailID,
                    name: ret.name,
                    email: ret.email,
                    queryString: "",
                    state: .detailView)
        
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let titleView = view as? UITableViewHeaderFooterView {
            titleView.textLabel?.text =  titleView.textLabel?.text?.capitalized
        }
    }
}

@available (iOS 13, *)
extension ContactGroupDetailViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        reload()
    }
}
