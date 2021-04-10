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

import PMUIFoundations
import UIKit

class SettingsGesturesViewController: ProtonMailViewController, ViewModelProtocol, CoordinatedNew {
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var infoIconImage: UIImageView!
    @IBOutlet private var topInfoTitle: UILabel!

    private var viewModel: SettingsGestureViewModel!
    private var coordinator: SettingsGesturesCoordinator?

    private(set) var selectedAction: SwipeActionItems?

    private var actionSheet: PMActionSheet?

    func set(viewModel: SettingsGestureViewModel) {
        self.viewModel = viewModel
    }

    func set(coordinator: SettingsGesturesCoordinator) {
        self.coordinator = coordinator
    }

    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }

    enum CellKey {
        static let cellHeight: CGFloat = 48.0
        static let displayCellHeight: CGFloat = 142.0
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateTitle()
        self.tableView.register(SettingsGeneralCell.self)
        self.tableView.register(SwipeActionLeftToRightTableViewCell.self)
        self.tableView.register(SwipeActionRightToLeftTableViewCell.self)
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .none

        precondition(viewModel != nil)
        precondition(coordinator != nil)

        self.view.backgroundColor = UIColorManager.BackgroundNorm
        self.infoIconImage.image = Asset.infoIcon.image
        self.infoIconImage.tintColor = UIColorManager.TextWeak
        self.topInfoTitle.attributedText = LocalString._setting_swipe_action_info_title
            .apply(style: FontManager.CaptionWeak)

        self.setupDismissButton()
        self.configureNavigationBar()
        self.setupDoneButton()

        let backItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backItem
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        self.tableView.reloadData()
    }

    private func setupDoneButton() {
        let doneBtn = UIBarButtonItem(title: LocalString._general_done_button,
                                      style: .plain,
                                      target: self,
                                      action: #selector(self.dismissView))
        doneBtn.tintColor = UIColorManager.InteractionNorm
        navigationItem.rightBarButtonItem = doneBtn
    }

    private func setupDismissButton() {
        let dismissBtn = Asset.actionSheetClose.image
            .toUIBarButtonItem(target: self,
                               action: #selector(self.dismissView),
                               style: .done,
                               tintColor: UIColorManager.TextNorm,
                               squareSize: 24,
                               backgroundColor: nil,
                               backgroundSquareSize: nil,
                               isRound: nil)
        navigationItem.leftBarButtonItem = dismissBtn
    }

    private func updateTitle() {
        self.title = LocalString._settings_swiping_gestures
    }

    private func showSwipeActionList(selected: SwipeActionItems) {
        self.selectedAction = selected
        self.coordinator?.go(to: .actionSelection)
    }

    private func hideActionSheet() {
        self.actionSheet?.dismiss(animated: true)
        self.actionSheet = nil
    }

    @objc
    private func dismissView() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}

extension SettingsGesturesViewController: UITableViewDelegate, UITableViewDataSource {
    // MARK: - table view delegate

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.settingSwipeActionItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.viewModel.settingSwipeActionItems[indexPath.row]
        switch item {
        case .left, .right:
            if let cell = tableView.dequeueReusableCell(withIdentifier: SettingsGeneralCell.CellID,
                                                        for: indexPath) as? SettingsGeneralCell
            {
                cell.backgroundColor = UIColorManager.BackgroundNorm
                cell.addSeparator(padding: 0)
                switch item {
                case .left:
                    cell.configureCell(left: LocalString._swipe_left_to_right,
                                       right: self.viewModel.leftToRightAction.selectionTitle,
                                       imageType: .arrow)
                case .right:
                    cell.configureCell(left: LocalString._swipe_right_to_left,
                                       right: self.viewModel.rightToLeftAction.selectionTitle,
                                       imageType: .arrow)
                default:
                    break
                }
                return cell
            }
        case .empty:
            let cell = UITableViewCell()
            cell.selectionStyle = .none
            return cell
        case .leftActionView:
            if let cell = tableView.dequeueReusableCell(withIdentifier: SwipeActionLeftToRightTableViewCell.CellID, for: indexPath) as? SwipeActionLeftToRightTableViewCell {
                cell.selectionStyle = .none
                let action = self.viewModel.leftToRightAction
                cell.configure(icon: action.actionDisplayIcon, title: action.actionDisplayTitle, color: action.actionColor, shouldHideIcon: action == .none)
                return cell
            }
        case .rightActionView:
            if let cell = tableView.dequeueReusableCell(withIdentifier: SwipeActionRightToLeftTableViewCell.CellID, for: indexPath) as? SwipeActionRightToLeftTableViewCell {
                cell.selectionStyle = .none
                let action = self.viewModel.rightToLeftAction
                cell.configure(icon: action.actionDisplayIcon, title: action.actionDisplayTitle, color: action.actionColor, shouldHideIcon: action == .none)
                return cell
            }
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = self.viewModel.settingSwipeActionItems[indexPath.row]
        switch item {
        case .left, .right, .empty:
            return CellKey.cellHeight
        case .leftActionView, .rightActionView:
            return CellKey.displayCellHeight
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let actionItem = self.viewModel.settingSwipeActionItems[indexPath.row]
        guard actionItem == .left || actionItem == .right else {
            return
        }
        self.showSwipeActionList(selected: actionItem)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension SettingsGesturesViewController: Deeplinkable {
    var deeplinkNode: DeepLink.Node {
        return DeepLink.Node(name: String(describing: SettingsGesturesViewController.self), value: nil)
    }
}
