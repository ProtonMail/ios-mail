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

import Foundation
import ProtonCore_Foundations
import ProtonCore_UIFoundations
import UIKit

final class SettingsEncryptedSearchViewController: UITableViewController, AccessibleView {
    private let viewModel: SettingsEncryptedSearchViewModelProtocol
    private weak var downloadProgressCell: EncryptedSearchDownloadProgressCell?

    private enum Layout {
        static let estimatedCellHeight: CGFloat = 48.0
        static let estimatedFooterHeight: CGFloat = 48.0
    }

    init(viewModel: SettingsEncryptedSearchViewModelProtocol) {
        self.viewModel = viewModel
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewModel.output.setUIDelegate(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.input.viewWillAppear()
    }

    private func setupUI() {
        emptyBackButtonTitleForNextView()
        title = L11n.EncryptedSearch.cell_title
        view.backgroundColor = ColorProvider.BackgroundSecondary
        view.frame = CGRect(origin: .zero, size: UIScreen.main.bounds.size)

        tableView.register(SwitchTableViewCell.self)
        tableView.register(viewType: SettingsTextFooterView.self)
        tableView.register(cellType: EncryptedSearchDownloadProgressCell.self)
        tableView.register(cellType: EncryptedSearchDownloadedMessagesCell.self)
        tableView.register(viewType: EncryptedSearchBannerFooterView.self)

        tableView.estimatedSectionFooterHeight = Layout.estimatedFooterHeight
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Layout.estimatedCellHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delaysContentTouches = false
    }
}

// MARK: UITableViewDataSource

extension SettingsEncryptedSearchViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.output.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewModel.output.sections[indexPath.section] {
        case .encryptedSearchFeature:
            return cellForEncryptedSearchFeature(at: indexPath)
        case .downloadViaMobileData:
            return cellForDownloadViewMobileData(at: indexPath)
        case .downloadProgress:
            return cellForDownloadProgress()
        case .downloadedMessages:
            return cellForDownloadedMessages()
        }
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer: UIView?
        switch viewModel.output.sections[section] {
        case .encryptedSearchFeature:
            let view = tableView.dequeue(viewType: SettingsTextFooterView.self)
            view.set(
                text: L11n.EncryptedSearch.settings_footer_of_encrypted_search,
                textLink: L11n.EncryptedSearch.settings_footer_of_encrypted_search_learn,
                linkUrl: Link.encryptedSearchInfo
            )
            footer = view
        case .downloadViaMobileData:
            let view = tableView.dequeue(viewType: SettingsTextFooterView.self)
            view.set(text: LocalString._settings_footer_of_download_via_mobile_data)
            footer = view
        case .downloadProgress:
            let view = tableView.dequeue(viewType: EncryptedSearchBannerFooterView.self)
            footer = view
        case .downloadedMessages:
            footer = nil
        }
        return footer
    }

    private func cellForEncryptedSearchFeature(at indexPath: IndexPath) -> SwitchTableViewCell {
        let cell = tableView.dequeue(cellType: SwitchTableViewCell.self)
        let cellTitle = L11n.EncryptedSearch.settings_title_of_encrypted_search
        cell.configCell(cellTitle, isOn: viewModel.output.isEncryptedSearchEnabled) { [weak self] newValue, feedback in
            if newValue {
                self?.showEnableEncryptedSearchAlert(for: cell.switchView)
            } else {
                self?.showDisableEncryptedSearchAlertIfNeeded(for: cell.switchView)
            }
            feedback(true)
        }
        return cell
    }

    private func cellForDownloadViewMobileData(at indexPath: IndexPath) -> SwitchTableViewCell {
        let cell = tableView.dequeue(cellType: SwitchTableViewCell.self)
        let cellTitle = LocalString._settings_title_of_download_via_mobile_data
        cell.configCell(cellTitle, isOn: viewModel.output.isUseMobileDataEnabled) { [weak self] newValue, feedback in
            self?.viewModel.input.didChangeUseMobileDataValue(isNewStatusEnabled: newValue)
            feedback(true)
        }
        return cell
    }

    private func cellForDownloadProgress() -> EncryptedSearchDownloadProgressCell {
        let cell = tableView.dequeue(cellType: EncryptedSearchDownloadProgressCell.self)
        cell.delegate = self

        // TODO: Pending. It depends on how the information is obtained in the VM and how it's exposed to the VC
        // let downloadState = viewModel.ouput.downloadState
        // cell.configureWith(state: downloadState.toDownloadingState())
        cell.configureWith(state: .fetchingNewMessages) // for sample purposes

        downloadProgressCell = cell
        return cell
    }

    private func cellForDownloadedMessages() -> EncryptedSearchDownloadedMessagesCell {
        let cell = tableView.dequeue(cellType: EncryptedSearchDownloadedMessagesCell.self)

        // TODO: Pending. It depends on how the information is obtained in the VM and how it's exposed to the VC
        // let downloadedMessages = viewModel.ouput.downloadedMessages
        // cell.configure(info: downloadedMessages.toDownloadedMessagesInfo())
        cell.configure(
            info: .init(
                icon: .success,
                title: .downlodedMessages,
                oldestMessage: .init(date: "Jan 1st, 2023", highlight: false),
                additionalInfo: .storageUsed(valueInMB: "145 MB")
            )
        ) // for sample purposes

        cell.accessoryType = .disclosureIndicator
        return cell
    }

    private func showEnableEncryptedSearchAlert(for cellSwitch: UISwitch) {
        let alert = UIAlertController(
            title: L11n.EncryptedSearch.alert_title,
            message: L11n.EncryptedSearch.alert_text,
            preferredStyle: .alert
        )
        let enableTitle = L11n.EncryptedSearch.alert_enable_button
        let cancelTitle = LocalString._general_cancel_button
        let enable = UIAlertAction(title: enableTitle, style: .default) { [weak self] _ in
            self?.viewModel.input.didChangeEncryptedSearchValue(isNewStatusEnabled: true)
        }
        let cancel = UIAlertAction(title: cancelTitle, style: .cancel) { _ in
            cellSwitch.setOn(false, animated: true)
        }
        [enable, cancel].forEach(alert.addAction)
        present(alert, animated: true, completion: nil)
    }

    private func showDisableEncryptedSearchAlertIfNeeded(for cellSwitch: UISwitch) {
        if viewModel.output.isDownloadInProgress {
            let alert = UIAlertController(
                title: L11n.EncryptedSearch.disable_feature_alert_title,
                message: L11n.EncryptedSearch.disable_feature_alert_message,
                preferredStyle: .alert
            )
            let disable = LocalString._general_ok_action
            let cancelTitle = L11n.EncryptedSearch.disable_feature_alert_button_cancel
            let enable = UIAlertAction(title: disable, style: .destructive) { [weak self] _ in
                self?.viewModel.input.didChangeEncryptedSearchValue(isNewStatusEnabled: false)
            }
            let cancel = UIAlertAction(title: cancelTitle, style: .cancel) { _ in
                cellSwitch.setOn(true, animated: true)
            }
            [enable, cancel].forEach(alert.addAction)
            present(alert, animated: true, completion: nil)
        } else {
            viewModel.input.didChangeEncryptedSearchValue(isNewStatusEnabled: false)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if viewModel.output.sections[indexPath.section] == .downloadedMessages {
            viewModel.input.didTapDownloadedMessages()
        }
    }
}

extension SettingsEncryptedSearchViewController: SettingsEncryptedSearchUIProtocol {

    func reloadData() {
        tableView.reloadData()
    }

    func updateDownloadProgress(progress: EncryptedSearchDownloadProgress) {
        downloadProgressCell?.updateDownloadingProgress(progress: progress.toDownloadingProgress())
    }
}

extension SettingsEncryptedSearchViewController: EncryptedSearchDownloadProgressCellDelegate {
    func didTapPause() {
        viewModel.input.didTapPauseMessagesDownload()
    }

    func didTapResume() {
        viewModel.input.didTapResumeMessagesDownload()
    }
}

private extension EncryptedSearchDownloadProgress {

    func toDownloadingProgress() -> EncryptedSearchDownloadProgressCell.DownloadingProgress {
        let messageCountText = String(
            format: L11n.EncryptedSearch.message_count,
            numMessagesDownloaded,
            totalMessages
        )
        return EncryptedSearchDownloadProgressCell.DownloadingProgress(
            messagesDownloaded: messageCountText,
            timeRemaining: timeRemaining,
            percentageDownloaded: percentageDownloaded
        )
    }
}
