// Copyright (c) 2023 Proton Technologies AG
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

import ProtonCore_Foundations
import ProtonCore_UIFoundations
import UIKit

final class SettingsLocalStorageViewController: UITableViewController, AccessibleView {
    private let viewModel: SettingsLocalStorageViewModelProtocol

    private enum Layout {
        static let estimatedCellHeight: CGFloat = 48.0
        static let estimatedFooterHeight: CGFloat = 48.0
        static let firstSectionHeaderHeight: CGFloat = 32.0
        static let separationBetweenSections: CGFloat = 8.0
    }

    init(viewModel: SettingsLocalStorageViewModelProtocol) {
        self.viewModel = viewModel
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        viewModel.output.setUIDelegate(self)
    }

    private func setUpUI() {
        emptyBackButtonTitleForNextView()
        title = LocalString._settings_title_of_local_storage
        view.backgroundColor = ColorProvider.BackgroundSecondary
        view.frame = CGRect(origin: .zero, size: UIScreen.main.bounds.size)

        tableView.register(cellType: DownloadedMessagesInfoCell.self)
        tableView.register(cellType: LocalStorageCell.self)
        tableView.register(viewType: SettingsTextFooterView.self)

        tableView.estimatedSectionFooterHeight = Layout.estimatedFooterHeight
        tableView.estimatedRowHeight = Layout.estimatedCellHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delaysContentTouches = false
    }
}

// MARK: UITableViewDataSource

extension SettingsLocalStorageViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.output.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewModel.output.sections[indexPath.section] {
        case .cachedData:
            return cellForCachedDataStorage()
        case .attachments:
            return cellForAttachmentsStorage()
        case .downloadedMessages:
            return cellForDownloadedMessages()
        }
    }

    private func cellForCachedDataStorage() -> LocalStorageCell {
        let cell = tableView.dequeue(cellType: LocalStorageCell.self)
        cell.delegate = self
        cell.selectionStyle = .none
        cell.tag = SettingsLocalStorageSection.cachedData.rawValue
        cell.configure(
            info: .init(
                title: LocalString._settings_title_of_cached_data,
                message: LocalString._settings_local_storage_cached_data_text,
                localStorageUsed: viewModel.output.cachedDataStorage,
                isClearButtonHidden: false
            )
        )
        return cell
    }

    private func cellForAttachmentsStorage() -> LocalStorageCell {
        let cell = tableView.dequeue(cellType: LocalStorageCell.self)
        cell.delegate = self
        cell.selectionStyle = .none
        cell.tag = SettingsLocalStorageSection.attachments.rawValue
        cell.configure(
            info: .init(
                title: LocalString._settings_title_of_attachments,
                message: LocalString._settings_local_storage_attachments_text,
                localStorageUsed: viewModel.output.attachmentsStorage,
                isClearButtonHidden: false
            )
        )
        return cell
    }

    private func cellForDownloadedMessages() -> DownloadedMessagesInfoCell {
        let cell = tableView.dequeue(cellType: DownloadedMessagesInfoCell.self)
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .gray
        cell.configure(info: .storage(viewModel.output.downloadedMessagesStorage))
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch viewModel.output.sections[section] {
        case .cachedData:
            return Layout.firstSectionHeaderHeight
        case .attachments, .downloadedMessages:
            return .leastNormalMagnitude
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch viewModel.output.sections[section] {
        case .cachedData, .attachments:
            return UIView()
        case .downloadedMessages:
            let footer = tableView.dequeue(viewType: SettingsTextFooterView.self)
            footer.set(text: LocalString._settings_foot_of_downloaded_messages_local_storage)
            return footer
        }
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch viewModel.output.sections[section] {
        case .cachedData, .attachments:
            return Layout.separationBetweenSections
        case .downloadedMessages:
            return UITableView.automaticDimension
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if viewModel.output.sections[indexPath.section] == .downloadedMessages {
            viewModel.input.didTapDownloadedMessages()
        }
    }
}

extension SettingsLocalStorageViewController: SettingsLocalStorageUIProtocol {

    func reloadData() {
        tableView.reloadData()
    }
}

extension SettingsLocalStorageViewController: LocalStorageCellDelegate {

    func didTapClear(sender: LocalStorageCell) {
        switch SettingsLocalStorageSection(rawValue: sender.tag) {
        case .cachedData:
            viewModel.input.didTapClearData()
        case .attachments:
            viewModel.input.didTapClearAttachments()
        case .none, .downloadedMessages:
            break
        }
    }
}
