//
//  SettingsGesturesViewController.swift
//  ProtonMail - Created on 3/17/15.
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


import UIKit
import MBProgressHUD
import PMKeymaker

class SettingsGesturesViewController: UITableViewController, ViewModelProtocol, CoordinatedNew {
    internal var viewModel : SettingsGestureViewModel!
    internal var coordinator : SettingsGesturesCoordinator?
    
    func set(viewModel: SettingsGestureViewModel) {
        self.viewModel = viewModel
    }
    
    func set(coordinator: SettingsGesturesCoordinator) {
        self.coordinator = coordinator
    }
    
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
    
    struct CellKey {
        static let headerCell : String        = "header_cell"
        static let headerCellHeight : CGFloat = 36.0
        static let settingCell : String       = "GeneralSettingViewCell"
        static let cellHeight: CGFloat = 50.0
    }
    
    @IBOutlet var settingTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateTitle()
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: CellKey.headerCell)
        self.tableView.register(UINib(nibName: CellKey.settingCell, bundle: nil), forCellReuseIdentifier: CellKey.settingCell)
        self.tableView.tableFooterView = UIView()
        self.tableView.backgroundColor = UIColor(hexString: "E2E6E8", alpha: 1.0)
    }
    
    private func updateTitle() {
        self.title = LocalString._settings_swiping_gestures
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    ///MARK: -- table view delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.setting_swipe_action_items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: CellKey.settingCell, for: indexPath) as? GeneralSettingViewCell {
            switch self.viewModel.setting_swipe_action_items[indexPath.row] {
            case .left:
                cell.configCell(LocalString._swipe_left_to_right, right: self.viewModel.userInfo.swipeLeftAction.description)
            case .right:
                cell.configCell(LocalString._swipe_right_to_left, right: self.viewModel.userInfo.swipeRightAction.description)
            }
            return cell
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CellKey.cellHeight
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return CellKey.headerCellHeight
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let action_item = self.viewModel.setting_swipe_action_items[indexPath.row]
        let alertController = UIAlertController(title: action_item.actionDescription, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
        let userInfo = self.viewModel.userInfo
        let currentAction = action_item == .left ? userInfo.swipeLeftAction : userInfo.swipeRightAction
        for swipeAction in self.viewModel.setting_swipe_actions {
            if swipeAction != currentAction {
                alertController.addAction(UIAlertAction(title: swipeAction.description, style: .default, handler: { [weak self] (action) -> Void in
                    let view = UIApplication.shared.keyWindow ?? UIView()
                    MBProgressHUD.showAdded(to: view, animated: true)
                    self?.viewModel.updateUserSwipeAction(isLeft: action_item == .left, action: swipeAction) { (_, _, _) in
                        MBProgressHUD.hide(for: view, animated: true)
                        self?.tableView.reloadData()
                    }
                }))
            }
        }
        let cell = tableView.cellForRow(at: indexPath)
        alertController.popoverPresentationController?.sourceView = cell ?? self.view
        alertController.popoverPresentationController?.sourceRect = (cell == nil ? self.view.frame : cell!.bounds)
        present(alertController, animated: true, completion: nil)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: CellKey.headerCell)
        header?.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        if let headerCell = header {
            let textLabel = UILabel()
            
            textLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
            textLabel.adjustsFontForContentSizeCategory = true
            textLabel.textColor = UIColor.ProtonMail.Gray_8E8E8E
            textLabel.text = LocalString._message_swipe_actions
            
            headerCell.contentView.addSubview(textLabel)
            
            textLabel.mas_makeConstraints({ (make) in
                let _ = make?.top.equalTo()(headerCell.contentView.mas_top)?.with()?.offset()(8)
                let _ = make?.bottom.equalTo()(headerCell.contentView.mas_bottom)?.with()?.offset()(-8)
                let _ = make?.left.equalTo()(headerCell.contentView.mas_left)?.with()?.offset()(8)
                let _ = make?.right.equalTo()(headerCell.contentView.mas_right)?.with()?.offset()(-8)
            })
        }
        return header
    }
}

extension SettingsGesturesViewController: Deeplinkable {
    var deeplinkNode: DeepLink.Node {
        return DeepLink.Node(name: String(describing: SettingsGesturesViewController.self), value: nil)
    }
}
