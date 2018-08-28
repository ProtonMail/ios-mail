//
//  ContactGroupSelectEmailViewController.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/17.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

/*
 Prototyping goals:
 1. Use native UITableView and native cell
 2. When the view appears, the cells are available for multiselection
 3. When the backward button is pressed, send the labelling request
 4. Maintain labelling information using NSSet
 */

class ContactGroupSelectEmailViewController: ProtonMailViewController, ViewModelProtocol
{
    var viewModel: ContactGroupSelectEmailViewModel!
    @IBOutlet weak var tableView: UITableView!
    
    func setViewModel(_ vm: Any) {
        viewModel = vm as! ContactGroupSelectEmailViewModel
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.save()
    }
    
    func inactiveViewModel() {}
    
    // table view
    
    // selection 
}

extension ContactGroupSelectEmailViewController: UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getTotalEmailCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactGroupSelectEmailCell",
                                                 for: indexPath)
        cell.textLabel?.text = viewModel.getCellData(at: indexPath)
        print(viewModel.getCellData(at: indexPath))
        return cell
    }
}

extension ContactGroupSelectEmailViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let status = viewModel.selectEmail(at: indexPath)
        
        let alert = UIAlertController(title: "Selected email",
                                      message: "You have \(status ? "" : "de")selected email \(viewModel.getCellData(at: indexPath))",
            preferredStyle: .alert)
        alert.addOKAction()
        
        present(alert, animated: true, completion: nil)
    }
}
