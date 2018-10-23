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
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchViewConstraint: NSLayoutConstraint!
    
    private var emailQueryString = ""
    private var searchController: UISearchController!
    
    let kContactGroupEditCellIdentifier = "ContactGroupEditCell"
    
    func setViewModel(_ vm: Any) {
        viewModel = vm as! ContactGroupSelectEmailViewModel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalString._contact_groups_manage_addresses
        
        tableView.allowsMultipleSelection = true
        tableView.register(UINib(nibName: "ContactGroupEditViewCell", bundle: Bundle.main),
                           forCellReuseIdentifier: kContactGroupEditCellIdentifier)
        
        prepareSearchBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // if the user is tricky enough the hold the view using the edge geatures
        // we will need to turn this off temporarily
        self.extendedLayoutIncludesOpaqueBars = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // set this after the layout is completed
        // so when the view disappeared, the search bar view won't leave a
        // black block underneath it
        self.extendedLayoutIncludesOpaqueBars = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.save()
    }
    
    func inactiveViewModel() {}
    
    private func prepareSearchBar() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = LocalString._general_search_placeholder
        searchController.searchBar.setValue(LocalString._general_cancel_button,
                                            forKey:"_cancelButtonText")
        
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchBar.delegate = self
        self.searchController.hidesNavigationBarDuringPresentation = true
        self.searchController.automaticallyAdjustsScrollViewInsets = true
        self.searchController.searchBar.sizeToFit()
        self.searchController.searchBar.keyboardType = .default
        self.searchController.searchBar.autocapitalizationType = .none
        self.searchController.searchBar.isTranslucent = false
        self.searchController.searchBar.tintColor = .white
        self.searchController.searchBar.barTintColor = UIColor.ProtonMail.Nav_Bar_Background
        self.searchController.searchBar.backgroundColor = .clear
        
        if #available(iOS 11.0, *) {
            self.searchViewConstraint.constant = 0.0
            self.searchView.isHidden = true
            self.navigationItem.largeTitleDisplayMode = .never
            self.navigationItem.hidesSearchBarWhenScrolling = false
            self.navigationItem.searchController = self.searchController
        } else {
            self.searchViewConstraint.constant = self.searchController.searchBar.frame.height
            self.searchView.backgroundColor = UIColor.ProtonMail.Nav_Bar_Background
            self.searchView.addSubview(self.searchController.searchBar)
            self.searchController.searchBar.contactSearchSetup(textfieldBG: UIColor.init(hexColorCode: "#82829C"),
                                                               placeholderColor: UIColor.init(hexColorCode: "#BBBBC9"), textColor: .white)
        }
    }
}

extension ContactGroupSelectEmailViewController: UISearchBarDelegate, UISearchResultsUpdating
{
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.search(query: searchController.searchBar.text)
        emailQueryString = searchController.searchBar.text ?? ""
        tableView.reloadData()
    }
}

extension ContactGroupSelectEmailViewController: UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getTotalEmailCount()
    }
    
    // https://medium.com/ios-os-x-development/ios-multiple-selections-in-table-view-88dc2249c3a2
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: kContactGroupEditCellIdentifier,
                                                 for: indexPath) as! ContactGroupEditViewCell
        
        let ret = viewModel.getCellData(at: indexPath)
        cell.config(emailID: ret.ID,
                    name: ret.name,
                    email: ret.email,
                    emailQueryString: self.emailQueryString,
                    state: .selectEmailView)
        
        cell.selectionStyle = .none
        if ret.isSelected {
            /*
             Calling this method does not cause the delegate to receive a
             tableView(_:willSelectRowAt:) or tableView(_:didSelectRowAt:) message,
             nor does it send selectionDidChangeNotification notifications to observers.
             */
            self.selectRow(at: indexPath, cell: cell)
        } else {
            self.deselectRow(at: indexPath, cell: cell)
        }
        
        return cell
    }
    
    func selectRow(at indexPath: IndexPath, cell: ContactGroupEditViewCell) {
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        cell.setSelected(true, animated: true)
        viewModel.selectEmail(ID: cell.emailID)
    }
    
    func deselectRow(at indexPath: IndexPath, cell: ContactGroupEditViewCell) {
        tableView.deselectRow(at: indexPath, animated: true)
        cell.setSelected(false, animated: true)
        viewModel.deselectEmail(ID: cell.emailID)
    }
}

extension ContactGroupSelectEmailViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? ContactGroupEditViewCell {
            self.selectRow(at: indexPath, cell: cell)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? ContactGroupEditViewCell {
            self.deselectRow(at: indexPath, cell: cell)
        }
    }
}
