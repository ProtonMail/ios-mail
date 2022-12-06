// Copyright (c) 2022 Proton AG
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

import Foundation
import LifetimeTracker
import ProtonCore_UIFoundations
import UIKit

final class ToolbarCustomizeViewController<T: ToolbarAction>: UIViewController, UITableViewDataSource,
    UITableViewDelegate,
    LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }

    lazy var customView = ToolbarCustomizeView()
    let viewModel: ToolbarCustomizeViewModel<T>
    var customizationIsDone: (([T]) -> Void)?
    private let shouldHideInfoView: Bool

    init(viewModel: ToolbarCustomizeViewModel<T>,
         shouldHideInfoView: Bool = false) {
        self.viewModel = viewModel
        self.shouldHideInfoView = shouldHideInfoView
        super.init(nibName: nil, bundle: nil)
        trackLifetime()
        customView.tableView.backgroundColor = ColorProvider.BackgroundSecondary
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalString._toolbar_customize_general_title

        setupNavigationBarItems()
        setupTableView()

        if viewModel.shouldShowInfoBubbleView {
            customView.addInfoBubbleView { [weak self] in
                self?.viewModel.hideInfoBubbleView()
            }
        }

        viewModel.reloadTableView = { [weak self] in
            self?.customView.tableView.reloadData()
        }

        if shouldHideInfoView {
            customView.dismissInfoBubbleView()
        }
    }

    private func setupNavigationBarItems() {
        let done = UIBarButtonItem(title: LocalString._general_done_button,
                                   style: .plain,
                                   target: self,
                                   action: #selector(doneButtonIsTapped))
        done.tintColor = ColorProvider.BrandNorm
        let close = UIBarButtonItem(image: IconProvider.cross,
                                    style: .plain,
                                    target: self,
                                    action: #selector(closeButtonIsTapped))
        close.tintColor = ColorProvider.IconNorm
        navigationItem.rightBarButtonItem = done
        navigationItem.leftBarButtonItem = close
    }

    private func setupTableView() {
        customView.tableView.delegate = self
        customView.tableView.dataSource = self
        customView.tableView.setEditing(true, animated: false)
        customView.tableView.register(ToolbarCustomizeCell.self, forCellReuseIdentifier: ToolbarCustomizeCell.reuseID)
        customView.resetButton.addTarget(self, action: #selector(resetActions), for: .touchUpInside)
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0:
            return buildSectionHeaderView(title: LocalString._toolbar_customize_header_title_of_first_section)
        case 1:
            return buildSectionHeaderView(title: LocalString._toolbar_customize_header_title_of_second_section)
        default:
            return nil
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsInSection(section: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ToolbarCustomizeCell.reuseID
        ) as? ToolbarCustomizeCell else {
            return UITableViewCell()
        }
        if let action = viewModel.toolbarAction(at: indexPath) {
            let cellIsEnable = viewModel.cellIsEnable(at: indexPath)
            let actionOfCell: ToolbarCustomizeCell.Action = viewModel.isAnSelectedAction(of: action) ? .remove : .insert
            cell.configure(toolbarAction: action,
                           action: actionOfCell,
                           indexPath: indexPath,
                           enable: cellIsEnable)
            cell.delegate = self
        }
        return cell
    }

    func tableView(
        _ tableView: UITableView,
        editingStyleForRowAt indexPath: IndexPath
    ) -> UITableViewCell.EditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        viewModel.moveAction(from: sourceIndexPath, to: destinationIndexPath)
    }

    func tableView(_ tableView: UITableView,
                   targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
                   toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if proposedDestinationIndexPath.section != 0 {
            return sourceIndexPath
        } else {
            return proposedDestinationIndexPath
        }
    }

    // MARK: - Actions

    @objc
    private func doneButtonIsTapped() {
        customizationIsDone?(viewModel.currentActions)
        dismiss(animated: true)
    }

    @objc
    private func closeButtonIsTapped() {
        dismiss(animated: true)
    }

    @objc
    private func resetActions() {
        let alert = UIAlertController(title: viewModel.alertTitle,
                                      message: viewModel.alertContent,
                                      preferredStyle: .alert)
        alert.addCancelAction(handler: nil)
        let resetAction = UIAlertAction(
            title: LocalString._general_confirm_action,
            style: .default
        ) { [weak self] _ in
            self?.viewModel.resetActionsToDefault()
        }
        alert.addAction(resetAction)
        present(alert, animated: true, completion: nil)
    }
}

extension ToolbarCustomizeViewController: ToolbarCustomizeCellDelegate {
    func handleAction(action: ToolbarCustomizeCell.Action, indexPath: IndexPath) {
        viewModel.handleCellAction(action: action, indexPath: indexPath)
    }
}

extension ToolbarCustomizeViewController {
    private func buildSectionHeaderView(title: String) -> UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.BackgroundNorm
        var attribute = FontManager.DefaultSmallWeak
        attribute[.font] = UIFont.adjustedFont(forTextStyle: .subheadline)
        let label = UILabel(attributedString: title.apply(style: attribute))
        view.addSubview(label)
        [
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ].activate()
        return view
    }
}
