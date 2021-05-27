//
//  SettingsNetworkTableViewController.swift
//  ProtonMail
//
//  Copyright (c) 2021 Proton Technologies AG
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

import ProtonCore_UIFoundations
import UIKit

class SettingsNetworkTableViewController: ProtonMailTableViewController {
    var coordinator: SettingsDeviceCoordinator?
    var viewModel: SettingsNetworkViewModel!

    struct Key {
        static let cellHeight: CGFloat = 48.0
        static let headerCell: String = "header_cell"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateTitle()
        self.view.backgroundColor = UIColorManager.BackgroundSecondary
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.headerCell)
        self.tableView.register(SwitchTableViewCell.self)

        self.tableView.estimatedSectionFooterHeight = 36.0
        self.tableView.sectionFooterHeight = UITableView.automaticDimension

        self.tableView.estimatedSectionHeaderHeight = 36.0
        self.tableView.sectionHeaderHeight = UITableView.automaticDimension

        self.tableView.estimatedRowHeight = Key.cellHeight
        self.tableView.rowHeight = UITableView.automaticDimension
    }

    private func updateTitle() {
        self.title = LocalString._alternative_routing
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.CellID, for: indexPath)
        let item = self.viewModel.sections[indexPath.section]
        if let switchCell = cell as? SwitchTableViewCell {
            switchCell.configCell(item.title, bottomLine: "", status: viewModel.isDohOn) { _, newStatus, _ in
                self.viewModel.setDohStatus(newStatus)
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let eSection = self.viewModel.sections[section]
        guard !eSection.head.isEmpty else {
            return nil
        }

        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: Key.headerCell)
        header?.contentView.backgroundColor = UIColorManager.BackgroundSecondary
        header?.contentView.subviews.forEach { $0.removeFromSuperview() }

        if let headerCell = header {
            let textLabel = UILabel()

            var textAttribute = FontManager.DefaultSmallWeak
            textAttribute.addTextAlignment(.left)
            textLabel.attributedText = NSAttributedString(string: eSection.head, attributes: textAttribute)
            textLabel.translatesAutoresizingMaskIntoConstraints = false

            headerCell.contentView.addSubview(textLabel)

            NSLayoutConstraint.activate([
                textLabel.heightAnchor.constraint(equalToConstant: 20.0),
                textLabel.topAnchor.constraint(equalTo: headerCell.contentView.topAnchor, constant: 24),
                textLabel.bottomAnchor.constraint(equalTo: headerCell.contentView.bottomAnchor, constant: -8),
                textLabel.leftAnchor.constraint(equalTo: headerCell.contentView.leftAnchor, constant: 16),
                textLabel.rightAnchor.constraint(equalTo: headerCell.contentView.rightAnchor, constant: -8)
            ])
        }
        return header
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: Key.headerCell)
        header?.contentView.backgroundColor = UIColorManager.BackgroundSecondary
        header?.contentView.subviews.forEach { $0.removeFromSuperview() }

        if let headerCell = header {
            let textView = UITextView()
            textView.isScrollEnabled = false
            textView.isEditable = false
            textView.backgroundColor = .clear

            let eSection = self.viewModel.sections[section]
            let learnMore = LocalString._settings_alternative_routing_learn
            let full = String.localizedStringWithFormat(eSection.foot, learnMore)

            let attributedString = NSMutableAttributedString(string: full,
                                                             attributes: FontManager.CaptionWeak)
            if let subrange = full.range(of: learnMore) {
                let nsRange = NSRange(subrange, in: full)
                attributedString.addAttribute(.link,
                                              value: Link.alternativeRouting,
                                              range: nsRange)
            }
            textView.attributedText = attributedString
            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.delegate = self

            headerCell.contentView.addSubview(textView)

            NSLayoutConstraint.activate([
                textView.topAnchor.constraint(equalTo: headerCell.contentView.topAnchor, constant: 8),
                textView.bottomAnchor.constraint(equalTo: headerCell.contentView.bottomAnchor, constant: -8),
                textView.leftAnchor.constraint(equalTo: headerCell.contentView.leftAnchor, constant: 13),
                textView.rightAnchor.constraint(equalTo: headerCell.contentView.rightAnchor, constant: -16)
            ])
        }
        return header
    }
}

extension SettingsNetworkTableViewController: UITextViewDelegate {
    func textView(_ textView: UITextView,
                  shouldInteractWith URL: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        guard UIApplication.shared.canOpenURL(URL) else { return false }
        UIApplication.shared.open(URL, options: [:], completionHandler: nil)
        return true
    }
}
