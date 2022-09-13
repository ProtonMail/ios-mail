//
//  LabelParentSelectViewController.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations
import UIKit

final class LabelParentSelectViewController: ProtonMailTableViewController {

    private var viewModel: LabelParentSelctVMProtocol!

    static func instance(hasNavigation: Bool) -> LabelParentSelectViewController {
        let instance = LabelParentSelectViewController(style: .plain)
        if hasNavigation {
            _ = UINavigationController(rootViewController: instance)
        }
        return instance
    }

    func set(viewModel: LabelParentSelctVMProtocol) {
        self.viewModel = viewModel
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(self.viewModel != nil, "Plese use set(viewModel:) to setting")

        self.setupView()
    }

    private func setupView() {
        self.setupNavigationBar()
        self.setupTable()
    }

    private func setupNavigationBar() {
        self.title = LocalString._parent_folder

        let btn = UIBarButtonItem(title: LocalString._general_done_button,
                                  style: .plain,
                                  target: self,
                                  action: #selector(self.clickDoneButton))
        var attr = FontManager.HeadlineSmall
        let foregroundColorOverride: UIColor = ColorProvider.InteractionNorm
        attr[.foregroundColor] = foregroundColorOverride
        btn.setTitleTextAttributes(attr, for: .normal)
        self.navigationItem.rightBarButtonItem = btn
    }

    private func setupTable() {
        self.tableView.tableFooterView = UIView(frame: .zero)
        self.tableView.register(MenuItemTableViewCell.defaultNib(),
                                forCellReuseIdentifier: MenuItemTableViewCell.defaultID())
        self.tableView.register(UITableViewCell.self)
    }

    @objc
    private func clickDoneButton() {
        self.viewModel.finishSelect()
        self.navigationController?.popViewController(animated: true)
    }
}

extension LabelParentSelectViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.labels.getNumberOfRows() + 1
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return self.setupNoneCell()
        }
        return self.setupFolderCell(indexPath: indexPath)
    }

    private func setupNoneCell() -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }

        guard let cellInstance = cell else { return .init() }

        cellInstance.textLabel?.text = LocalString._general_none
        cellInstance.textLabel?.textColor = ColorProvider.TextNorm
        cellInstance.accessoryType = self.viewModel.parentID.isEmpty ? .checkmark : .none
        cellInstance.selectionStyle = .none
        cellInstance.addSeparator(padding: 0)
        return cellInstance
    }

    private func setupFolderCell(indexPath: IndexPath) -> MenuItemTableViewCell {
        guard let cell = self.tableView
                .dequeueReusableCell(withIdentifier: MenuItemTableViewCell.defaultID(),
                                     for: indexPath) as? MenuItemTableViewCell else {
            return .init()
        }
        let path = IndexPath(row: indexPath.row - 1, section: 0)
        guard let label = self.viewModel.labels.getFolderItem(by: path) else {
            return .init()
        }
        cell.config(by: label, showArrow: false, useFillIcon: self.viewModel.useFolderColor, delegate: nil)
        if self.viewModel.isAllowToSelect(row: indexPath.row) {
            cell.update(textColor: ColorProvider.TextNorm)
            cell.update(iconColor: self.viewModel.getFolderColor(label: label))
        } else {
            cell.update(textColor: ColorProvider.TextDisabled)
            cell.update(iconColor: self.viewModel.getFolderColor(label: label), alpha: 0.4)
        }
        cell.update(badge: 0)
        let isParent = label.location.rawLabelID == self.viewModel.parentID
        cell.accessoryType = isParent ? .checkmark : .none
        cell.addSeparator(padding: 0)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard self.viewModel.isAllowToSelect(row: indexPath.row) else {
            return
        }

        let parentID = self.viewModel.parentID
        let row = parentID.isEmpty ? 0 : (self.viewModel.labels.getRow(of: LabelID(parentID)) ?? 0) + 1
        let previous = IndexPath(row: row, section: 0)
        let cell = tableView.cellForRow(at: previous)
        cell?.accessoryType = .none

        let newCell = tableView.cellForRow(at: indexPath)
        newCell?.accessoryType = .checkmark
        self.viewModel.selectRow(row: indexPath.row)
    }
}
