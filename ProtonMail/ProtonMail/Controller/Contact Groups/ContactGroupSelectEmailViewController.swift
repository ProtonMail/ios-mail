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
    
    func setViewModel(_ vm: Any) {
        viewModel = vm as! ContactGroupSelectEmailViewModel
    }
    
    override func viewDidLoad() {
        tableView.allowsMultipleSelection = true
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactGroupSelectEmailCell",
                                                 for: indexPath)
        
        let ret = viewModel.getCellData(at: indexPath)
        cell.textLabel?.text = ret.name
        cell.detailTextLabel?.text = ret.email
        
        cell.selectionStyle = .none
        if ret.isSelected {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            cell.accessoryType = .checkmark
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            cell.accessoryType = .none
        }
        
        return cell
    }
}

extension ContactGroupSelectEmailViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.isSelected = true
        cell?.accessoryType = .checkmark
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.isSelected = false
        cell?.accessoryType = .none
    }
}
