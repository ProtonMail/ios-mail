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

class ContactGroupDetailViewController: ProtonMailViewController, ViewModelProtocol {
    typealias viewModelType = ContactGroupDetailViewModel

    var viewModel: ContactGroupDetailViewModel!
    
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var groupDetailLabel: UILabel!
    @IBOutlet weak var groupImage: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    
    private let kToContactGroupEditSegue = "toContactGroupEditSegue"
    private let kContactGroupViewCellIdentifier = "ContactGroupEditCell"
    private let kToComposerSegue = "toComposer"
    private let kToUpgradeAlertSegue = "toUpgradeAlertSegue"
    
    func set(viewModel: ContactGroupDetailViewModel) {
        self.viewModel = viewModel
    }
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        if self.viewModel.user.isPaid {
            self.performSegue(withIdentifier: kToComposerSegue, sender: (ID: viewModel.getGroupID(), name: viewModel.getName()))
        } else {
            self.performSegue(withIdentifier: kToUpgradeAlertSegue, sender: self)
        }
    }
    
    @IBAction func editButtonTapped(_ sender: UIBarButtonItem) {
        if self.viewModel.user.isPaid == false {
            self.performSegue(withIdentifier: kToUpgradeAlertSegue, sender: self)
            return
        }
        performSegue(withIdentifier: kToContactGroupEditSegue,
                     sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = LocalString._contact_groups_detail_view_title
        
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
        groupNameLabel.text = viewModel.getName()
        
        groupDetailLabel.text = viewModel.getTotalEmailString()
        
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
                                                        user: user)
            if let result = sender as? (String, String) {
                let contactGroupVO = ContactGroupVO(ID: result.0, name: result.1)
                contactGroupVO.selectAllEmailFromGroup()
                viewModel.addToContacts(contactGroupVO)
            }
            next.set(viewModel: ComposeContainerViewModel(editorViewModel: viewModel))
            next.set(coordinator: ComposeContainerViewCoordinator(controller: next))
            
        } else if segue.identifier == kToUpgradeAlertSegue {
            let popup = segue.destination as! UpgradeAlertViewController
            popup.delegate = self
            sharedVMService.upgradeAlert(contacts: popup)
            self.setPresentationStyleForSelfController(self,
                                                       presentingController: popup,
                                                       style: .overFullScreen)
        }
        
        if #available(iOS 13, *) {
            if let nav = segue.destination as? UINavigationController {
                nav.children[0].presentationController?.delegate = self
            }
            segue.destination.presentationController?.delegate = self
        }
    }
}

extension ContactGroupDetailViewController: UpgradeAlertVCDelegate {
    func postToPlan() {
        NotificationCenter.default.post(name: .switchView,
                                        object: DeepLink(MenuCoordinatorNew.Destination.plan.rawValue))
    }
    func goPlans() {
        if self.presentingViewController != nil {
            self.dismiss(animated: true) {
                self.postToPlan()
            }
        } else {
            self.postToPlan()
        }
    }
    
    func learnMore() {
        UIApplication.shared.openURL(.paidPlans)
    }
    
    func cancel() {
        
    }
}

extension ContactGroupDetailViewController: UITableViewDataSource
{
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
}

@available (iOS 13, *)
extension ContactGroupDetailViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        reload()
    }
}
