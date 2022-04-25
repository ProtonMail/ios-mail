//
//  NetworkTroubleShootViewController.swift
//  ProtonMail - Created on 3/01/2020.
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

import MessageUI
import ProtonCore_UIFoundations
import UIKit

class NetworkTroubleShootViewController: UITableViewController, AccessibleView {
    private var viewModel: NetworkTroubleShootViewModel

    enum ID {
        static var headerCell = "header_cell"
        static var headerHeight: CGFloat = 30.0
    }

    var onDismiss: () -> Void = {}

    init(viewModel: NetworkTroubleShootViewModel) {
        self.viewModel = viewModel
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateTitle()
        self.tableView.register(UINib(nibName: "SwitchTwolineCell", bundle: nil), forCellReuseIdentifier: SwitchTwolineCell.CellID)
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: ID.headerCell)
        self.tableView.estimatedSectionHeaderHeight = ID.headerHeight
        self.tableView.sectionHeaderHeight = UITableView.automaticDimension
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.noSeparatorsBelowFooter()

        let newBackButton = UIBarButtonItem(title: LocalString._general_back_action,
                                            style: UIBarButtonItem.Style.plain,
                                            target: self,
                                            action: #selector(NetworkTroubleShootViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton
        generateAccessibilityIdentifiers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    @objc
    private func back(sender: UIBarButtonItem) {
        if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: self.onDismiss)
        } else {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }

    private func updateTitle() {
        self.title = viewModel.title
    }

    // MARK: - table view delegates
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.viewModel.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTwolineCell.CellID, for: indexPath)
        cell.accessoryType = .none
        cell.selectionStyle = .none
        guard let switchCell = cell as? SwitchTwolineCell else {
            return cell
        }
        switch item {
        case .allowSwitch:
            switchCell.configCell(item.top, bottomLine: item.attributedString, showSwitcher: true, status: true) { [weak self] _, newStatus, _ in
                self?.viewModel.dohStatus = newStatus ? .on : .off
            }
        default:
            switchCell.delegate = self
            switchCell.configCell(item.top, bottomLine: item.attributedString, showSwitcher: false, status: false) { _, _, _ in
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 8
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension NetworkTroubleShootViewController: SwitchTwolineCellDelegate, MFMailComposeViewControllerDelegate {
    func mailto() {
        self.openMFMail()
    }

    func openMFMail() {
        let mailComposer = MFMailComposeViewController()
        mailComposer.setToRecipients(["support@protonmail.zendesk.com"])
        mailComposer.setSubject(LocalString._troubleshoot_support_subject)
        mailComposer.setMessageBody(LocalString._troubleshoot_support_body, isHTML: false)
        present(mailComposer, animated: true, completion: nil)
    }
}
