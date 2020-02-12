//
//  ReportBugsViewController.swift
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


import Foundation
import MBProgressHUD

class AccountManagerViewController: ProtonMailViewController, ViewModelProtocol, CoordinatedNew {
    private var viewModel : AccountManagerViewModel!
    private var coordinator : AccountManagerCoordinator?
    
    private let kMenuCellHeight: CGFloat = 44.0
    private let kUserCellHeight: CGFloat = 60.0
    
    func set(viewModel: AccountManagerViewModel) {
        self.viewModel = viewModel
    }
    func set(coordinator: AccountManagerCoordinator) {
        self.coordinator = coordinator
    }
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
    
    
    // MARK: - View Outlets
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.backgroundColor = UIColor.ProtonMail.TableSeparatorGray
        self.tableView.estimatedSectionFooterHeight = kUserCellHeight
        
        NotificationCenter.default.addObserver(forName: Notification.Name.didObtainMailboxPassword, object: nil, queue: .main) { _ in
            self.navigationController?.popToViewController(self, animated: true)
        }
        
        self.title = LocalString._account

        let cancelButton = UIBarButtonItem(title: LocalString._general_cancel_button, style: .plain, target: self, action: #selector(cancelAction))
        self.navigationItem.leftBarButtonItem = cancelButton
        let removeAllButton = UIBarButtonItem(title: LocalString._remove_all, style: .plain, target: self, action: #selector(removeAction))
        self.navigationItem.rightBarButtonItem = removeAllButton
    }
    
    @objc internal func dismiss() {
        if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func cancelAction(_ sender: UIBarButtonItem) {
        self.dismiss()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Private methods
    
    // MARK: Actions
    
    @IBAction fileprivate func removeAction(_ sender: UIBarButtonItem) {
        //remove all
        let title = "Warning!"
        let message = "You are about to remove all accounts. You will not be able to access them from is device unless you add them again.\nDo you want to remove all your accounts anyway?"
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(.init(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
        alertController.addAction(.init(title: LocalString._remove_all, style: .destructive, handler: { _ in
            self.viewModel.signOut()
            self.dismiss()
        }))
        
        alertController.popoverPresentationController?.barButtonItem = sender
        alertController.popoverPresentationController?.sourceRect = self.view.frame
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource
extension AccountManagerViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.sectionCount()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.rowCount(at: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let s = self.viewModel.section(at: indexPath.section)
        switch s {
        case .users:
            let cell = tableView.dequeueReusableCell(withIdentifier: "account_cell", for: indexPath)
            if let userCell = cell as? AccountManagerUserCell, let user =  self.viewModel.user(at: indexPath.row) {
                userCell.configCell(name: user.defaultDisplayName, email: user.defaultEmail)
            }
            return cell
        case .disconnected:
            let cell = tableView.dequeueReusableCell(withIdentifier: "account_cell", for: indexPath)
            if let userCell = cell as? AccountManagerUserCell, let user =  self.viewModel.handle(at: indexPath.row) {
                userCell.configLoggedOutCell(name: user.defaultDisplayName, email: user.defaultEmail)
            }
            return cell
        case .add:
            let cell = tableView.dequeueReusableCell(withIdentifier: "add_account_cell", for: indexPath)
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        switch self.viewModel.section(at: indexPath.section) {
        case .users where self.viewModel.usersCount > 1:
            return [UITableViewRowAction(style: .destructive, title: LocalString._sign_out) { _, indexPath in
                let title = "Warning!"
                let message = LocalString._logout_confirmation
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(.init(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
                alert.addAction(.init(title: LocalString._sign_out, style: .destructive, handler: { _ in
                    self.viewModel.remove(at: indexPath)
                    self.tableView.reloadData()
                }))
                self.present(alert, animated: true, completion: nil)
            }]
        case .disconnected:
            return [UITableViewRowAction(style: .destructive, title: LocalString._general_delete_action) { _, indexPath in
                let title = "Warning!"
                let message = "By removing this account , you will no longer be able to access it from this device unless you add it again.\nDo you want to remove this account anyway?"
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(.init(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
                alert.addAction(.init(title: LocalString._general_remove_button, style: .destructive, handler: { _ in
                    self.viewModel.remove(at: indexPath)
                    self.tableView.reloadData()
                }))
                self.present(alert, animated: true, completion: nil)
            }]
        
        default:
            return []
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch self.viewModel.section(at: indexPath.section) {
        case .users, .disconnected:
            return kUserCellHeight
        case .add:
            return kMenuCellHeight
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch self.viewModel.section(at: section) {
        case .users, .add:
            return kMenuCellHeight / 2
        default:
            return 0.0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UITableViewHeaderFooterView(reuseIdentifier: "account_spacer")
        view.backgroundColor = UIColor.ProtonMail.TableSeparatorGray
        return view
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard self.viewModel.section(at: section) == .add else { return nil }
        
        let view = UITableViewHeaderFooterView(reuseIdentifier: "account_footer")
        view.backgroundColor = UIColor.ProtonMail.TableSeparatorGray
        
        let label = UILabel(font: .preferredFont(forTextStyle: .footnote),
                            text: self.viewModel.textForFooter,
                            textColor: UIColor.ProtonMail.TableFootnoteTextGray)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        
        view.contentView.addSubview(label)
        label.leadingAnchor.constraint(equalTo: view.contentView.leadingAnchor, constant: 10.0).isActive = true
        label.trailingAnchor.constraint(equalTo: view.contentView.trailingAnchor, constant: 10.0).isActive = true
        label.topAnchor.constraint(equalTo: view.contentView.topAnchor, constant: 10.0).isActive = true
        label.bottomAnchor.constraint(equalTo: view.contentView.bottomAnchor, constant: 10.0).isActive = true
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let s = self.viewModel.section(at: section)
        switch s {
        case .users, .disconnected:
            return 0.5
        case .add:
            return UITableView.automaticDimension
        }
    }
}

extension AccountManagerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.viewModel.section(at: indexPath.section) {
        case .users:
            self.viewModel.activateUser(at: indexPath)
            self.dismiss()
            
        case .disconnected:
            self.coordinator?.go(to: .addAccount, sender: self.viewModel.handle(at: indexPath.row))
            
        case .add:
            self.coordinator?.go(to: .addAccount)
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
}
