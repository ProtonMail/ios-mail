//
//  HelpViewController.swift
//  ProtonCore-Login - Created on 04/11/2020.
//
//  Copyright (c) 2019 Proton Technologies AG
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

import UIKit
import ProtonCore_CoreTranslation
import ProtonCore_Foundations
import ProtonCore_UIFoundations

protocol HelpViewControllerDelegate: AnyObject {
    func userDidDismissHelpViewController()
    func userDidRequestHelp(item: HelpItem)
}

final class HelpViewController: UIViewController, AccessibleView {

    // MARK: - Outlets

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var closeButton: UIButton!

    // MARK: - Properties

    weak var delegate: HelpViewControllerDelegate?
    var viewModel: HelpViewModel!
    
    override var preferredStatusBarStyle: UIStatusBarStyle { darkModeAwarePreferredStatusBarStyle() }

    // MARK: - Setup

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupTableView()
        generateAccessibilityIdentifiers()
    }

    private func setupUI() {
        view.backgroundColor = ColorProvider.BackgroundNorm
        tableView.backgroundColor = ColorProvider.BackgroundNorm
        titleLabel.textColor = ColorProvider.TextNorm
        closeButton.setImage(IconProvider.crossSmall, for: .normal)
        closeButton.tintColor = ColorProvider.IconNorm
        titleLabel.text = CoreString._ls_help_screen_title
    }

    private func setupTableView() {
        tableView.register(PMCell.nib, forCellReuseIdentifier: PMCell.reuseIdentifier)
        tableView.register(PMTitleCell.nib, forCellReuseIdentifier: PMTitleCell.reuseIdentifier)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.reloadData()
    }

    // MARK: - Actions

    @IBAction private func closePressed(_ sender: Any) {
        delegate?.userDidDismissHelpViewController()
    }
}

// MARK: - Table view delegates

extension HelpViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.helpSections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.helpSections[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let helpItem = viewModel.helpSections[indexPath.section][indexPath.row]
        switch helpItem {
        case .staticText(let text):
            let cell = tableView.dequeueReusableCell(withIdentifier: PMTitleCell.reuseIdentifier,
                                                     for: indexPath) as! PMTitleCell
            cell.title = text
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: PMCell.reuseIdentifier,
                                                     for: indexPath) as! PMCell
            cell.configure(item: helpItem)
            return cell
        }
    }
}

extension HelpViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let helpItem = viewModel.helpSections[indexPath.section][indexPath.row]
        delegate?.userDidRequestHelp(item: helpItem)
    }
}
