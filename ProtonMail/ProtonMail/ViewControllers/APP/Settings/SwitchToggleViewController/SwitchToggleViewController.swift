// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import MBProgressHUD
import ProtonCore_UIFoundations
import UIKit

final class SwitchToggleViewController: UITableViewController {

    private let viewModel: SwitchToggleVMProtocol

    init(viewModel: SwitchToggleVMProtocol) {
        self.viewModel = viewModel
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.output.sectionNumber
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.output.rowNumber
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = SwitchTableViewCell.reuseIdentifier
        guard let cell = tableView
            .dequeueReusableCell(withIdentifier: id, for: indexPath) as? SwitchTableViewCell else {
            return UITableViewCell()
        }
        guard let item = viewModel.output.cellData(for: indexPath) else {
            fatalError("Should have data")
        }
        cell.configCell(item.title, isOn: item.status) { [weak self] newStatus, feedback in
            self?.showLoading(shouldShow: true)
            self?.viewModel.input.toggle(for: indexPath, to: newStatus) { error in
                self?.showLoading(shouldShow: false)
                error?.alertToast()
                let isSuccess = error == nil
                feedback(isSuccess)
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let title = viewModel.output.sectionHeader(of: section)
        return title == nil ? 36 : UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let text = viewModel.output.sectionHeader(of: section) else {
            return nil
        }
        let padding = viewModel.output.headerTopPadding
        return getHeaderFooterView(text: text, titleTopPadding: padding)
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let desc = viewModel.output.sectionFooter(of: section)
        return desc == nil ? 36 : UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let text = viewModel.output.sectionFooter(of: section) else {
            return nil
        }
        let padding = viewModel.output.footerTopPadding
        return getHeaderFooterView(text: text, titleTopPadding: padding)
    }
}

extension SwitchToggleViewController {
    private func setUpUI() {
        title = viewModel.output.title
        setUpTableView()
    }

    private func setUpTableView() {
        tableView.backgroundView = nil
        tableView.backgroundColor = ColorProvider.BackgroundSecondary
        tableView.register(SwitchTableViewCell.defaultNib(),
                           forCellReuseIdentifier: SwitchTableViewCell.reuseIdentifier)
        tableView.register(UITableViewHeaderFooterView.self,
                           forHeaderFooterViewReuseIdentifier: UITableViewHeaderFooterView.reuseIdentifier)
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 36.0
        tableView.estimatedSectionFooterHeight = 36.0
        tableView.separatorInset = .zero
    }

    private func getHeaderFooterView(text: String, titleTopPadding: CGFloat) -> UIView? {
        let id = UITableViewHeaderFooterView.reuseIdentifier
        guard let hfView = tableView
            .dequeueReusableHeaderFooterView(withIdentifier: id) else {
            return nil
        }
        hfView.contentView.backgroundColor = ColorProvider.BackgroundSecondary
        hfView.contentView.subviews.forEach { $0.removeFromSuperview() }

        let textLabel = UILabel()
        textLabel.set(text: text,
                      preferredFont: .footnote,
                      textColor: ColorProvider.TextWeak)
        textLabel.numberOfLines = 0
        hfView.contentView.addSubview(textLabel)

        [
            textLabel.topAnchor.constraint(equalTo: hfView.contentView.topAnchor, constant: titleTopPadding),
            textLabel.bottomAnchor.constraint(equalTo: hfView.contentView.bottomAnchor, constant: -8),
            textLabel.leftAnchor.constraint(equalTo: hfView.contentView.leftAnchor, constant: 16),
            textLabel.rightAnchor.constraint(equalTo: hfView.contentView.rightAnchor, constant: -16)
        ].activate()
        return hfView
    }

    private func showLoading(shouldShow: Bool) {
        let view = UIApplication.shared.keyWindow ?? UIView()
        if shouldShow {
            MBProgressHUD.showAdded(to: view, animated: true)
        }
        MBProgressHUD.hide(for: view, animated: true)
    }
}
