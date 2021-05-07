//
//  HelpViewController.swift
//  ProtonMail - Created on 2/1/16.
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

#if canImport(UIKit)
import UIKit
import PMUIFoundations
import PMCoreTranslation

protocol HelpViewControllerDelegate: class {
    func didDismissHelpViewController()
}

public class HelpViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var closeBarButtonItem: UIBarButtonItem!

    weak var delegate: HelpViewControllerDelegate?
    var viewModel: HelpViewModel!

    // MARK: - View controller life cycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(PMCell.nib, forCellReuseIdentifier: PMCell.reuseIdentifier)
        configureUI()
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.default
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.zeroMargin()
    }

    // MARK: - Actions

    @IBAction func closeAction(_ sender: UIBarButtonItem) {
        delegate?.didDismissHelpViewController()
    }

    // MARK: - Private Interface

    private func configureUI() {
        closeBarButtonItem.tintColor = UIColorManager.IconNorm
        view.backgroundColor = UIColorManager.BackgroundNorm
        tableView.backgroundColor = UIColorManager.BackgroundNorm
        title = CoreString._hv_help_button
        tableView.noSeparatorsBelowFooter()
        headerLabel.textColor = UIColorManager.TextWeak
        headerLabel.text = CoreString._hv_help_header
    }

}

// MARK: - UITableViewDataSource

extension HelpViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.helpMenuItems.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PMCell.reuseIdentifier, for: indexPath) as! PMCell
        cell.selectionStyle = .default
        let item = viewModel.helpMenuItems[indexPath.row]
        cell.icon = item.image
        cell.title = item.title
        cell.subtitle = item.subtitle
        return cell
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.zeroMargin()
    }
}

// MARK: - UITableViewDelegate

extension HelpViewController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = viewModel.helpMenuItems[indexPath.row]
        guard let url = item.url else { return }
        UIApplication.shared.open(url)
    }
}

#endif
