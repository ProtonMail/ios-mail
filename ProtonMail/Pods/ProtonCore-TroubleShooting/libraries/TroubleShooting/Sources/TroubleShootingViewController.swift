//
//  TroubleShootingViewController.swift
//  ProtonCore-TroubleShooting - Created on 08/20/2020
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.
//

import UIKit
import MessageUI
import ProtonCore_Foundations
import ProtonCore_UIFoundations
import ProtonCore_CoreTranslation

public typealias OnDismissComplete = () -> Void

public class TroubleShootingViewController: UITableViewController, AccessibleView {
    private var viewModel: TroubleShootingViewModel

    enum ID {
        static var headerCell = "trouble_shooting_header_cell"
        static var headerHeight: CGFloat = 30.0
    }

    var onDismiss: OnDismissComplete = {}

    public init(viewModel: TroubleShootingViewModel) {
        self.viewModel = viewModel
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.updateTitle()
        self.tableView.register(UINib(nibName: "TroubleShootingCell", bundle: TSCommon.bundle),
                                forCellReuseIdentifier: TroubleShootingCell.CellID)
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: ID.headerCell)
        self.tableView.estimatedSectionHeaderHeight = ID.headerHeight
        self.tableView.sectionHeaderHeight = UITableView.automaticDimension
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)

        let newBackButton = UIBarButtonItem(title: CoreString._general_back_action,
                                            style: UIBarButtonItem.Style.plain,
                                            target: self,
                                            action: #selector(TroubleShootingViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton
        generateAccessibilityIdentifiers()
    }

    override public func viewWillAppear(_ animated: Bool) {
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
    override public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.items.count
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.viewModel.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: TroubleShootingCell.CellID, for: indexPath)
        cell.accessoryType = .none
        cell.selectionStyle = .none
        guard let switchCell = cell as? TroubleShootingCell else {
            return cell
        }
        switch item {
        case .allowSwitch:
            switchCell.configCell(item.top, bottomLine: item.attributedString,
                                  showSwitcher: true, status: viewModel.dohStatus == .on) { [weak self] _, newStatus, _ in
                self?.viewModel.dohStatus = newStatus ? .on : .off
            }
        default:
            switchCell.delegate = self
            switchCell.configCell(item.top, bottomLine: item.attributedString,
                                  showSwitcher: false, status: false) { _, _, _ in
            }
        }
        return cell
    }

    override public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    override public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 8
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension TroubleShootingViewController: TroubleShootingCellDelegate, MFMailComposeViewControllerDelegate {
    func mailto(email: String) {
        self.openMFMail(email: email)
    }
    
    func openMFMail(email: String) {
        let mailComposer = MFMailComposeViewController()
        mailComposer.setToRecipients([email])
        mailComposer.setSubject(CoreString._troubleshoot_support_subject)
        mailComposer.setMessageBody(CoreString._troubleshoot_support_body, isHTML: false)
        present(mailComposer, animated: true, completion: nil)
    }
}
