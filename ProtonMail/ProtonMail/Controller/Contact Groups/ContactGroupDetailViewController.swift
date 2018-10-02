//
//  ContactGroupDetailViewController.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/9/10.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit
import PromiseKit

class ContactGroupDetailViewController: ProtonMailViewController, ViewModelProtocol {

    var viewModel: ContactGroupDetailViewModel!
    
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var groupDetailLabel: UILabel!
    @IBOutlet weak var groupImage: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    let kToContactGroupEditSegue = "toContactGroupEditSegue"
    
    let kContactGroupViewCellIdentifier = "ContactGroupEditCell"
    
    func setViewModel(_ vm: Any) {
        viewModel = vm as! ContactGroupDetailViewModel
    }
    
    func inactiveViewModel() {}
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        // TODO
        let alert = UIAlertController(title: "Send email to contact group",
                                      message: "To be implemented",
                                      preferredStyle: .alert)
        alert.addOKAction()
        
        UIApplication.shared.keyWindow?.rootViewController?.present(alert,
                                                                    animated: true,
                                                                    completion: nil)
    }
    
    @IBAction func editButtonTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: kToContactGroupEditSegue,
                     sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Group Details"
        
        prepareTable()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        firstly {
            () -> Promise<Bool> in
            
            ActivityIndicatorHelper.showActivityIndicator(at: self.view)
            return self.viewModel.reload()
            }.done {
                (isDeleted) in
                
                if isDeleted {
                    self.navigationController?.popViewController(animated: true)
                } else {
                    self.refresh()
                }
            }.ensure {
                ActivityIndicatorHelper.hideActivityIndicator(at: self.view)
        }
    }
    
    private func refresh() {
        prepareHeader()
        tableView.reloadData()
    }

    private func prepareHeader() {
        groupNameLabel.text = viewModel.getName()
        
        groupDetailLabel.text = viewModel.getTotalEmailString()
        
        groupImage.backgroundColor = UIColor(hexString: viewModel.getColor(),
                                             alpha: 1.0)
        groupImage.layer.cornerRadius = 20.0
    }
    
    private func prepareTable() {
        tableView.register(UINib(nibName: "ContactGroupEditViewCell", bundle: Bundle.main),
                           forCellReuseIdentifier: kContactGroupViewCellIdentifier)
        tableView.noSeparatorsBelowFooter()
        
        tableView.allowsSelection = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kToContactGroupEditSegue {
            let contactGroupEditViewController = segue.destination.childViewControllers[0] as! ContactGroupEditViewController
            
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
                fatalError("Can't prepare for the contact group edit view")
            }
        }
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
        if section == 0 {
            return "CONTACTS"
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kContactGroupViewCellIdentifier,
                                                 for: indexPath) as! ContactGroupEditViewCell
        
        let ret = viewModel.getEmail(at: indexPath)
        cell.config(name: ret.name,
                    email: ret.email,
                    state: .detailView)
        
        return cell
    }
}
