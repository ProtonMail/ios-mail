//
//  ContactGroupSelectEmailViewController.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/17.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

class ContactGroupSelectEmailViewController: ProtonMailViewController, ViewModelProtocol
{
    var viewModel: ContactGroupSelectEmailViewModel!
    @IBOutlet weak var tableView: UITableView!
    
    let kContactGroupEditCellIdentifier = "ContactGroupEditCell"
    
    func setViewModel(_ vm: Any) {
        viewModel = vm as! ContactGroupSelectEmailViewModel
    }
    
    override func viewDidLoad() {
        title = "Add Addresses"
        
        tableView.allowsMultipleSelection = true
        tableView.register(UINib(nibName: "ContactGroupEditViewCell", bundle: Bundle.main),
                           forCellReuseIdentifier: kContactGroupEditCellIdentifier)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.save(indexPaths: tableView.indexPathsForSelectedRows)
    }
    
    func inactiveViewModel() {}
}

extension ContactGroupSelectEmailViewController: UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getTotalEmailCount()
    }
    
    // TODO: for custom cell, override setSelected()
    // https://medium.com/ios-os-x-development/ios-multiple-selections-in-table-view-88dc2249c3a2
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: kContactGroupEditCellIdentifier,
                                                 for: indexPath) as! ContactGroupEditViewCell
        
        let ret = viewModel.getCellData(at: indexPath)
        cell.config(name: ret.name,
                    email: ret.email,
                    state: .selectEmailView)
        
        cell.selectionStyle = .none
        if ret.isSelected {
            /*
             Calling this method does not cause the delegate to receive a tableView(_:willSelectRowAt:) or tableView(_:didSelectRowAt:) message,
             nor does it send selectionDidChangeNotification notifications to observers.
             */
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            cell.setSelected(true, animated: true)
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            cell.setSelected(false, animated: true)
        }
        
        return cell
    }
}

extension ContactGroupSelectEmailViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.isSelected = true
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.isSelected = false
    }
}
