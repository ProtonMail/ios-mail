//
//  AppVersionDebugViewController.swift
//  ProtonMail
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

import UIKit
import PMUIFoundations

final class AppVersionDebugViewController: ProtonMailTableViewController {
    struct Key {
        static let headerCell = "header_cell"
        static let headerCellHeight: CGFloat = 36.0
    }
    private let viewModel : AppVersionDebugViewModel

    init(viewModel: AppVersionDebugViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Please use init(viewModel:) instead")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor  = UIColor(hexColorCode: "#E2E6E8")
        self.title = LocalString._app_information
        
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.headerCell)
        self.tableView.register(SettingsGeneralCell.self)
        
        self.tableView.estimatedRowHeight = 50.0
        self.tableView.rowHeight = UITableView.automaticDimension

        self.tableView.tableFooterView = RegisterAgainFooter(target: self, action: #selector(shouldRegisterForNotification))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let tableFooterView = tableView.tableFooterView else {
            return
        }
        let width = tableView.bounds.size.width
        let size = tableFooterView.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height))
        if tableFooterView.frame.size.height != size.height {
            tableFooterView.frame.size.height = size.height
            tableView.tableFooterView = tableFooterView
        }
    }

    @objc func shouldRegisterForNotification() {
        let footerView = tableView.tableFooterView as? RegisterAgainFooter
        footerView?.registerAgainButton.isEnabled = false
        viewModel.registerAgainForNotifications()
        delay(1.0) {
            LocalString._push_registration_confirmation.alertToastBottom()
            footerView?.registerAgainButton.isEnabled = true
        }
    }
}

extension AppVersionDebugViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let viewModelSection = viewModel.sections[section]

        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsGeneralCell.CellID, for: indexPath)
        cell.accessoryType = .none
        if let c = cell as? SettingsGeneralCell {
            c.config(left: viewModel.rowDescription(for: viewModelSection))
            c.config(right: viewModel.rowValue(for: viewModelSection))
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: Key.headerCell)
        header?.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        if let headerCell = header {
            let textLabel = UILabel()
            
            textLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
            textLabel.adjustsFontForContentSizeCategory = true
            textLabel.textColor = UIColor.ProtonMail.Gray_8E8E8E
            let vmSection = self.viewModel.sections[section]
            textLabel.text = viewModel.sectionName(for: vmSection)
            
            headerCell.contentView.addSubview(textLabel)
            
            textLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                textLabel.topAnchor.constraint(equalTo: headerCell.contentView.topAnchor, constant: 8),
                textLabel.bottomAnchor.constraint(equalTo: headerCell.contentView.bottomAnchor, constant: -8),
                textLabel.leftAnchor.constraint(equalTo: headerCell.contentView.leftAnchor, constant: 8),
                textLabel.rightAnchor.constraint(equalTo: headerCell.contentView.rightAnchor, constant: -8)
            ])
        }
        return header
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return Key.headerCellHeight
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        false
    }
}

final class RegisterAgainFooter: UIView {
    let registerAgainButton = UIButton()

    init(target: Any, action: Selector) {
        super.init(frame: .zero)
        registerAgainButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(registerAgainButton)
        NSLayoutConstraint.activate([
            registerAgainButton.heightAnchor.constraint(equalToConstant: 30),
            registerAgainButton.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            registerAgainButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            registerAgainButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            registerAgainButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
        var regularAttributes = [NSAttributedString.Key: Any]()
        regularAttributes[.font] = UIFont.preferredFont(forTextStyle: .caption1)
        regularAttributes[.foregroundColor] = UIColorManager.TextNorm
        let attributedString = NSAttributedString(string: LocalString._register_again_for_push, attributes: regularAttributes)

        registerAgainButton.setAttributedTitle(attributedString, for: .normal)
        let colorImage = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in
            UIColorManager.BackgroundNorm.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: 1, height: 1)).fill()
        }
        registerAgainButton.setBackgroundImage(colorImage, for: .normal)
        registerAgainButton.roundCorners()
        registerAgainButton.addTarget(target, action: action, for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("Please use init(frame:)")
    }
}
