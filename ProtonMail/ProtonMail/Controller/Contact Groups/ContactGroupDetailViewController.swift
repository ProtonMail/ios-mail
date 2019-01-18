//
//  ContactGroupDetailViewController.swift
//  ProtonMail
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import UIKit
import PromiseKit

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
        if sharedUserDataService.isPaidUser() {
            self.performSegue(withIdentifier: kToComposerSegue, sender: (ID: viewModel.getGroupID(), name: viewModel.getName()))
        } else {
            self.performSegue(withIdentifier: kToUpgradeAlertSegue, sender: self)
        }
    }
    
    @IBAction func editButtonTapped(_ sender: UIBarButtonItem) {
        if sharedUserDataService.isPaidUser() == false {
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
        
        firstly { () -> Promise<Bool> in
            ActivityIndicatorHelper.showActivityIndicator(at: self.view)
            return self.viewModel.reload()
        }.ensure {
            ActivityIndicatorHelper.hideActivityIndicator(at: self.view)
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
            let destination = segue.destination.children[0] as! ComposeViewController
            if let result = sender as? (String, String) {
                let contactGroupVO = ContactGroupVO.init(ID: result.0, name: result.1)
                contactGroupVO.selectAllEmailFromGroup()
                sharedVMService.newDraft(vmp: destination)
                //TODO::fixme finish up here fix services partservices
                let viewModel = ComposeViewModelImpl(msg: nil, action: .newDraft)
                viewModel.addToContacts(contactGroupVO)
                let coordinator = ComposeCoordinator(vc: destination,
                                                     vm: viewModel, services: ServiceFactory.default) //set view model
                coordinator.start()
            }
        } else if segue.identifier == kToUpgradeAlertSegue {
            let popup = segue.destination as! UpgradeAlertViewController
            popup.delegate = self
            sharedVMService.upgradeAlert(contacts: popup)
            self.setPresentationStyleForSelfController(self,
                                                       presentingController: popup,
                                                       style: .overFullScreen)
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
